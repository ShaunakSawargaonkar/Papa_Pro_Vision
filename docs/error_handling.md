# Error Handling

## Error Taxonomy

| Category | Examples | Handling |
|---|---|---|
| **Network** | No internet, timeout, DNS failure | TTS alert + action abort |
| **Gemini API** | `GenerativeAIException`, rate limit, invalid input | Error message spoken to user |
| **Google TTS API** | HTTP error, invalid response | Sentence skipped, queue continues |
| **Firebase Auth** | Invalid phone, too many requests, timeout | SnackBar error message |
| **Firestore** | Read/write failures, permission denied | Error message in response DTO |
| **Razorpay** | Payment failure, gateway error | Toast message |
| **Camera** | Init failure, capture error | Error logged, loading indicator shown |
| **STT** | Init failure, recognition error | State → failed, mic off sound |
| **JSON Parse** | Image correction response malformed | Permissive fallback (treat as correct) |

## User-Facing Errors vs Developer Errors

### User-Facing

| Error | Presentation | Recovery |
|---|---|---|
| No internet | TTS speaks "Internet not available..." | User checks connection |
| Gemini error | Error text spoken via TTS | User retries |
| Auth failure | SnackBar with translated message | User retries |
| Payment failure | Toast message | User retries |
| Account disabled | AlasPage with message | Contact support |
| Killed APK | AlasPage with update message | Update app |
| Multiple accounts | AlasPage "Contact support" | Contact support |
| Referral key invalid | SnackBar error | Re-enter key |
| Form validation | SnackBar "Please fill all required fields" | Fix form |

### Developer/Debug Only

| Error | Location | Output |
|---|---|---|
| Camera init failure | `_HomeScreenState._initialize()` | `print()` |
| TTS API failure details | `GoogleTTSService.speak()` | `print()` |
| Firestore query details | `DatabaseHelper` methods | `print()` |
| Stream cancellation | `AgentService` | `print()` |
| Audio playback failure | `_AudioManager.playSound()` | `print()` |

## Network Failures

### Detection
`Devicehelper.hasInternetConnectionAndNotify()`:
- DNS lookup to `google.com` with 2-second timeout
- On failure: `DeviceAudioHelper.playInternetNotAvailableSound()` (FlutterTTS speaks alert)
- Returns `false` to caller

### Call Sites

| Operation | Internet Check | Behavior on Failure |
|---|---|---|
| `checkUserStatus()` | Yes | Returns `UserStatus.noInternet` |
| `processInput()` | Yes | Resets to idle, returns |
| `setHistoryMode()` | Yes | Returns without action, print log |
| `unsetHistoryMode()` | Yes | Returns without action, print log |
| `updateResponseCount()` | Yes | Returns without updating |
| `GoogleTTSService.speak()` streaming | Yes (in `sendStreamingMessage`) | Returns without streaming |

## API Failures

### Gemini

```dart
on GenerativeAIException catch (e) {
  Analyticshelper.updateResponseCount("PromptErrorCount", userUID);
  return "Error from AI Service: $e";
}
catch (e) {
  return "An unexpected error occurred: $e";
}
```

The error string is returned through the normal response pipeline and may be spoken to the user.

### Google Cloud TTS

```dart
catch (e) {
  Analyticshelper.updateResponseCount("TTSErrorCount", userUID);
  print("TTS error for '$trimmed': $e");
}
```

Failed sentence is skipped. Audio queue continues with next sentence.

### Razorpay

```dart
void _handlePaymentErrorSafely(dynamic response) {
  // Handles PaymentFailureResponse, String, Map, and unknown types
  // Shows Fluttertoast with error message
}
```

## Parsing Failures

| Source | Failure Mode | Handling |
|---|---|---|
| Image correction JSON | `jsonDecode` throws | `ImageCorrectionResponse(isImageCorrect: true)` — permissive |
| TTS audio content | Base64 decode fails | Exception propagated to catch block, sentence skipped |
| Firestore data cast | `as Map<String, dynamic>` fails | Exception propagated to outer catch |
| Payment price parse | `int.tryParse` returns null | Falls back to default `299` |

## LLM Failure Modes

| Failure | Current Behavior | Impact |
|---|---|---|
| Gemini returns empty text | Empty chunk skipped in streaming | Possible silence |
| Gemini returns very long response | Chunked at sentence boundaries + 100-word limit | TTS queue grows |
| Gemini returns Markdown formatting | `*` and `"` stripped by `cleanAgentResponse()` | Mostly handled |
| Gemini returns content in wrong language | Not handled — TTS detects script and uses appropriate voice | Acceptable |
| Gemini stream error (mid-stream) | `onError` callback cancels stream, logs error | Response truncated |
| Gemini refuses to answer (safety filter) | SDK may throw or return filtered response | Error message spoken |

## Retry Policy

**Current state: No retry mechanism exists for any operation.**

| Operation | Retry | Recommendation |
|---|---|---|
| Gemini API call | None | User re-initiates |
| Google TTS call | None | Sentence skipped |
| Internet check | None | User manually retries |
| Firebase Auth | None | User retries via UI |
| Firestore operations | None | Error returned to caller |
| Razorpay | SnackBar "Retry" action available | Manual retry via button |

## Fallback UX

| Scenario | Fallback |
|---|---|
| Image correction fails | Main flow continues normally |
| Video frame extraction fails | Send full MP4 video instead |
| Google TTS fails for a sentence | Skip sentence, continue queue |
| Internet lost during streaming | Stream error caught, response truncated |
| Camera init fails | Loading spinner shown |
| STT init fails | `ConversationState.failed` set |

## Logging

All error logging uses `print()` statements. There is no structured logging, log levels, or conditional debug/release logging.

## Debugging Information

### Key Print Statements for Debugging

| Location | Pattern | Purpose |
|---|---|---|
| `AgentService` streaming | `[STREAM CHUNK n]`, `[TTS START #n]` | Track streaming progress |
| `AudioPlayerService` | `"Enqueuing audio"`, `"Playing audio"` | Track audio queue |
| `DatabaseHelper` | `"Checking user status"`, `"Creating user"` | Track Firestore operations |
| `DeviceAudioHelper` | `"Playing ... Sound"` | Track audio feedback |
| `HomeScreen` | `"Before toggle:"`, `"After toggle:"` | Track user interaction flow |
