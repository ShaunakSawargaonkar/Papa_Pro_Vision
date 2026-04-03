# Open Questions

Questions and unresolved assumptions discovered during documentation. Each item describes what is unknown, why it matters, and what would resolve it.

## Critical

### OQ-01: API Key Security

**Question:** Why are API keys (Gemini, Google TTS, Razorpay) hardcoded in source when `flutter_dotenv` is already a dependency?

**Why it matters:** Keys are extractable from compiled APK. Could lead to API abuse, financial loss (TTS/Razorpay), or key revocation.

**Resolution:** Migrate to `.env` file using `flutter_dotenv`, add `secrets.dart` and `.env` to `.gitignore`, restrict keys in Google Cloud Console.

### OQ-02: Server-Side Payment Verification

**Question:** Is there a Razorpay webhook for server-side payment verification?

**Why it matters:** Client-side payment callbacks alone are unreliable. If the app crashes after payment but before Firestore update, the user has paid but won't get access.

**Resolution:** Check Razorpay dashboard for webhook configuration. If none exists, implement a Cloud Function to verify payments.

### OQ-03: Firestore Security Rules

**Question:** What Firestore security rules are in place?

**Why it matters:** Current code reads/writes multiple collections. Without proper rules, any authenticated user could potentially read other users' data or modify their own subscription status.

**Resolution:** Audit `firestore.rules` file in Firebase Console. Document the rules.

## Important

### OQ-04: iOS Build Status

**Question:** Is the iOS build working? Is the app deployed on App Store?

**Why it matters:** iOS project directories exist but iOS-specific configuration (provisioning, capabilities) is not verified.

**Resolution:** Try `flutter build ios` and document results.

### OQ-05: Emergency Contact Feature

**Question:** What is the intended use of the emergency contact saved in SharedPreferences?

**Why it matters:** The field exists in ProfilePage but is never read by any feature. It may represent planned functionality.

**Resolution:** Clarify with product owner whether this is planned (e.g., SOS button, emergency call) or can be removed.

### OQ-06: Google Search Integration Plans

**Question:** Is the Render server Google Search feature planned for re-enablement?

**Why it matters:** Code exists for `sendGoogleSearchMessage()` and `getResponseFromRender()` but is disabled (`ifGoogle = false`). The Render server URL is hardcoded.

**Resolution:** Clarify product plans. If deprecated, remove dead code. If planned, document the feature.

### OQ-07: `error_bot.png` Asset

**Question:** What is `assets/error_bot.png` intended for?

**Why it matters:** The asset is declared in `pubspec.yaml` but not referenced in any Dart file. It increases APK size unnecessarily if unused.

**Resolution:** Check if it was previously used and became dead reference, or if planned for a future error screen.

### OQ-08: ConversationState.failed Recovery

**Question:** How does the user recover from `ConversationState.failed`?

**Why it matters:** If STT initialization fails, the state is set to `failed` but there is no UI mechanism to retry or recover. The user would need to restart the app.

**Resolution:** Add a retry mechanism or auto-recovery when STT fails.

### OQ-09: `image` Package Usage

**Question:** What is the `image: ^4.5.4` dependency used for?

**Why it matters:** No import of the `image` package was found in the codebase. It may be unused, adding to APK size.

**Resolution:** Search for `import 'package:image/` in full codebase. If unused, remove from pubspec.yaml.

## Minor

### OQ-10: `get_it` Service Locator Usage

**Question:** Is `get_it` actively used for dependency injection?

**Why it matters:** `get_it` is imported in `service_locator.dart` but `locator` is declared without being registered or used. TTS services are created directly via factory function.

**Resolution:** Either adopt `get_it` for DI or remove the dependency.

### OQ-11: Old Device ID Functions

**Question:** Are `getDeviceId()` and `getOldUserDeviceId()` still needed?

**Why it matters:** Both functions return hardcoded placeholder strings. `checkRegistration()` (legacy) uses them but is not called in the main flow (replaced by `checkUserStatus()`).

**Resolution:** If the old registration system is fully deprecated, remove these functions and `checkRegistration()`.

### OQ-12: Multiple google-services.json Files

**Question:** Why are there multiple `google-services_*.json` files in `android/app/`?

**Why it matters:** Only `google-services.json` is used by the build. Other files (`google-services_old.json`, `Old2google-services.json`, `OldDBgoogle-services.json`) may contain old Firebase project credentials.

**Resolution:** Remove old files if they are not needed. They may contain credentials that should not be in source control.

### OQ-13: `color_constans.dart` Empty File

**Question:** Is `lib/UI/Constants/color_constans.dart` intended to hold something?

**Why it matters:** The file exists but is empty. It may be planned for a design token system.

**Resolution:** Either populate with app color constants (currently scattered in widgets) or remove the file.

### OQ-14: `intl` Package Usage

**Question:** What is the `intl: ^0.19.0` dependency used for?

**Why it matters:** No `intl` imports were found in the main source files. It may be a transitive dependency or planned for localization.

**Resolution:** Verify if `intl` is used directly. If only a transitive dependency, it doesn't need explicit listing.

### OQ-15: STTErrorCount Never Incremented

**Question:** The analytics key `STTErrorCount` is initialized at user creation but never incremented when STT errors occur.

**Why it matters:** STT errors are real but not tracked, creating a blind spot in usage analytics.

**Resolution:** Add `Analyticshelper.updateResponseCount("STTErrorCount", userUID)` in the STT `onError` callback.
