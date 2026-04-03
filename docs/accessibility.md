# Accessibility

This app is designed **primarily for blind and visually impaired users**. Accessibility is not an afterthought — it is the core purpose.

## Accessibility-First Design Rules

1. **Every interaction must be operable without vision.** The user should never need to see the screen to use core features.
2. **Audio feedback for all actions.** Every button press, state change, and error must produce an audible signal.
3. **Haptic feedback for confirmations and errors.** Vibration patterns reinforce important events.
4. **Minimal reliance on visual indicators.** Text display of responses is secondary to TTS output.

## Screen Reader Semantics

### Current Implementation

| Widget | Semantics Label | `excludeSemantics` |
|---|---|---|
| Settings button (AppBar) | `"Profile Settings button"` | `true` |
| Camera preview / Clear image | `"Clear image"` (if image loaded) or `"Camera feed"` | `true` |
| Green mic button | Dynamic: `"Stop listening"` / `"Stop speaking"` / `"Ask any question with chat history"` | `true` |
| Yellow mic button | Dynamic: `"Stop listening"` / `"Stop speaking"` / `"Ask question on an image"` | `true` |

### Gaps

- **Sidebar buttons** ("Reader Mode", "Smart View Mode") — no explicit `Semantics` wrapper. Rely on text content.
- **Copy Response button** — no `Semantics` label. Uses `ElevatedButton.icon` which may infer label from text.
- **PaymentGateway** subscription plan cards — no explicit accessibility labels.
- **RegistrationPage** form fields — standard Material `TextFormField` with `labelText` (inherently accessible).
- **ImagePreview** — no `Semantics` wrapper on the image itself.
- **AlasPage** error messages — standard `Text` widgets (inherently accessible).

## Focus Order

No explicit focus order management (`FocusTraversalGroup`, `FocusTraversalPolicy`) is implemented. Focus order follows default widget tree order:
1. AppBar (settings button)
2. Camera preview area
3. Sidebar buttons (left/right)
4. Mic buttons (left/right)
5. Copy Response button (if visible)

**Recommendation:** Consider adding `FocusTraversalOrder` for critical elements, especially the mic buttons which are the primary interaction targets.

## Text-to-Speech (TTS)

### Architecture

Two TTS implementations:
1. **Google Cloud TTS** (primary) — higher quality, requires network
2. **Flutter TTS** (fallback) — device-level, used for simple announcements

### When TTS is Used

| Event | TTS Method | Content |
|---|---|---|
| Gemini response streaming | `GoogleTTSService.speak()` | Sentence-by-sentence from Gemini |
| Processing indicator | `ttsService.speak(isIntermediate: true)` | "Processing Response" / "विचार करतोय" |
| Smart View mode activation | `ttsService.speak(isIntermediate: true)` | "Processing Smart View" |
| Reader Mode activation | `ttsService.speak(isIntermediate: true)` | "Reading Mode" |
| Image correction guidance | `ttsService.speak(isIntermediate: true)` | Camera movement instructions |
| No internet | `FlutterTts.speak()` | "Internet not available. Please check your connection and try again." |

### Speech Rate Control

User-configurable via ProfilePage slider (0.25 to 2.0, default 1.0). Saved in SharedPreferences as `speechRate`. Applied to Google Cloud TTS API `speakingRate` parameter.

### Language Auto-Detection

Per-sentence detection: if text contains Devanagari characters → Marathi TTS voice; otherwise → English TTS voice. This allows mixed-language responses to be spoken naturally.

## Speech Input (STT)

| Aspect | Detail |
|---|---|
| Plugin | `speech_to_text` ^7.3.0 |
| Engine | OS-level (Android/iOS built-in) |
| Locale | `en_IN` or `mr_IN` (from SharedPreferences `inputLanguage`) |
| Trigger | Mic button tap → `controller.startListening()` |
| Completion | `onStatus: 'done'` callback → processes recognized words |
| Error handling | `onError` callback → plays mic off sound, sets state to failed |

## Audio Feedback (Sound Effects)

All UI sounds managed by `DeviceAudioHelper` using `_AudioManager` singleton.

