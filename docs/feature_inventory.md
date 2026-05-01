# Feature Inventory

## Implemented Features

### F-01: Phone OTP Authentication

| Aspect | Detail |
|---|---|
| **Purpose** | Authenticate users via phone number + SMS OTP |
| **Screens** | `PhoneAuthPage` |
| **Services** | `FirebaseAuth` |
| **Models** | None (Firebase SDK handles internally) |
| **Dependencies** | Firebase Auth, SMS |
| **Known Limitations** | Country code hardcoded to +91 (India); no support for other countries |

### F-02: User Registration

| Aspect | Detail |
|---|---|
| **Purpose** | Register new users as single or organization type |
| **Screens** | `RegistrationPage` |
| **Services** | `DatabaseHelper.createUser()`, `DatabaseHelper.verifyReferralKey()` |
| **Models** | `CreateUserResponse`, `ReferralKeyResponse` |
| **Dependencies** | Firestore (Users, Organisations, ReferralKey collections) |
| **Known Limitations** | Gender is a dropdown (Male/Female); occupation is optional; no data validation beyond form validators |

### F-03: Subscription Payment

| Aspect | Detail |
|---|---|
| **Purpose** | Collect subscription payments via Razorpay |
| **Screens** | `PaymentGateway` |
| **Services** | `Razorpay`, `PaymentService`, `DatabaseHelper.setSubscriptionInformation()` |
| **Models** | Subscription plans (maps), `SubscriptionBundleType`, `SubscriptionTier` |
| **Dependencies** | Razorpay SDK, Firestore (PaymentCost, ReferralKey) |
| **Known Limitations** | No server-side payment verification webhook; ₹1 free trial bypasses Razorpay |

### F-04: App Version Enforcement

| Aspect | Detail |
|---|---|
| **Purpose** | Block outdated APK versions from accessing the app |
| **Screens** | `AlasPage` |
| **Services** | `DatabaseHelper.checkKilledAPKVersions()` |
| **Models** | `KilledAPKVersionResponse` |
| **Dependencies** | Firestore (KilledAPKVersions), `package_info_plus` |
| **Known Limitations** | APK version stored at registration time — not updated on app upgrade |

### F-05: Image Capture + Voice Query (Normal Mode)

| Aspect | Detail |
|---|---|
| **Purpose** | Capture camera image, ask a voice question, receive spoken answer |
| **Screens** | `HomeScreen` |
| **Services** | Camera, STT, `AgentService`, `GoogleTTSService`, `AudioPlayerService` |
| **Models** | `Content` (Gemini SDK), `AppContentState` |
| **Dependencies** | Camera plugin, speech_to_text, Gemini API, Google Cloud TTS API |
| **Known Limitations** | No retry on Gemini failure; very high resolution images may be slow |

### F-06: Smart View Mode

| Aspect | Detail |
|---|---|
| **Purpose** | Auto-describe scene or read text based on image content type |
| **Screens** | `HomeScreen` (right sidebar) |
| **Services** | Same as F-05 |
| **Models** | Same as F-05 |
| **Dependencies** | Same as F-05 |
| **Known Limitations** | No user prompt — decision made entirely by Gemini's system prompt |

### F-07: Auto Reading Mode (Reader Mode)

| Aspect | Detail |
|---|---|
| **Purpose** | Extract and read text from captured image verbatim |
| **Screens** | `HomeScreen` (left sidebar) |
| **Services** | Same as F-05 |
| **Models** | Same as F-05 |
| **Dependencies** | Same as F-05 |
| **Known Limitations** | Text extraction depends on Gemini accuracy; no fallback to OCR-specific models |

### F-08: Translation

| Aspect | Detail |
|---|---|
| **Purpose** | Translate image text into communication language |
| **Screens** | `HomeScreen`, `ProfilePage` (toggle) |
| **Services** | `AgentService` (system prompts with translation variant) |
| **Models** | Same as F-05 |
| **Dependencies** | Gemini API |
| **Known Limitations** | Only applies to Smart View and Auto Reading modes; includes "Parentheses Rule" for duplicate transliterations |

### F-09: Video Recording + Query

| Aspect | Detail |
|---|---|
| **Purpose** | Record up to 7 seconds of video, ask question, receive spoken answer |
| **Screens** | `HomeScreen` (right mic long-press) |
| **Services** | Camera (video), STT, `AgentService`, `GoogleTTSService` |
| **Models** | `File` (video), `Content` with `DataPart('video/mp4')` |
| **Dependencies** | Camera plugin, Gemini API (video support) |
| **Known Limitations** | Full MP4 uploaded (potentially large); FFmpeg frame extraction exists but is disabled |

