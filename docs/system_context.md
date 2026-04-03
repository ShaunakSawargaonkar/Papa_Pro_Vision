# System Context

## High-Level System Context

```
┌──────────────────────────────────────────────────────┐
│                   Letsee Flutter App                  │
│                  (Android / iOS)                      │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │ Camera   │  │ STT      │  │ ConversationCtrl │   │
│  │ Service  │  │ (on-dev) │  │ (Provider)       │   │
│  └────┬─────┘  └────┬─────┘  └───────┬──────────┘   │
│       │              │                │              │
│       └──────────────┴────────┬───────┘              │
│                               │                      │
│                    ┌──────────▼──────────┐            │
│                    │    AgentService     │            │
│                    │  (Gemini Client)    │            │
│                    └──────────┬──────────┘            │
│                               │                      │
│                    ┌──────────▼──────────┐            │
│                    │   TTS Service       │            │
│                    │ (Google Cloud TTS)  │            │
│                    └──────────┬──────────┘            │
│                               │                      │
│                    ┌──────────▼──────────┐            │
│                    │  AudioPlayerService │            │
│                    │  (audioplayers)     │            │
│                    └────────────────────┘            │
└──────────────────────────────────────────────────────┘
                        │           │
           ┌────────────┘           └────────────┐
           ▼                                     ▼
┌─────────────────────┐              ┌─────────────────────┐
│  Google Cloud APIs  │              │   Firebase          │
│                     │              │                     │
│  • Gemini 2.0 Flash │              │  • Auth (Phone OTP) │
│    (generativeai)   │              │  • Firestore        │
│  • Gemini 2.5 Flash │              │    (Users, Orgs,    │
│    (image correct.) │              │     ReferralKey,    │
│  • Cloud TTS API    │              │     KilledAPK,      │
│                     │              │     PaymentCost)    │
└─────────────────────┘              └─────────────────────┘
           │
           ▼
┌─────────────────────┐              ┌─────────────────────┐
│  Render Server      │              │   Razorpay          │
│  (Google Search     │              │   (Payment)         │
│   Proxy)            │              │                     │
│  vercelgooglesearch │              └─────────────────────┘
│  .onrender.com      │
└─────────────────────┘
```

## App Boundaries

| Boundary | Responsibility |
|---|---|
| **Camera** | On-device. Image capture, video recording. No cloud upload — bytes sent directly to Gemini. |
| **Speech-to-Text** | On-device. Uses `speech_to_text` plugin (OS-level STT). |
| **Gemini LLM** | Cloud. All image understanding, text reading, scene description, and Q&A. |
| **Google Cloud TTS** | Cloud. Converts Gemini text response to audio (MP3). |
| **Audio playback** | On-device. `audioplayers` package plays MP3 bytes received from TTS. |
| **Firebase Auth** | Cloud. Phone number OTP verification. |
| **Firestore** | Cloud. User registration, subscription status, analytics, payment costs, killed APK versions. |
| **Razorpay** | Cloud. Payment processing for subscriptions. |
| **Render server** | Cloud. Proxy for Google Search queries (currently disabled in code). |

## External Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| `google_generative_ai` | ^0.4.7 | Gemini API client |
| `camera` | ^0.11.2 | Camera capture |
| `speech_to_text` | ^7.3.0 | On-device STT |
| `flutter_tts` | ^4.2.3 | Fallback TTS (device-level) |
| `audioplayers` | ^5.2.1 | Audio playback |
| `firebase_core` | ^2.24.2 | Firebase initialization |
| `firebase_auth` | ^4.16.0 | Phone OTP auth |
| `cloud_firestore` | ^4.14.0 | Database |
| `razorpay_flutter` | ^1.4.0 | Payment gateway |
| `provider` | ^6.1.5+1 | State management |
| `shared_preferences` | ^2.2.2 | Local key-value storage |
| `http` | ^1.2.1 | HTTP client for TTS and Render |
| `permission_handler` | ^12.0.1 | Runtime permissions |
| `receive_sharing_intent` | ^1.8.1 | Receive shared images |
| `ffmpeg_kit_flutter_new_video` | ^1.1.0 | Video frame extraction (currently commented out) |
| `path_provider` | ^2.1.5 | Temp directory access |
| `package_info_plus` | ^9.0.0 | APK version info |
| `intl` | ^0.19.0 | Internationalization |
| `image` | ^4.5.4 | Image processing (usage unclear — TODO) |
| `flutter_native_splash` | ^2.4.7 | Splash screen |
| `fluttertoast` | ^8.2.14 | Toast messages |
| `get_it` | ^7.6.0 | Service locator (registered but not actively used for DI) |

## Gemini Integration Boundary

| Aspect | Detail |
|---|---|
| Models used | `gemini-2.0-flash` (main), `gemini-2.5-flash` (image correction) |
| Client library | `google_generative_ai` Dart package |
| Auth | API key passed in constructor |
| Input types | Text, JPEG images, MP4 video |
| Output | Streamed text (main), JSON (image correction) |
| Chat statefullness | `ChatSession` maintains multi-turn history |

## Client / Server Responsibilities

| Responsibility | Where |
|---|---|
| Image capture and preprocessing | Client |
| Video capture | Client |
| Speech recognition | Client (on-device) |
| Prompt construction | Client (TextService + SystemPrompts) |
| LLM inference | Server (Gemini API) |
| Image quality assessment | Server (Gemini 2.5 Flash) |
| Text-to-speech synthesis | Server (Google Cloud TTS API) |
| Audio playback | Client |
| User authentication | Server (Firebase Auth) |
| User data storage | Server (Firestore) |
| Payment processing | Server (Razorpay) |
| Analytics counters | Server (Firestore) |
| Subscription management | Server (Firestore) + Client (status check) |
