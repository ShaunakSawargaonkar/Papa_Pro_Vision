# Low-Level Design

## Module Map

```
lib/
├── main.dart                          # App entry, Firebase init, auth routing
├── enums.dart                         # All enums (ConversationState, InteractionMode, UserStatus, etc.)
├── secrets.dart                       # API keys (hardcoded — security issue)
├── text_service.dart                  # Prompt text and UI strings per language/mode
├── Helper/
│   ├── DatabaseHelper.dart            # Firestore CRUD, user status, subscriptions
│   ├── AnalyticsHelper.dart           # Firestore analytics counter updates
│   ├── DeviceAudioHelper.dart         # Sound effects (camera, mic, delete, video, internet)
│   ├── DeviceHelper.dart              # Internet check, text cleaning, device ID, video frames
│   └── FileSharingHelper.dart         # Receive sharing intent handling
├── LLMResponse/
│   ├── agent_service.dart             # Gemini client, streaming, chat session management
│   ├── image_correction_service.dart  # Gemini 2.5 Flash image quality checker
│   └── system_prompt_enums.dart       # All system prompt templates
├── Payment/
│   ├── payment_gatway.dart            # Razorpay UI and payment flow
│   └── payment_utils.dart             # Subscription plans, Firestore price fetch
├── StateManagement/
│   └── button_state_provider.dart     # ConversationController (ChangeNotifier), AppContentState
├── Txt2Speech/
│   ├── service_locator.dart           # TTS interface + factory
│   ├── Models/
│   │   ├── google_tts.dart            # Google Cloud TTS implementation
│   │   └── flutter_tts.dart           # Flutter TTS fallback implementation
│   └── AudioPlayer/
│       └── audio_player.dart          # Audio queue + sequential playback
└── UI/
    ├── home_Screen.dart               # Main interaction screen
    ├── profile_page.dart              # User settings
    ├── auth/
    │   └── phone_auth_page.dart       # Phone OTP auth
    ├── RegisterPage/
    │   ├── registration_page.dart     # User registration form
    │   ├── AlasPage.dart              # Generic error page
    │   └── AlasInternet.dart          # No-internet error page
    ├── Constants/
    │   └── color_constans.dart        # Empty file
    └── widgets/
        ├── mic_button.dart            # Circular mic/status button
        ├── side_bar_button.dart       # Sidebar overlay button (Reader/Smart View)
        └── image_preview.dart         # Camera preview or uploaded image display
```

## Key Classes and Responsibilities

### `ConversationController` (lib/StateManagement/button_state_provider.dart)

The **central orchestrator**. A `ChangeNotifier` provided via `Provider` at the app root.

| Responsibility | Detail |
|---|---|
| Owns `AppContentState` | Single source of truth for conversation state |
| Orchestrates `AgentService` | Initializes, resets, triggers Gemini calls |
| Orchestrates `TextToSpeechService` | Starts/stops TTS, handles `doneSpeaking` |
| Manages `SpeechToText` | Initializes STT, handles status and error callbacks |
| Manages `ImageCorrectionService` | Runs parallel image quality check |
| Manages `FileSharingHelper` | Receives images shared from other apps |
| Mode switching | `setSmartViewMode()`, `setAutoReadingMode()`, `setHistoryMode()`, etc. |
| Input processing | `processInput()` — the main pipeline from user input to Gemini response |

**Key State Fields (AppContentState):**

| Field | Type | Purpose |
|---|---|---|
| `agentResponse` | `String` | Accumulated Gemini response text |
| `userRecognisedWords` | `String` | STT-recognized user speech |
| `speechEndRemark` | `String` | Image correction guidance to speak after main response |
| `conversationState` | `ConversationState?` | Current state machine state |
| `interactionMode` | `InteractionMode?` | Current interaction mode |
| `isHistoryMode` | `bool` | Whether follow-up questions use chat history |
| `hasUploadedImage` | `bool` | Whether an externally shared image is loaded |
| `userUID` | `String` | Firebase user UID |