| Action | Sound | Source |
|---|---|---|
| Image captured | Camera click | `assets/sounds/camera-13695.mp3` |
| Clear image | Delete sound | `assets/sounds/mag-remove-92075.mp3` |
| Video recording start | Focus sound | System: `/system/media/audio/ui/camera_focus.ogg` |
| Mic on (start listening) | Record start | System: `/system/media/audio/ui/VideoRecord.ogg` |
| Mic off (stop listening) | Record stop | System: `/system/media/audio/ui/VideoStop.ogg` |
| No internet | Spoken string | FlutterTTS: "Internet not available..." |

**Fallback pattern:** System sounds attempt multiple paths (e.g., `camera_focus.ogg`, then `VideoRecord.ogg`, then `Effect_Tick.ogg`).

## Haptic Feedback

| Event | Haptic Type | Location |
|---|---|---|
| OTP sent successfully | `HapticFeedback.lightImpact()` | PhoneAuthPage |
| Send OTP pressed | `HapticFeedback.mediumImpact()` | PhoneAuthPage |
| Validation error | `HapticFeedback.heavyImpact()` | PhoneAuthPage, RegistrationPage |
| Auto-sign-in success | `HapticFeedback.lightImpact()` | PhoneAuthPage |
| Form submission | `HapticFeedback.mediumImpact()` | RegistrationPage |
| Payment checkout opened | `HapticFeedback.mediumImpact()` | PaymentGateway |
| Payment success | `HapticFeedback.lightImpact()` | PaymentGateway |
| Payment failure | `HapticFeedback.heavyImpact()` | PaymentGateway |

**Pattern:**
- Light impact = success confirmation
- Medium impact = action initiated
- Heavy impact = error / validation failure

## Contrast and Visual Design

| Property | Value |
|---|---|
| Theme brightness | `Brightness.dark` |
| Scaffold background | `Colors.black` |
| Primary action color | Gold (#FCB853) |
| Mic button (history) | Green |
| Mic button (image) | Yellow |
| Active mic state | White background |
| Sidebar buttons | White 25% opacity with blur backdrop |
| Sidebar text | White with heavy black shadows (3 shadow layers) |
| AlasPage background | Gold (#FCB853) with white card |

## Touch Target Sizes

| Element | Size |
|---|---|
| Mic buttons | `32% of screen width` (circle) — typically ~115px on 360px-wide device |
| Sidebar buttons | `15% of screen width` × full camera height — large touch target |
| Entire left/right mic areas | `50% of screen width` each — entire half is tappable |
| Settings icon | AppBar default (`48x48`) |
| Copy Response button | Full width with padding |

**Assessment:** Touch targets are generous, appropriate for blind users who rely on approximate spatial knowledge.

## Error Announcements

| Error | Announcement Method |
|---|---|
| No internet | TTS: "Internet not available. Please check your connection and try again." |
| Gemini API error | TTS: Error message spoken aloud (via normal response pipeline) |
| STT failure | Sound: mic off sound plays |
| Image correction needed | TTS: "Your request is not completely answerable given the image. Please [movement instruction]" |

## Behavior for Blind Users

### Spatial Layout Contract

The home screen has a consistent spatial layout that blind users memorize:
- **Top half**: Camera preview (tap to clear image)
- **Left edge**: Reader Mode
- **Right edge**: Smart View Mode
- **Bottom left**: Chat History mic (green)
- **Bottom right**: Image Ask mic (yellow) — long-press for video

### Interaction Flow (No Vision Needed)

1. Open app → audio feedback indicates ready state
2. Tap bottom-right → camera click sound → mic on sound → speak question → mic off sound
3. Wait → "Processing Response" spoken → response streamed as speech
4. Tap during speech → speaking stops
5. Tap left edge → "Reading Mode" spoken → camera click → text read aloud
6. Tap right edge → "Processing Smart View" spoken → camera click → scene described

### Recommended Improvements

1. Add spoken announcement when app first reaches home screen ("Ready" or "Letsee is ready")
2. Add Semantics for sidebar buttons
3. Consider adding a training/tutorial mode for new users
4. Add explicit Semantics for image preview state changes
5. Consider adding TalkBack gesture customization
