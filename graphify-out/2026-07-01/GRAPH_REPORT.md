# Graph Report - lib  (2026-07-01)

## Corpus Check
- Corpus is ~15,796 words - fits in a single context window. You may not need a graph.

## Summary
- 445 nodes · 616 edges · 16 communities
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 9 edges (avg confidence: 0.91)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_App State & Agent Orchestration|App State & Agent Orchestration]]
- [[_COMMUNITY_Home Screen & Camera Capture|Home Screen & Camera Capture]]
- [[_COMMUNITY_LLM Chat & Device Helpers|LLM Chat & Device Helpers]]
- [[_COMMUNITY_TTS Engines (FlutterGoogle)|TTS Engines (Flutter/Google)]]
- [[_COMMUNITY_Device Audio & Sound Effects|Device Audio & Sound Effects]]
- [[_COMMUNITY_Enums & Subscription Types|Enums & Subscription Types]]
- [[_COMMUNITY_Payment Gateway (Razorpay)|Payment Gateway (Razorpay)]]
- [[_COMMUNITY_Firestore Database Helper|Firestore Database Helper]]
- [[_COMMUNITY_Registration Screen|Registration Screen]]
- [[_COMMUNITY_App Entry & Internet Gating|App Entry & Internet Gating]]
- [[_COMMUNITY_File Sharing & Service Locator|File Sharing & Service Locator]]
- [[_COMMUNITY_Phone Auth Screen|Phone Auth Screen]]
- [[_COMMUNITY_Pricing & Localized Text|Pricing & Localized Text]]
- [[_COMMUNITY_LLM System Prompts|LLM System Prompts]]
- [[_COMMUNITY_Profile Screen|Profile Screen]]

## God Nodes (most connected - your core abstractions)
1. `HomeScreen` - 14 edges
2. `MyApp` - 9 edges
3. `Devicehelper.hasInternetConnectionAndNotify` - 8 edges
4. `RegistrationPage` - 7 edges
5. `Analyticshelper.updateResponseCount` - 6 edges
6. `ConversationController` - 6 edges
7. `state` - 6 edges
8. `AgentService.sendGoogleSearchMessage` - 5 edges
9. `AgentService.sendStreamingMessage` - 5 edges
10. `ConversationController.processInput` - 5 edges

## Surprising Connections (you probably didn't know these)
- `AudioPlayerService (queued playback)` --semantically_similar_to--> `_AudioManager (audio playback singleton)`  [INFERRED] [semantically similar]
  lib/Txt2Speech/AudioPlayer/audio_player.dart → lib/Helper/DeviceAudioHelper.dart
- `Devicehelper.hasInternetConnectionAndNotify` --calls--> `DeviceAudioHelper.playInternetNotAvailableSound`  [EXTRACTED]
  lib/Helper/DeviceHelper.dart → lib/Helper/DeviceAudioHelper.dart
- `AlasInternetPage` --semantically_similar_to--> `AlasPage`  [INFERRED] [semantically similar]
  lib/UI/RegisterPage/AlasInternet.dart → lib/UI/RegisterPage/AlasPage.dart
- `PhoneAuthPage` --shares_data_with--> `RegistrationPage`  [INFERRED]
  lib/UI/auth/phone_auth_page.dart → lib/UI/RegisterPage/registration_page.dart
- `RegistrationPage._buildFormField` --semantically_similar_to--> `PhoneAuthPage._buildFormField`  [INFERRED] [semantically similar]
  lib/UI/RegisterPage/registration_page.dart → lib/UI/auth/phone_auth_page.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Text-to-Speech pipeline (interface, implementations, playback, factory)** — lib_txt2speech_service_locator_texttospeechservice, lib_txt2speech_models_google_tts_googlettsservice, lib_txt2speech_models_flutter_tts_fluttertsservice, lib_txt2speech_audioplayer_audio_player_audioplayerservice, lib_txt2speech_service_locator_setupttsservice [INFERRED 0.85]
- **Payment and subscription activation flow** — lib_payment_payment_gatway_paymentgatewaystate, lib_payment_payment_utils_paymentservice, lib_payment_payment_utils_fetchpaymentcosts, lib_helper_databasehelper_setsubscriptioninformation [INFERRED 0.85]
- **Streaming LLM response with TTS playback and analytics** — lib_statemanagement_button_state_provider_processinput, lib_llmresponse_agent_service_sendstreamingmessage, lib_txt2speech_models_google_tts_googlettsservice, lib_helper_analyticshelper_updateresponsecount [INFERRED 0.75]
- **App auth and registration routing flow** — lib_main_myapp, lib_ui_auth_phone_auth_page_phoneauthpage, lib_ui_registerpage_registration_page_registrationpage, lib_ui_home_screen_homescreen, lib_ui_registerpage_alaspage_alaspage [INFERRED 0.85]
- **Home screen camera interaction widgets** — lib_ui_home_screen_homescreen, lib_ui_widgets_image_preview_imagepreview, lib_ui_widgets_mic_button_micbutton, lib_ui_widgets_side_bar_button_sidebarbutton [INFERRED 0.85]
- **Screens sharing SharedPreferences settings state** — lib_ui_profile_page_profilepage, lib_ui_home_screen_homescreen, lib_ui_auth_phone_auth_page_phoneauthpage, lib_ui_registerpage_registration_page_registrationpage [INFERRED 0.75]

## Communities (16 total, 0 thin omitted)

