# LLM Integration

## Gemini Usage Model

| Aspect | Detail |
|---|---|
| Primary model | `gemini-2.0-flash` (AgentService) |
| Secondary model | `gemini-2.5-flash` (ImageCorrectionService) |
| SDK | `google_generative_ai` ^0.4.7 |
| Authentication | API key passed to `GenerativeModel` constructor |
| Input modalities | Text, JPEG images, MP4 video |
| Output modality | Text (streamed for main, JSON for image correction) |
| Chat sessions | `ChatSession` with persistent history per conversation |

## Prompt Templates and Composition

### Prompt Architecture

```
┌──────────────────────────┐
│   System Instruction     │  ← Set per mode at model init time
│   (SystemPrompts class)  │  ← Contains: role, rules, language directive
└──────────────┬───────────┘
               │
┌──────────────▼───────────┐
│   User Content           │  ← Built per request in CreateContentForResponse()
│   - Image/Video (bytes)  │
│   - Prompt text          │
└──────────────────────────┘
```

### System Prompts (lib/LLMResponse/system_prompt_enums.dart)

All system prompts are in `SystemPrompts` class. They use `{communicationLanguage}` as a placeholder replaced at runtime.

#### Normal Mode
```
You are a helpful, friendly assistant for blind users.
Communication language: {communicationLanguage}. Always respond in the communication language independent of the language of the user.
```

#### Video Mode
```
You are a helpful, friendly assistant for blind users. User will provide a video or a list of images and a prompt. This video or a list of images will be of his surroundings that he or she will capture from their phone camera. Try to answer the prompt based on the video or a list of images content and guide him or her accordingly. If the user is asking to find something, answer it by guiding him clearly towards the object he is looking for. Do not give bounding boxes as answer.
Communication language: {communicationLanguage}. ...
```

#### Smart View Mode
Two variants: with and without translation.

**Without translation:** Decides if image is primarily text or visual. For text: identify material + read verbatim in original language. For visual: overview + detailed description. Includes camera guidance rules.

**With translation:** Same as above but translates all text into `{communicationLanguage}`. Includes "Parentheses Rule" to remove duplicate transliterations (e.g., "क्लासिक (Classic)" → "क्लासिक").

#### Auto Reading Mode
Two variants: with and without translation.

**Without translation:** Read the main body text exactly as written, in its original language. No greetings, no headings. Guide camera if text is cut off.

**With translation:** Translate main body text into `{communicationLanguage}`. Apply Parentheses Rule. Remove non-essential elements.

#### Image Correction
Structured prompt evaluates if user query is answerable given the image. Returns JSON with:
- Whether part of query is unanswerable/partially answerable
- Whether answer is improvable
- Camera movement instructions

Uses `{user_query}` placeholder replaced with actual user query.

### User Prompt Construction (lib/text_service.dart)

Default prompts per mode and language:

| Mode | English | Marathi |
|---|---|---|
| normal | "What do you see in the image? Describe it for a blind person" | "तुम्हाला या चित्रात काय दिसते? आंधळ्या व्यक्तीसाठी त्याचे वर्णन करा." |
| smartView | "Describe what you see in the image. If the image is predominantly text, read it clearly. If text or image is unclear, suggest camera adjustments." | Marathi equivalent |
| autoReading | "Read the text in the image." | "चित्रातील मजकूर वाचा." |
| video | "What do you see in the video? Describe it for a blind person" | Marathi equivalent |

**Logic:** If user speaks (voice recognized), their speech replaces the default prompt. For Smart View and Auto Reading modes, the default prompt is always used regardless of voice input.

## Streaming Behavior

The primary interaction uses `sendMessageStream()` for real-time response delivery.

### Streaming Pipeline

```
Gemini API stream → AgentService.sendStreamingMessage()
  ├── Each chunk.text accumulated character by character
  ├── On sentence end (.) or 100 words:
  │     ├── Clean text (strip *, ", .)
  │     ├── Check session ID still valid
  │     ├── Call onStartSpeaking() (transition to speaking state)
  │     └── ttsService.speak(cleanedText, sessionId)
  │           ├── Google Cloud TTS API → base64 MP3
  │           └── AudioPlayerService.enqueue(audioBytes)
  ├── On stream done:
  │     └── Speak any remaining text
  └── On error:
        └── Log and cancel
```

### Session Invalidation

- `AgentService.streamSessionId` tracks current stream session
- `stopStream()` sets `streamSessionId = -1`, adds partial response to chat history (guarded by `_isStopping` flag to prevent duplicate calls), cancels subscription
- Before each TTS call **and before accumulating `agentResponse`**, session ID is checked — mismatches discard the chunk
- `GoogleTTSService` uses a monotonic `_sessionCounter` (not DateTime) to guarantee unique session IDs

## Response Validation and Post-Processing

### Text Cleaning

`Devicehelper.cleanAgentResponse()` strips:
- `*` → ` ` (space)
- `"` → removed
- `.` → removed

This is applied before TTS to avoid Markdown formatting artifacts being spoken.

### Image Correction Response

JSON response parsed with error handling:
```dart
Map<String, dynamic> jsonResponse = jsonDecode(response.text!);
```
On parse failure → `ImageCorrectionResponse(isImageCorrect: true)` (permissive).

## Hallucination Mitigation

- System prompts include explicit checklists ("CHECKLIST BEFORE SENDING")
- Auto Reading Mode: "Read the text exactly as written" — constrains output to image content
- Image Correction: Structured JSON output with schema enforcement reduces freeform hallucination
- Normal Mode: System prompt instructs to respond based on what is seen in the image

## Safety Filtering

- No explicit safety settings configured in `GenerativeModel`
- Gemini's default safety filters apply
- System prompts do not explicitly address harmful content filtering

**Recommendation:** Consider adding `SafetySetting` parameters for categories like HARM_CATEGORY_HARASSMENT, etc.

## Fallbacks When Gemini Fails

| Failure | Current Behavior |
|---|---|
| `GenerativeAIException` | Error message string returned, spoken to user |
| Generic exception | "An unexpected error occurred: {error}" spoken to user |
| No internet | Checked before Gemini call — TTS "Internet not available" |
| Stream cancelled by user | Partial response saved to chat history |
| Image correction parse error | Image treated as correct — main flow continues |

**Note:** There is no retry mechanism for Gemini failures. The user must re-initiate the interaction.

## Chat History Management

| Action | Effect |
|---|---|
| New image interaction (non-history mode) | `_agentService.reset()` — clears history |
| History mode query | History preserved — multi-turn conversation |
| Mode change (Smart View, Auto Reading) | Agent re-initialized with new system prompt |
| Stop speaking | Partial response added to history, agent re-initialized |
| Return from ProfilePage | Agent re-initialized with new settings |

## Language Handling

| Language | STT Locale | Gemini Communication Language | TTS Voice |
|---|---|---|---|
| English | `en_IN` | `English` | `en-IN-Chirp3-HD-Alnilam` |
| Marathi | `mr_IN` | `Marathi` | `mr-IN-Chirp3-HD-Achird` |

The mapping `inputLanguageToCommunicationLanguage` in `TextService` converts locale codes to Gemini-understandable language names.

TTS language is auto-detected per sentence using Devanagari script detection — even in English mode, any Marathi text in Gemini's response will be spoken with the Marathi voice.

## Rate Limiting

No client-side rate limiting is implemented. Gemini API quotas are managed server-side by Google.

## Analytics

Every successful Gemini response increments:
- `ResponseCount`
- `EnglishResponseCount` or `MarathiResponseCount` (based on `inputLanguage`)

Errors increment:
- `PromptErrorCount`