**State Machine:**

```
idle ──► listening ──► processing ──► speaking ──► idle
  │                                                  ▲
  ├──► videoRecording ──► idle ──► listening ──► ... │
  │                                                  │
  └──► failed ───────────────────────────────────────┘
```

### `AgentService` (lib/LLMResponse/agent_service.dart)

| Responsibility | Detail |
|---|---|
| Wraps `GenerativeModel` | Creates Gemini model with system prompt per mode |
| Chat session management | Maintains `ChatSession` with history |
| `CreateContentForResponse()` | Builds `Content` objects from text/image/video |
| `sendStreamingMessage()` | Streams Gemini response, segments by sentence, calls TTS per segment |
| `generateResponse()` | Non-streaming Gemini call (not currently used in main flow) |
| `sendGoogleSearchMessage()` | Calls Render server proxy (currently disabled) |
| `stopStream()` | Cancels active stream, saves partial response to chat history |
| Stream session management | Uses `streamSessionId` to invalidate old streams |

**Streaming Chunking Logic:**
- Characters accumulated until `.` (sentence end) or 100 words
- Each chunk cleaned via `Devicehelper.cleanAgentResponse()` (strips `*`, `"`, `.`)
- Cleaned chunk spoken via `ttsService.speak()`
- Remaining text after stream completes spoken as final chunk

### `ImageCorrectionService` (lib/LLMResponse/image_correction_service.dart)

| Responsibility | Detail |
|---|---|
| Uses `gemini-2.5-flash` | Separate model dedicated to image quality assessment |
| JSON structured output | Response schema enforces `reason`, `part_of_query_parially_unanswerable`, `part_of_query_answer_improvable`, `movement` |
| Returns `ImageCorrectionResponse` | `isImageCorrect` flag + optional guidance text + `recaptureRequired` flag |
| Permissive fallback | On parse error, returns `isImageCorrect: true` |

### `GoogleTTSService` (lib/Txt2Speech/Models/google_tts.dart)

| Responsibility | Detail |
|---|---|
| Calls Google Cloud TTS REST API | `texttospeech.googleapis.com/v1/text:synthesize` |
| Language detection | Uses `Devicehelper.IsDevanagari()` to detect Marathi text |
| Voice selection | `en-IN-Chirp3-HD-Alnilam` for English, `mr-IN-Chirp3-HD-Achird` for Marathi |
| Speech rate | Read from SharedPreferences (`speechRate`, default 1.0) |
| Audio output | Base64-decoded MP3 bytes enqueued to `AudioPlayerService` |
| Session management | `startSession()` returns session ID; old sessions invalidated on stop |
| `speak()` | Single chunk — for streaming pipeline |
| `speak2()` | Full text — splits by sentences, then by 100-word chunks |
| `onQueueEmptyAndComplete` | Callback fires `controller.doneSpeaking()` when audio queue empty |

### `AudioPlayerService` (lib/Txt2Speech/AudioPlayer/audio_player.dart)

| Responsibility | Detail |
|---|---|
| Sequential audio queue | `List<Uint8List>` of MP3 audio bytes |
| Auto-advance | `onPlayerComplete` triggers `_playNext()` |
| Stop/reset | `stop()` clears queue and halts playback; `reset()` clears queue without stopping |
| Queue empty callback | Fires `onQueueEmptyAndComplete` when playing finishes and queue is empty |

### `DatabaseHelper` (lib/Helper/DatabaseHelper.dart)

| Method | Purpose |
|---|---|
| `createUser()` | Creates User doc, Organization doc, ReferralKey doc in Firestore |
| `verifyReferralKey()` | Validates referral key name, checks usage limits |
| `checkUserStatus()` | Returns `UserStatusResponse` with routing decision |
| `checkKilledAPKVersions()` | Checks if current APK version is killed |
| `checkSubscriptionStatus()` | Checks if subscription is active, pending, or first payment |
| `setSubscriptionInformation()` | Updates referral key with subscription dates |