### Community 0 - "App State & Agent Orchestration"
Cohesion: 0.04
Nodes (48): AgentService?, AppContentState get, FileSharingHelper?, InteractionMode?, AgentService, agentResponse, _agentService, AppContentState (shared conversation state) (+40 more)

### Community 1 - "Home Screen & Camera Capture"
Cohesion: 0.05
Nodes (40): CameraController, ChangeNotifier, dart:typed_data, ConversationController, state, HomeScreen.appBar, build, cameraController (+32 more)

### Community 2 - "LLM Chat & Device Helpers"
Cohesion: 0.07
Nodes (39): ChatSession, dart:io, File, Analyticshelper, Analyticshelper.updateResponseCount, Devicehelper.checkRegistration, Devicehelper.cleanAgentResponse, Devicehelper (+31 more)

### Community 3 - "TTS Engines (Flutter/Google)"
Cohesion: 0.07
Nodes (31): AppContentState, AudioPlayerService?, dart:convert, Devicehelper.IsDevanagari, AudioPlayerService.enqueue, _appContentState, _flutterTts, speak (+23 more)

### Community 4 - "Device Audio & Sound Effects"
Cohesion: 0.07
Nodes (30): AudioPlayer, bool get, _AudioManager (audio playback singleton), _audioPlayer, _currentSoundType, DeviceAudioHelper, dispose, _instance (+22 more)

### Community 5 - "Enums & Subscription Types"
Cohesion: 0.07
Nodes (29): ConversationState, dart:ui, firstMonthFree,
  oneMonth,
  threeMonths,
  sixMonths,, ConversationState, getDaysDuration, InteractionMode, oneYear, SubscriptionBundleType (+21 more)

### Community 6 - "Payment Gateway (Razorpay)"
Cohesion: 0.07
Nodes (30): accentBlue, accentGreen, build, _buildPlanCard, createState, dispose, _getDisplayPlans, _getResponsiveValues (+22 more)

### Community 7 - "Firestore Database Helper"
Cohesion: 0.07
Nodes (29): DocumentReference?, DatabaseHelper.checkKilledAPKVersions, DatabaseHelper.checkSubscriptionStatus, DatabaseHelper.checkUserStatus, createUser, CreateUserResponse, DatabaseHelper, isKilled (+21 more)

### Community 8 - "Registration Screen"
Cohesion: 0.08
Nodes (26): UserType, _ageController, build, _buildOrganizationForm, _buildUserDetailsForm, createState, dispose, _formKey (+18 more)

### Community 9 - "App Entry & Internet Gating"
Cohesion: 0.09
Nodes (23): UserStatus, UserStatusResponse, build, initializeApp, main, MyApp, AlasInternetPage, build (+15 more)

### Community 10 - "File Sharing & Service Locator"
Cohesion: 0.09
Nodes (22): dart:async, GetIt, dispose, FileSharingHelper, initialize, _intentSub, FileSharingHelper.intentSubListener, FileSharingHelper.processSharedImage (+14 more)

### Community 11 - "Phone Auth Screen"
Cohesion: 0.11
Nodes (21): build, PhoneAuthPage._buildFormField, _codeController, _codeSent, createState, dispose, _error, _formKey (+13 more)

### Community 12 - "Pricing & Localized Text"
Cohesion: 0.11
Nodes (17): _PaymentGatewayState._initializePaymentCosts, _calculateSavings, PaymentService.fetchPaymentCosts, initialSubscriptionPlans, monthlyPrice, monthlyPriceStr, PaymentService, subscriptionPlans (+9 more)

### Community 13 - "LLM System Prompts"
Cohesion: 0.11
Nodes (17): CHECK BEFORE, CHECKLIST BEFORE, AgentService._getSystemPrompt, autoReadingSystemPrompt, autoReadingSystemPromptWithTranslation, rule, RULES, SENDING (+9 more)

### Community 14 - "Profile Screen"
Cohesion: 0.12
Nodes (16): FormState, ../Helper/DeviceAudioHelper.dart, build, createState, dispose, _emergencyContactController, _enableTranslation, _formKey (+8 more)

## Knowledge Gaps
- **242 isolated node(s):** `Analyticshelper`, `ReferralKeyResponse`, `CreateUserResponse`, `KilledAPKVersionResponse`, `DatabaseHelper` (+237 more)
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AgentService._getSystemPrompt` connect `LLM System Prompts` to `LLM Chat & Device Helpers`?**
  _High betweenness centrality (0.074) - this node is a cross-community bridge._
- **Why does `HomeScreen` connect `Enums & Subscription Types` to `App Entry & Internet Gating`, `Profile Screen`, `Home Screen & Camera Capture`, `Payment Gateway (Razorpay)`?**
  _High betweenness centrality (0.045) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `HomeScreen` (e.g. with `ProfilePage` and `ProfilePage._saveUserData`) actually correct?**
  _`HomeScreen` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Analyticshelper`, `ReferralKeyResponse`, `CreateUserResponse` to the rest of the system?**
  _242 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `App State & Agent Orchestration` be split into smaller, more focused modules?**
  _Cohesion score 0.04421768707482993 - nodes in this community are weakly interconnected._
- **Should `Home Screen & Camera Capture` be split into smaller, more focused modules?**
  _Cohesion score 0.0545876887340302 - nodes in this community are weakly interconnected._
- **Should `LLM Chat & Device Helpers` be split into smaller, more focused modules?**
  _Cohesion score 0.06504065040650407 - nodes in this community are weakly interconnected._