# Data Model

## Firestore Collections

### Users

| Field | Type | Required | Description |
|---|---|---|---|
| `Name` | string | Yes | User's display name |
| `Age` | int | Yes | User's age |
| `Gender` | string | Yes | "Male", "Female", or other |
| `IsAdmin` | bool | Yes | `true` for single users; `false` for org members |
| `Occupation` | string | No (nullable) | User's occupation |
| `ReferralKey` | DocumentReference | Yes | Ref → `ReferralKey/{id}` |
| `OrgID` | DocumentReference | Yes | Ref → `Organisations/{id}` |
| `IsEnabled` | bool | Yes | Account active flag |
| `UserUID` | string | Yes | Firebase Auth UID |
| `CreatedAt` | Timestamp | Yes | Server timestamp |
| `APKVersion` | string | Yes | `"version+buildNumber"` (e.g., `"5.5.8+8"`) |
| `Analytics` | map | Yes | Nested analytics counters |

**Analytics Sub-document:**

| Field | Type | Description |
|---|---|---|
| `ResponseCount` | int | Total Gemini responses |
| `TTSErrorCount` | int | TTS API failures |
| `STTErrorCount` | int | STT failures |
| `PromptErrorCount` | int | Gemini API errors |
| `CancelledRequestCount` | int | User-cancelled interactions |
| `ImageCaptureCount` | int | Images captured |
| `LLMInteractionWithImageCount` | int | Queries with captured image |
| `JustLLMInteractionCount` | int | Text-only queries (history mode) |
| `SmartViewModeCount` | int | Smart View activations |
| `ReaderModeCount` | int | Reader Mode activations |
| `TranslationCount` | int | Translation-enabled interactions |
| `MarathiResponseCount` | int | Marathi-language responses |
| `EnglishResponseCount` | int | English-language responses |

**Additional analytics keys tracked in code but not initialized in creation:**
- `LLMInteractionWithUploadedImageCount`
- `VideoModeCount`

### Organisations

| Field | Type | Required | Description |
|---|---|---|---|
| `NumberOfUsers` | int | Yes | Count of users in org |
| `OrgType` | string | Yes | `"single"` or `"organization"` |
| `ReferralKeys` | List\<DocumentReference\> | Yes | Refs → `ReferralKey/{id}` |
| `CreatedAt` | Timestamp | Yes | Server timestamp |

### ReferralKey

| Field | Type | Required | Description |
|---|---|---|---|
| `NumberOfUsers` | int | Yes | Current usage count |
| `KeyName` | string | Yes | Human-readable key name. `"SINGLE_USER"` for single users |
| `MaxCount` | int | Yes | Maximum allowed users |
| `CreatedAt` | Timestamp | Yes | Server timestamp |
| `OrgID` | DocumentReference | Yes | Ref → `Organisations/{id}` |
| `SubscriptionBundleType` | string | No | e.g., `"1 Month"`, `"First Month Free"` |
| `SubscriptionEndDate` | Timestamp | No (nullable) | `null` means first payment pending |
| `SubscriptionTier` | string | No | `"free"` or `"paid"` |

**Subscription Status Logic:**
- `SubscriptionEndDate == null` → `UserStatus.firstPaymentPending`
- `SubscriptionEndDate > now` → `UserStatus.active`
- `SubscriptionEndDate <= now` → `UserStatus.paymentPending`

### KilledAPKVersions

| Field | Type | Required | Description |
|---|---|---|---|
| `APKVersion` | string | Yes | Version string to block (e.g., `"5.3.0+6"`) |
| `CreatedAt` | Timestamp | Yes | Server timestamp |
| `ReasonTitle` | string | Yes | Title shown on AlasPage |
| `ReasonMessage` | string | Yes | Message shown on AlasPage |

### PaymentCost

| Field | Type | Description |
|---|---|---|
| `1 Month` | int/string | Price in INR for 1 month |
| `3 Months` | int/string | Price in INR for 3 months |
| `6 Months` | int/string | Price in INR for 6 months |
| `1 Year` | int/string | Price in INR for 1 year |
| `First Month Free` | int/string | Price in INR for free trial (typically 1) |

## Dart Domain Classes

### Response DTOs

| Class | File | Fields |
|---|---|---|
| `UserStatusResponse` | `DatabaseHelper.dart` | `message?`, `reasonTitle?`, `userStatus`, `referralKeyRef?` |
| `ReferralKeyResponse` | `DatabaseHelper.dart` | `message?`, `success`, `referralKeyRef?`, `orgRef?` |
| `CreateUserResponse` | `DatabaseHelper.dart` | `message?`, `success`, `userRef?`, `orgRef?`, `referralKeyRef?` |
| `KilledAPKVersionResponse` | `DatabaseHelper.dart` | `isKilled`, `reasonTitle?`, `reasonMessage?` |
| `ImageCorrectionResponse` | `image_correction_service.dart` | `response?`, `isImageCorrect`, `recaptureRequired?` |
| `AppContentState` | `button_state_provider.dart` | `agentResponse`, `userRecognisedWords`, `speechEndRemark`, `conversationState`, `interactionMode`, `isHistoryMode`, `hasUploadedImage`, `userUID` |

### Enums

| Enum | Values | File |
|---|---|---|
| `ConversationState` | `idle`, `listening`, `processing`, `speaking`, `videoRecording`, `failed` | `enums.dart` |
| `InteractionMode` | `normal`, `smartView`, `autoReading`, `video` | `enums.dart` |
| `UserType` | `single`, `organization` | `enums.dart` |
| `UserStatus` | `errorState`, `notRegistered`, `firstPaymentPending`, `paymentPending`, `active`, `noInternet`, `apkKilled` | `enums.dart` |
| `SubscriptionBundleType` | `firstMonthFree`, `oneMonth`, `threeMonths`, `sixMonths`, `oneYear` | `enums.dart` |
| `SubscriptionTier` | `free`, `paid` | `enums.dart` |

## Local Persistence

| Store | Technology | Data |
|---|---|---|
| User preferences | `SharedPreferences` | Language, speech rate, translation, camera, contacts |
| Transient image bytes | In-memory `Uint8List` | Current captured/uploaded image |
| Transient video file | Temp file system | Deleted after processing |
| Chat history | In-memory `List<Content>` | Cleared on mode change or agent reset |

## Serialization / Deserialization

- **Firestore**: No custom serialization — raw `Map<String, dynamic>` reads/writes
- **Gemini API**: `Content` objects built via `google_generative_ai` SDK (`Content.multi()`, `DataPart()`, `TextPart()`)
- **Image correction response**: JSON decoded from Gemini structured output (`jsonDecode`)
- **Google TTS response**: JSON decoded, `audioContent` field Base64-decoded to bytes
- **SharedPreferences**: Native get/set methods for primitives

## Validation Rules

| Validation | Where |
|---|---|
| Phone number format | `PhoneAuthPage._formKey` validator |
| OTP code not empty | `PhoneAuthPage._verifyCode()` |
| Registration form required fields | `RegistrationPage._formKey` validator |
| Referral key not empty | `RegistrationPage._verifyReferralKey()` |
| Payment amount > 0 | `PaymentGateway.openCheckout()` |
| Internet available | `Devicehelper.hasInternetConnectionAndNotify()` called before network operations |
| User UID not empty | Partial check in `DatabaseHelper.createUser()` (currently commented out) |
