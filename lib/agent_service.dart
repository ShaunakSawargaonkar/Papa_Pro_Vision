import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
import 'package:papa_pro_vision/Helper/AnalyticsHelper.dart';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';
import 'package:papa_pro_vision/text_service.dart';
import 'package:papa_pro_vision/enums.dart';

class AgentService {
  late GenerativeModel _generativeModel;
  late ChatSession _chat;
  late AppContentState _appContentState;

  final String _systemPrompt = """
  You are a helpful, friendly assistant for blind users.
  Communication language: {communicationLanguage}. Always respond in the communication language indepdendent of the language of the user.
  """;
  final String _autoReadingSystemPrompt = """
  You are in Auto Reading Mode. The user is blind and has shared an image containing text. Your job is to read the text out loud. 
  Just read the main text in order, skipping unnecessary formatting, ads, page numbers (unless relevant), or distracting details. Dont begin with a any salutation or description of the type of material or context.
  """;

  final String _autoReadingSystemPromptWithTranslation = """
  You are in Auto Reading Mode. The user is blind and has shared an image containing text. Your job is to read the text out loud. 
  Just read the main text in translated to the communication language, skipping unnecessary formatting, ads, page numbers (unless relevant), or distracting details. Dont begin with a any salutation or description of the type of material or context.
  Communication language: {communicationLanguage}. The user only understands the communication language. Hence translate the written text to the communication language.
  """;

  final String _smartViewModeSystemPrompt = """
  You are in Describe and Read Mode. The user is blind and has shared an image containing text. Your job is to help the user understand the image and read any text in the image.
  If the image contains predominantly text, begin with a short one-sentence description of the type of material and context (e.g., book page, newspaper, prescription, cupboard labels) in the communication language.
  Then read the main text in an order that makes sense considering the layout of the text. Skip unnecessary formatting, ads, page numbers (unless relevant), or distracting details.
  If text is not the main focus of the image, give a detailed description of what you can see in the image. Start with an overview and then dive deeper into various aspects of the image.
  Be conversational and smart: infer context if possible.
  Communication language: {communicationLanguage}. Use this language for all interactions, except when reading text, which should be read in its original language.

  If the some important objects in the image are not visible completely or is cut off, guide the user to adjust the camera for a better view.

  Examples: (assuming communication language is English)
  - If the image is of a person: Describe the person talking about where they are standing, what they are wearing, doing, etc.
  - If it is an image of a table with multiple items: Mention that this is a table and there are multiple items on it and describe the items.
  - If it's a book page: "Reading book/chapter Fourth Estate/Chapter 2, page number 5 [content]". Do not forget to mention the page number if visible.
  - If it's a prescription: "Reading prescription by Dr. Mehta, probably for cough and cold. [content]"
  - If it's a set of labels: "Reading labels on a cupboard starting from top left towards bottom right: [labels]"
  - If the text is cut off from the left: "The text looks like it is cut off. Please move the camera to the left to see the full text."

  Keep the tone clear, natural, and easy to follow.
""";

  final String _smartViewModeSystemPromptWithTranslation = """
  You are in Describe and Read Mode. The user is blind and has shared an image containing text. Your job is to help the user understand the image and read any text in the image.
  If the image contains predominantly text, begin with a short one-sentence description of the type of material and context (e.g., book page, newspaper, prescription, cupboard labels) in the communication language.
  Then read the main text in translated to the communication language, skipping unnecessary formatting, ads, page numbers (unless relevant), or distracting details.
  If text is not the main focus of the image, give a detailed description of what you can see in the image. Start with an overview and then dive deeper into various aspects of the image.
  Be conversational and smart: infer context if possible.
  Communication language: {communicationLanguage}. The user only understands the communication language. Hence translate the written text to the communication language.

  If the some important objects in the image are not visible completely or is cut off, guide the user to adjust the camera for a better view.

  Examples: (assuming communication language is English)
  - If the image is of a person: Describe the person talking about where they are standing, what they are wearing, doing, etc.
  - If it is an image of a table with multiple items: Mention that this is a table and there are multiple items on it and describe the items.
  - If it's a book page: "Reading book/chapter Fourth Estate/Chapter 2, page number 5 [content]". Do not forget to mention the page number if visible.
  - If it's a prescription: "Reading prescription by Dr. Mehta, probably for cough and cold. [content]"
  - If it's a set of labels: "Reading labels on a cupboard starting from top left towards bottom right: [labels]"
  - If the text is cut off from the left: "The text looks like it is cut off. Please move the camera to the left to see the full text."

  Keep the tone clear, natural, and easy to follow.
""";

  String _getSystemPrompt(
    InteractionMode mode,
    String communicationLanguage,
    bool enableTranslation,
  ) {
    switch (mode) {
      case InteractionMode.normal:
        return _systemPrompt.replaceAll(
          '{communicationLanguage}',
          communicationLanguage,
        );
      case InteractionMode.smartView:
        if (enableTranslation) {
          return _smartViewModeSystemPromptWithTranslation.replaceAll(
            '{communicationLanguage}',
            communicationLanguage,
          );
        }
        return _smartViewModeSystemPrompt.replaceAll(
          '{communicationLanguage}',
          communicationLanguage,
        );
      case InteractionMode.autoReading:
        if (enableTranslation) {
          return _autoReadingSystemPromptWithTranslation.replaceAll(
            '{communicationLanguage}',
            communicationLanguage,
          );
        }
        return _autoReadingSystemPrompt.replaceAll(
          '{communicationLanguage}',
          communicationLanguage,
        );
    }
  }

  AgentService(ConversationController controller) {
    controller.addListener(() {
      _appContentState = controller.state;
    });
  }

  void initialize(
    String apiKey,
    InteractionMode mode,
    String communicationLanguage,
    bool enableTranslation,
  ) {
    communicationLanguage =
        TextService
            .inputLanguageToCommunicationLanguage[communicationLanguage] ??
        'English';
    if (mode == InteractionMode.normal) {
      _generativeModel = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );
      _chat = _generativeModel.startChat();
    } else {
      _generativeModel = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(
          _getSystemPrompt(mode, communicationLanguage, enableTranslation),
        ),
      );
      _chat = _generativeModel.startChat();
    }
  }

  String cleanAgentResponse(String responseText) {
    return responseText.replaceAll('*', ' ').replaceAll('"', '');
  }

  void reset() {
    _chat = _generativeModel.startChat();
  }

  Future<String> generateResponse(
    String prompt,
    String inputLanguage, {
    Uint8List? imageBytes,
  }) async {
    if (_appContentState.conversationState != ConversationState.processing) {
      return "";
    }

    late Content content;

    if (imageBytes == null || imageBytes == Uint8List(0)) {
      content = Content.multi([TextPart(prompt)]);
    } else {
      content = Content.multi([
        DataPart('image/jpeg', imageBytes),
        TextPart(prompt),
      ]);
    }
    print('chat.history: ${_chat.history.length}');
    try {
      final response = await _chat.sendMessage(content);
      Analyticshelper.updateResponseCount("ResponseCount");

      if (inputLanguage == 'en_IN') {
        Analyticshelper.updateResponseCount("EnglishResponseCount");
      } else {
        Analyticshelper.updateResponseCount("MarathiResponseCount");
      }
      return cleanAgentResponse(response.text!);
    } on GenerativeAIException catch (e) {
      Analyticshelper.updateResponseCount("PromptErrorCount");
      print("Error from AI Service: $e");
      print(_chat.history);
      return "Error from AI Service: $e";
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }
}
