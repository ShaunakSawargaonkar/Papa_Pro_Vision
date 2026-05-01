# API Contracts

## 1. Google Gemini API (via `google_generative_ai` SDK)

### Main Model (AgentService)

| Property | Value |
|---|---|
| Model | `gemini-2.0-flash` |
| Auth | API key in constructor |
| SDK | `google_generative_ai` ^0.4.7 |
| Mode | Chat session (`ChatSession`) with system instruction per mode |

**Request — Image + Text:**
```dart
Content.multi([
  DataPart('image/jpeg', imageBytes),  // Uint8List
  TextPart(prompt),                     // String
])
```

**Request — Video + Text:**
```dart
Content.multi([
  DataPart('video/mp4', videoBytes),   // Uint8List (full file)
  TextPart(prompt),
])
```

**Request — Text Only:**
```dart
Content.multi([TextPart(prompt)])
```

**Response — Streaming:**
```dart
Stream<GenerateContentResponse> stream = _chat.sendMessageStream(content);
// Each chunk: chunk.text → accumulated text
```

**System Instructions:**

| Mode | System Prompt Key | Behavior |
|---|---|---|
| `normal` | `SystemPrompts.systemPrompt` | General blind-user assistant; responds in `{communicationLanguage}` |
| `smartView` | `SystemPrompts.smartViewModeSystemPrompt` or `...WithTranslation` | Describe scenes or read text |
| `autoReading` | `SystemPrompts.autoReadingSystemPrompt` or `...WithTranslation` | Read text verbatim (or translate) |
| `video` | `SystemPrompts.videoSystemPrompt` | Describe video for blind person |

### Image Correction Model

| Property | Value |
|---|---|
| Model | `gemini-2.5-flash` |
| Auth | API key from `Secrets.geminiApiKey` |
| Response format | `application/json` with schema |

**Request:**
```dart
Content.multi([
  DataPart('image/jpeg', imageBytes),
  TextPart(promptWithUserQuery),
])
```

**Response Schema:**
```json
{
  "reason": "string — why query is not answerable or improvable",
  "part_of_query_answer_improvable": "string|null — quoted part of query that's improvable",
  "part_of_query_parially_unanswerable": "string|null — quoted part that's unanswerable",
  "movement": "string|null — camera adjustment instruction"
}
```

**Decision Logic:**
- If `part_of_query_parially_unanswerable` is non-null → image is incorrect, recapture required
- If `part_of_query_answer_improvable` is non-null → image is suboptimal, improvement suggested
- Otherwise → image is correct

## 2. Google Cloud Text-to-Speech API

### Endpoint

```
POST https://texttospeech.googleapis.com/v1/text:synthesize?key={API_KEY}
```

### Request

**Headers:**
```
Content-Type: application/json
```

**Body (English):**
```json
{
  "input": { "text": "Hello, this is a test" },
  "voice": {
    "languageCode": "en-IN",
    "name": "en-IN-Chirp3-HD-Alnilam"
  },
  "audioConfig": {
    "audioEncoding": "MP3",
    "speakingRate": 1.0
  }
}
```

**Body (Marathi):**
```json
{
  "input": { "text": "नमस्कार" },
  "voice": {
    "languageCode": "mr-IN",
    "name": "mr-IN-Chirp3-HD-Achird",
    "ssmlGender": "MALE"
  },
  "audioConfig": {
    "audioEncoding": "MP3",
    "speakingRate": 1.0
  }
}
```

### Timeout

HTTP requests have a **15-second timeout** per call. On timeout, the sentence is skipped and the audio queue continues.

### Response

**Success (200):**
```json
{
  "audioContent": "//NExAAQ... (base64-encoded MP3)"
}
```

**Error:**
```json
{
  "error": {
    "code": 400,
    "message": "...",
    "status": "INVALID_ARGUMENT"
  }
}
```

### Language Detection

Determined by `Devicehelper.IsDevanagari(text)`:
- If text contains Devanagari characters (U+0900–U+097F) → `mr-IN`
- Otherwise → `en-IN`

### Speech Rate

Read from `SharedPreferences` key `speechRate` (default `1.0`). Range: `0.25` to `2.0`.

## 3. Render Server (Google Search Proxy)

**Currently disabled in production flow** — `ifGoogle` is hardcoded to `false`.

### Endpoint

```
GET https://vercelgooglesearch.onrender.com/search/{encodedQuery}?user_id={userId}
```

### Response

**Success (200):**
```json
{
  "response": "The search result text..."
}
```

**Error:**
HTTP status != 200 → throws `Exception('Failed to search: ${statusCode}')`.

## 4. Firebase Auth

| Operation | Method |
|---|---|
| Send OTP | `FirebaseAuth.instance.verifyPhoneNumber()` |
| Verify OTP | `FirebaseAuth.instance.signInWithCredential(PhoneAuthProvider.credential(...))` |
| Auth state stream | `FirebaseAuth.instance.authStateChanges()` |

### Timeout

Phone verification timeout: **60 seconds**.

### Error Codes Handled

| Code | User Message |
|---|---|
| `invalid-phone-number` | "Invalid phone number format..." |
| `too-many-requests` | "Too many attempts..." |
| `app-not-authorized` | "App not authorized..." |
| Default | "Verification failed. Please try again." |

## 5. Razorpay Payment

### Configuration

```dart
{
  'key': 'rzp_live_Rs0d9WEg1h6UPg',
  'amount': price * 100,  // paise
  'name': 'Letsee',
  'description': 'Premium Subscription - {plan}',
  'timeout': 300,  // 5 minutes
  'prefill': { 'contact': phoneNumber },
  'config': {
    'display': {
      'hide': [
        { 'method': 'emi' },
        { 'method': 'wallet' },
        { 'method': 'paylater' }
      ],
      'preferences': { 'show_default_blocks': true }
    }
  },
  'theme': { 'color': '#FCB853' }
}
```

### Events

| Event | Handler |
|---|---|
| `EVENT_PAYMENT_SUCCESS` | Update Firestore subscription → navigate to HomeScreen |
| `EVENT_PAYMENT_ERROR` | Show toast/snackbar with error message |
| `EVENT_EXTERNAL_WALLET` | Show info toast |

## 6. Firestore Operations

### Read Operations

| Operation | Collection | Query |
|---|---|---|
| Check user status | `Users` | `where('UserUID', isEqualTo: uid)` |
| Check killed APK | `KilledAPKVersions` | `where('APKVersion', isEqualTo: version)` |
| Verify referral key | `ReferralKey` | `where('KeyName', isEqualTo: keyName)` |
| Fetch payment costs | `PaymentCost` | `.get()` (first doc) |
| Get referral key doc | Via `DocumentReference.get()` | Direct ref |

### Write Operations

| Operation | Collection | Method |
|---|---|---|
| Create org | `Organisations` | `.add()` |
| Create referral key | `ReferralKey` | `.add()` |
| Create user | `Users` | `.add()` |
| Update org refs | `Organisations` | `.update()` (arrayUnion) |
| Update referral key count | `ReferralKey` | `.update()` (increment) |
| Update org user count | `Organisations` | `.update()` (increment) |
| Update subscription | `ReferralKey` | `.update()` |
| Update analytics | `Users` | `.update()` (increment) |
