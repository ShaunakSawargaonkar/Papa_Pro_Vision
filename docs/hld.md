# High-Level Design

## Major Subsystems

```
┌─────────────────────────────────────────────────────────────┐
│                        Letsee App                           │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────────────┐  │
│  │ Auth &      │  │ Home &      │  │ Settings /         │  │
│  │ Onboarding  │  │ Interaction │  │ Profile            │  │
│  │             │  │             │  │                    │  │
│  │ PhoneAuth   │  │ HomeScreen  │  │ ProfilePage        │  │
│  │ Registration│  │ Camera      │  │ SharedPreferences  │  │
│  │ Payment     │  │ Voice I/O   │  │                    │  │
│  │ StatusCheck │  │ LLM         │  │                    │  │
│  └──────┬──────┘  └──────┬──────┘  └────────┬───────────┘  │
│         │                │                   │              │
│  ┌──────▼────────────────▼───────────────────▼───────────┐  │
│  │              ConversationController (Provider)         │  │
│  │              (Central state + orchestration)           │  │
│  └────┬───────────┬──────────────┬──────────────┬────────┘  │
│       │           │              │              │           │
│  ┌────▼────┐ ┌────▼────┐  ┌─────▼─────┐  ┌────▼────────┐  │
│  │ Agent   │ │ TTS     │  │ STT       │  │ Image       │  │
│  │ Service │ │ Service │  │ (speech   │  │ Correction  │  │
│  │ (Gemini)│ │ (Google │  │  _to_text)│  │ Service     │  │
│  │         │ │  Cloud) │  │           │  │ (Gemini 2.5)│  │
│  └─────────┘ └─────────┘  └───────────┘  └─────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Helper Layer                             │   │
│  │  DatabaseHelper | AnalyticsHelper | DeviceHelper     │   │
│  │  DeviceAudioHelper | FileSharingHelper               │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow Overview

### Normal Mode (Image + Voice Query)

```
User taps right mic → _captureImage() → camera captures JPEG bytes
                    → controller.setImageBytes(bytes)
                    → controller.startListening(locale)
                    → STT records speech
                    → STT onStatus='done'
                    → controller.processInput(language, imageBytes)
                    → [parallel] runImageCorrection(prompt, imageBytes)
                    → AgentService.CreateContentForResponse(prompt, imageBytes)
                    → AgentService.sendStreamingMessage(content, ttsService)
                    → Gemini streaming chunks arrive
                    → Each sentence → GoogleTTSService.speak() → Google Cloud TTS API → audio bytes
                    → AudioPlayerService.enqueue(audioBytes) → played sequentially
                    → Stream done → remaining text spoken → doneSpeaking()
```

### Smart View / Auto Reading Mode

```
User taps sidebar → controller.setSmartViewMode() or setAutoReadingMode()
                  → TTS announces mode change
                  → _captureImage() → image captured
                  → controller.processInput(language, imageBytes)
                  → Default prompt used (no voice input needed)
                  → Same Gemini → TTS pipeline as Normal Mode
```

### Video Mode

```
User long-presses right mic → startVideoRecording() → camera records video
                            → Release or 7s timer → stopVideoRecording()
                            → controller.startListening(locale) → user speaks
                            → STT done → processInput(language, videoFile: file)
                            → Video bytes sent to Gemini (full MP4)
                            → Same streaming + TTS pipeline
```

## Screen-to-Service Mapping

| Screen | Services Used |
|---|---|
| `PhoneAuthPage` | `FirebaseAuth` |
| `RegistrationPage` | `DatabaseHelper.createUser`, `DatabaseHelper.verifyReferralKey` |
| `PaymentGateway` | `Razorpay`, `PaymentService.fetchPaymentCosts`, `DatabaseHelper.setSubscriptionInformation` |
| `HomeScreen` | `ConversationController`, `AgentService`, `GoogleTTSService`, `SpeechToText`, `Camera`, `ImageCorrectionService`, `FileSharingHelper`, `DeviceAudioHelper`, `AnalyticsHelper` |
| `ProfilePage` | `SharedPreferences` |
| `AlasPage` / `AlasInternetPage` | None (static display) |

## Error Propagation Model

```
Gemini API error → GenerativeAIException caught in AgentService
                 → Error string returned → spoken via TTS to user
                 → AnalyticsHelper increments PromptErrorCount

Google TTS error → Exception caught in GoogleTTSService.speak()
                 → AnalyticsHelper increments TTSErrorCount
                 → Current sentence skipped, queue continues

STT error → SpeechToText onError callback
          → DeviceAudioHelper.playMicOFFSound()
          → conversationState = ConversationState.failed

Network unavailable → Devicehelper.hasInternetConnectionAndNotify()
                    → TTS speaks "Internet not available"
                    → Action aborted, state reset to idle

Firebase/Firestore error → Caught in DatabaseHelper methods
                         → Error message returned in response objects
                         → UI shows error via SnackBar or AlasPage
```

## Resilience and Fallback Strategy

| Failure | Fallback |
|---|---|
| Gemini API failure | Error message spoken to user. No retry. |
| Google Cloud TTS failure | Individual sentence skipped; queue continues with next. Analytics logged. |
| No internet at launch | `AlasInternetPage` displayed |
| No internet mid-interaction | TTS speaks "Internet not available" and resets to idle |
| Camera init failure | Error logged; CircularProgressIndicator shown |
| STT init failure | `ConversationState.failed` |
| Video frame extraction failure | Fallback: send full MP4 video to Gemini instead of frames |
| Image correction fails to parse JSON | Treat image as correct (permissive fallback) |
| Razorpay init failure | SnackBar error shown |
| Payment failure | Toast error message shown |
| Killed APK version | `AlasPage` with update message |
| Multiple users with same phone | Error state → contact support page |
