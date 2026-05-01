# Copilot Instructions — Letsee (papa_pro_vision)

## What This App Is

Letsee is a Flutter app for **blind and visually impaired users** in India. It captures camera images/video, sends them to Google Gemini with a voice query, and speaks the response via Google Cloud TTS. Supports English (India) and Marathi.

## Critical Rules

1. **Accessibility is not optional.** Every new widget must have a `Semantics` label. Every state change must produce audio feedback (TTS or sound effect). Blind users cannot see the screen.
2. **Never break the streaming pipeline.** The flow is: Gemini stream → sentence chunking → Google TTS per chunk → AudioPlayerService queue. Changing any part of this chain affects all interaction modes.
3. **All 4 interaction modes share ConversationController.** Normal, Smart View, Auto Reading, and Video modes all flow through `processInput()`. Test all modes when changing shared code.
4. **API keys are hardcoded** in `lib/secrets.dart` and `lib/Payment/payment_gatway.dart`. Do not log them or add new hardcoded keys. Use the existing `Secrets` class.
5. **No internet = no functionality.** All Gemini and TTS calls require network. Always check `Devicehelper.hasInternetConnectionAndNotify()` before network operations.
6. **System prompts are in `lib/LLMResponse/system_prompt_enums.dart`.** They use `{communicationLanguage}` placeholder. Changing a prompt affects all users immediately.
7. **Firestore schema is documented in `docs/data_model.md`.** The schema comment block at the top of `DatabaseHelper.dart` must stay in sync.

## Architecture Quick Reference

- **State management:** Single `ConversationController` (ChangeNotifier) via Provider
- **LLM:** `AgentService` wraps `gemini-2.0-flash`. `ImageCorrectionService` uses `gemini-2.5-flash` (currently **disabled**)
- **TTS:** `GoogleTTSService` (primary) → Google Cloud TTS REST API → `AudioPlayerService` (queue)
- **STT:** `speech_to_text` plugin (on-device)
- **Auth:** Firebase Phone OTP
- **DB:** Firestore (Users, Organisations, ReferralKey, KilledAPKVersions, PaymentCost)
- **Payments:** Razorpay

## State Machine

```
idle → listening → processing → speaking → idle
idle → videoRecording → idle → listening → processing → speaking → idle
any → idle (user tap to stop)
idle → failed (STT init error)
```

## Key Conventions

- Audio feedback: use `DeviceAudioHelper` for UI sounds, `ttsService.speak(text, isIntermediate: true)` for spoken announcements
- Haptics: `lightImpact` = success, `mediumImpact` = action started, `heavyImpact` = error
- TTS language: auto-detected per sentence via `Devicehelper.IsDevanagari()` (Devanagari → Marathi voice, else → English voice)
- Error handling: catch, log with `print()`, return user-friendly message or skip gracefully. No retry mechanisms exist.
- Analytics: increment counters via `Analyticshelper.updateResponseCount(type, userUID)`

## File Naming

- Existing code uses PascalCase filenames (`DatabaseHelper.dart`, `DeviceHelper.dart`). Follow this convention.
- New helper classes go in `lib/Helper/`
- New UI screens go in `lib/UI/`
- New widgets go in `lib/UI/widgets/`

## Docs

Full documentation is in `docs/`. Start with `docs/index.md` for the file map.

| When doing | Read first |
|---|---|
| Changing Gemini prompts or modes | `docs/llm_integration.md` |
| Changing Firestore reads/writes | `docs/data_model.md` + `docs/api_contracts.md` |
| Changing UI or adding screens | `docs/navigation_and_ui_map.md` |
| Changing conversation flow | `docs/state_management.md` |
| Adding external API calls | `docs/api_contracts.md` |
| Fixing accessibility | `docs/accessibility.md` |