### F-10: Chat History (Follow-up Questions)

| Aspect | Detail |
|---|---|
| **Purpose** | Ask follow-up questions without capturing a new image |
| **Screens** | `HomeScreen` (left/green mic) |
| **Services** | `AgentService` (chat session preserved) |
| **Models** | `ChatSession` history |
| **Dependencies** | Gemini API |
| **Known Limitations** | History only retained for current mode; mode changes clear history |

### F-11: Image Correction Guidance (DISABLED)

| Aspect | Detail |
|---|---|
| **Purpose** | Guide blind users to improve camera positioning when image is inadequate |
| **Screens** | `HomeScreen` (spoken feedback) |
| **Services** | `ImageCorrectionService` |
| **Models** | `ImageCorrectionResponse` |
| **Dependencies** | Gemini 2.5 Flash API |
| **Status** | **Disabled** — `runImageCorrection()` call is commented out in `processInput()`. Code preserved for future re-enablement. |
| **Known Limitations** | When enabled: runs in parallel — may complete after main response is already speaking; guidance is spoken after main response or interrupts if recapture required |

### F-12: Receive Shared Images

| Aspect | Detail |
|---|---|
| **Purpose** | Allow users to share images from other apps to Letsee |
| **Screens** | `HomeScreen` (image displayed in preview) |
| **Services** | `FileSharingHelper`, `ReceiveSharingIntent` |
| **Models** | `SharedMediaFile` |
| **Dependencies** | `receive_sharing_intent` plugin |
| **Known Limitations** | Only first shared file is processed; only image files supported. Null/empty file paths and non-existent files are guarded against. |

### F-13: Profile / Settings

| Aspect | Detail |
|---|---|
| **Purpose** | Configure speech rate, language, translation, camera preference |
| **Screens** | `ProfilePage` |
| **Services** | `SharedPreferences` |
| **Models** | None (primitive values) |
| **Dependencies** | `shared_preferences` |
| **Known Limitations** | Emergency contact field exists but is not used anywhere in the app |

### F-14: Audio Feedback

| Aspect | Detail |
|---|---|
| **Purpose** | Provide non-visual feedback for all state changes |
| **Screens** | `HomeScreen` |
| **Services** | `DeviceAudioHelper` |
| **Models** | None |
| **Dependencies** | `audioplayers`, system sound files, `flutter_tts` |
| **Known Limitations** | Fallback sound paths depend on Android system files being present. `_isPlaying` flag is reset in `finally` block to prevent stuck state. `playInternetNotAvailableSound()` is awaited with explicit language set. |

### F-15: Analytics Tracking

| Aspect | Detail |
|---|---|
| **Purpose** | Track usage patterns per user for product insights |
| **Screens** | All (triggered from `HomeScreen`) |
| **Services** | `AnalyticsHelper` |
| **Models** | Analytics sub-document in Users collection |
| **Dependencies** | Firestore |
| **Known Limitations** | Counter-only; no time-series; no grouping by session; requires internet for each increment |

### F-16: Copy Response to Clipboard

| Aspect | Detail |
|---|---|
| **Purpose** | Allow sighted assistants to copy the AI response text |
| **Screens** | `HomeScreen` (button shown when response exists) |
| **Services** | System clipboard |
| **Models** | None |
| **Dependencies** | `flutter/services.dart` |
| **Known Limitations** | Button visibility depends on `agentResponse.isNotEmpty` |

## Not Implemented / Planned Features

| Feature | Evidence | Status |
|---|---|---|
| Google Search integration | Code exists in `AgentService.sendGoogleSearchMessage()` and `getResponseFromRender()` but `ifGoogle = false` | Disabled |
| Video frame extraction (FFmpeg) | Code exists in `DeviceHelper.extractVideoFrames()` but commented out in `AgentService` | Disabled |
| Emergency contact use | Field saved in SharedPreferences but never read for any feature | TODO |
| `error_bot.png` usage | Asset declared but not referenced in code | TODO |
| iOS deployment | iOS project exists but production status unknown | UNKNOWN |
| Device ID-based registration | Legacy code exists in `DeviceHelper` but not actively used | Deprecated |