### `DeviceHelper` (lib/Helper/DeviceHelper.dart)

| Method | Purpose |
|---|---|
| `hasInternetConnectionAndNotify()` | DNS lookup to google.com with 2s timeout; plays TTS alert on failure |
| `cleanAgentResponse()` | Strips `*`, `"`, `.` from Gemini response text |
| `IsDevanagari()` | Regex check for Devanagari Unicode range (U+0900–U+097F) |
| `extractVideoFrames()` | FFmpeg frame extraction at 5fps (currently commented out in usage) |
| `getDeviceId()` | Returns hardcoded placeholder string (legacy) |
| `checkRegistration()` | Legacy registration check (uses old device ID scheme) |

### `DeviceAudioHelper` (lib/Helper/DeviceAudioHelper.dart)

Singleton `_AudioManager` manages audio playback for UI sounds.

| Method | Sound |
|---|---|
| `playCameraClickSound()` | `sounds/camera-13695.mp3` |
| `playDeleteSound()` | `sounds/mag-remove-92075.mp3` |
| `playVideoStartSound()` | System `/system/media/audio/ui/camera_focus.ogg` |
| `playMicONSound()` | System `/system/media/audio/ui/VideoRecord.ogg` |
| `playMicOFFSound()` | System `/system/media/audio/ui/VideoStop.ogg` |
| `playInternetNotAvailableSound()` | FlutterTTS speaks "Internet not available..." |

### `TextService` (lib/text_service.dart)

Provides mode-specific and language-specific prompt text and UI strings.

| Method | Returns |
|---|---|
| `getPromptText(language, mode)` | Default user-facing prompt per mode/language |
| `getProcessingResponseText(language)` | "Processing Response" / "विचार करतोय" |
| `getSmartViewText(language, isStart)` | "Processing Smart View" / Marathi equivalent |
| `getAutoReaderText(language, isStart)` | "Reading Mode" / Marathi equivalent |

### `FileSharingHelper` (lib/Helper/FileSharingHelper.dart)

| Method | Purpose |
|---|---|
| `initialize()` | Subscribes to `ReceiveSharingIntent` media stream |
| `processSharedImage()` | Reads first shared file as bytes, calls `controller.setUploadedImageMode()` |

### `AnalyticsHelper` (lib/Helper/AnalyticsHelper.dart)

| Method | Purpose |
|---|---|
| `updateResponseCount(type, userUID)` | Increments `Analytics.<type>` counter on user's Firestore document |

**Tracked Analytics Keys:**
`ResponseCount`, `TTSErrorCount`, `STTErrorCount`, `PromptErrorCount`, `CancelledRequestCount`, `ImageCaptureCount`, `LLMInteractionWithImageCount`, `JustLLMInteractionCount`, `SmartViewModeCount`, `ReaderModeCount`, `TranslationCount`, `MarathiResponseCount`, `EnglishResponseCount`, `LLMInteractionWithUploadedImageCount`, `VideoModeCount`

## Dependency Relationships

```
main.dart
  └── ConversationController (Provider)
        ├── AgentService
        │     ├── GenerativeModel (google_generative_ai)
        │     ├── TextService
        │     └── AnalyticsHelper → Firestore
        ├── GoogleTTSService (or FlutterTTSService)
        │     ├── AudioPlayerService
        │     ├── Secrets (API key)
        │     └── AnalyticsHelper
        ├── SpeechToText
        ├── ImageCorrectionService
        │     ├── GenerativeModel (gemini-2.5-flash)
        │     └── SystemPrompts
        ├── FileSharingHelper
        │     └── ReceiveSharingIntent
        └── DeviceAudioHelper
              └── _AudioManager (singleton)
```
