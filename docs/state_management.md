# State Management

## Approach

The app uses **Provider** with a single `ChangeNotifier` — `ConversationController` — as the central state manager. It is created at the root `MaterialApp` via `ChangeNotifierProvider`.

There is no Bloc, Riverpod, or other state management library.

## Source of Truth

| Data | Source of Truth | Storage |
|---|---|---|
| Conversation state (idle/listening/etc.) | `AppContentState.conversationState` | In-memory |
| Interaction mode | `AppContentState.interactionMode` | In-memory |
| Current image bytes | `ConversationController._imageBytes` | In-memory |
| Video file | `ConversationController.videoFile` | Temp file on disk (cleared to empty `File('')` before each `processInput` call) |
| Agent response text | `AppContentState.agentResponse` | In-memory |
| User recognized speech | `AppContentState.userRecognisedWords` | In-memory |
| Chat history | `AgentService.chatHistory` / `ChatSession` | In-memory |
| User preferences | `SharedPreferences` | Local persistent storage |
| User profile/subscription | Firestore | Cloud |
| Auth state | `FirebaseAuth` | Cloud + local cache |

## Local State vs Shared State

| Scope | State | Location |
|---|---|---|
| **App-wide (shared)** | `ConversationController` via Provider | Accessed by `HomeScreen`, `ProfilePage` (indirectly via settings) |
| **Screen-local** | Camera controller, form controllers, loading flags | `_HomeScreenState`, `_RegistrationPageState`, etc. |
| **Service-internal** | TTS session ID (monotonic counter), audio queue + generation, stream subscription + stopping guard | `GoogleTTSService`, `AudioPlayerService`, `AgentService` |
| **Operation guards** | `_operationId` (monotonic), `_isProcessingInput` reentry guard, `_isToggling` UI debounce | `ConversationController`, `_HomeScreenState` |

## Async State Lifecycle

### Conversation Flow State Machine

```
                        ┌───────────────────────────────────┐
                        │                                   │
                        ▼                                   │
  ┌──────┐  tap/mode  ┌───────────┐  STT done  ┌──────────┴──┐
  │ idle │ ──────────► │ listening │ ──────────► │ processing  │
  └──┬───┘             └───────────┘             └──────┬──────┘
     │                                                   │
     │  long-press                          first chunk  │
     │                                      arrives      │
     ▼                                                   ▼
  ┌────────────────┐                           ┌──────────────┐
  │ videoRecording │                           │   speaking   │
  └───────┬────────┘                           └──────┬───────┘
          │                                           │
          │  release/timer                  queue empty│
          ▼                                    + done  │
       ┌──────┐                                       │
       │ idle │ ◄─────────────────────────────────────┘
       └──────┘

  Any state ──(tap during active)──► idle (via stopSpeaking/stopSpeakingForGoogleSearch)

  Special: idle → failed (STT initialization error)
```

### Loading / Empty / Error / Success States

| State | Indicator | Recovery |
|---|---|---|
| App loading (camera init) | `CircularProgressIndicator` | Wait for init to complete |
| Processing Gemini response | Mic icon shows `Icons.loop`; TTS says "Processing Response" | Tap to cancel |
| Speaking response | Mic icon shows `Icons.pause` | Tap to stop |
| No internet | TTS speaks alert; `AlasInternetPage` at launch | Check connection |
| STT failed | `ConversationState.failed` | TODO: No UI recovery mechanism documented |
| Empty response | No special handling — idle state returns | N/A |

## Rebuild Boundaries

- `ConversationController` calls `notifyListeners()` on every state change
- `HomeScreen` calls `Provider.of<ConversationController>(context)` in `build()` — rebuilds on every notification
- `MicButton`, `SideBarButton`, `ImagePreview` are stateless — they rebuild when parent rebuilds
- No `Selector` or `Consumer` widgets are used — the entire `HomeScreen` body rebuilds on state changes

**Performance note:** This is acceptable because the UI is simple, but adding `Consumer` widgets around individual sections could reduce unnecessary rebuilds.

## State Mutation Rules

| Rule | Detail |
|---|---|
| All mutations via `ConversationController` | No direct mutation of `AppContentState` from UI |
| `notifyListeners()` after every mutation | Ensures UI always reflects current state |
| Mode changes re-initialize AgentService | `initializeAgent()` called with new mode's system prompt |
| `stopSpeaking()` resets to idle | Cancels stream, stops TTS, resets mode to normal |
| `doneSpeaking()` auto-fires on queue empty | TTS service callback → controller method |
| `processInput()` is the main pipeline | Handles internet check, prompt construction, Gemini call, streaming. Clears `agentResponse` at entry. `sendStreamingMessage` uses a `Completer` so the guard is not released until the stream completes. |

## SharedPreferences Keys

| Key | Type | Default | Purpose |
|---|---|---|---|
| `inputLanguage` | `String` | `'en_IN'` | STT locale and prompt language |
| `speechRate` | `double` | `1.0` | Google Cloud TTS speech rate |
| `enableTranslation` | `bool` | `false` | Translate text content in reading modes |
| `useFrontCamera` | `bool` | `false` | Camera selection |
| `emergencyContact` | `String` | `''` | Emergency contact number (stored but not used in current code) |
| `contactNumber` | `String` | — | User's phone number (set during OTP flow) |
| `UserUId` | `String` | — | Firebase UID (set during OTP flow) |
