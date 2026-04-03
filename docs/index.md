# Letsee — Documentation Home

## Purpose

This documentation set is the **source of truth** for the Letsee (package: `papa_pro_vision`) Flutter application. It is written for AI coding assistants and human developers to enable:

- Feature implementation without re-deriving architecture
- Bug fixing without guessing service boundaries
- Safe API and prompt contract changes
- Test writing aligned to documented behavior

## How to Use These Docs

| Task | Start Here |
|---|---|
| System boundaries and external deps | [System Context](system_context.md) |
| Architecture, data flows, error propagation | [High-Level Design](hld.md) |
| Module map, class responsibilities | [Low-Level Design](lld.md) |
| Screens, navigation, layout | [Navigation & UI Map](navigation_and_ui_map.md) |
| State machine, Provider, SharedPreferences | [State Management](state_management.md) |
| Firestore schema, DTOs, enums | [Data Model](data_model.md) |
| Gemini, TTS, Razorpay, Firebase APIs | [API Contracts](api_contracts.md) |
| Prompts, streaming pipeline, modes | [LLM Integration](llm_integration.md) |
| Screen reader, TTS, haptics, audio cues | [Accessibility](accessibility.md) |
| Error taxonomy, fallbacks, failure modes | [Error Handling](error_handling.md) |
| All implemented and disabled features | [Feature Inventory](feature_inventory.md) |
| Unresolved gaps and known issues | [Open Questions](open_questions.md) |

## Conventions

- Use canonical names from [enums.dart](../lib/enums.dart) and the terms defined in each doc file consistently.
- Sections marked `TODO` or `UNKNOWN` indicate gaps discovered during documentation — they are intentional, not oversights.
- "Current Implementation" describes what the code does today. "Planned / Proposed" describes intent not yet in code.
- All file paths are relative to project root (`d:\SideProjects\Papa_Pro_Vision\`).

## App Identity

| Property | Value |
|---|---|
| Package name | `papa_pro_vision` |
| Display name | `Letsee` (shown in AppBar as `Letsee`) |
| App ID | `com.letsee.letsee` |
| Version | `5.5.8+8` |
| Min Android SDK | 24 |
| Dart SDK | `^3.8.1` |
