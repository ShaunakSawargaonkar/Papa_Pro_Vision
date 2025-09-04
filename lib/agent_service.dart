import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:papa_pro_vision/AnalyticsHelper.dart';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum InteractionMode { normal, smartReading, autoReading }

class AgentService {
  late GenerativeModel _generativeModel;
  late ChatSession _chat;
  final _generationConfig = GenerationConfig(temperature: 0);
  late AppContentState _appContentState;

  final String _systemPrompt = """
  You are a helpful, friendly assistant for blind users. Always respond in a warm and conversational tone, using simple and concise language.
  Keep answers clear, and easy to follow—like speaking to a friend.
  Never be robotic—be natural, engaging, and supportive.
  """;
  final String _autoReadingSystemPrompt = """
  You are in Auto Reading Mode. The user is blind and has shared an image containing text. Your job is to read the text out loud in a natural, friendly, and helpful way. 
  Dont begin with a description of the type of material or context. Just read the main text in order, skipping unnecessary formatting, ads, page numbers (unless relevant), or distracting details.
  """;

  final String _readingModeSystemPrompt = """
  You are in Reading Mode. The user is blind and has shared an image containing text. Your job is to read the text out loud in a natural, friendly, and helpful way.
  Begin with a short one-sentence description of the type of material and context (e.g., book page, newspaper, prescription, cupboard labels).
  Do not describe every small visual detail—focus only on what helps the user understand what they are reading.
  Read the main text in order, skipping unnecessary formatting, ads, page numbers (unless relevant), or distracting details.
  Be conversational and smart: infer context if possible.
  If the page is not visible completely or is cut off, guide the user to adjust the camera for a better view.

  Examples:
  - If it's a book page: "Reading book/chapter Fourth Estate/Chapter 2, page number 5 [content]". Do not forget to mention the page number if visible.
  - If it's a newspaper: "Reading newspaper dated July 20, 2023, section Sports. [content]"
  - If it's a prescription: "Reading prescription by Dr. Mehta, probably for cough and cold. [content]"
  - If it's a set of labels: "Reading labels on a cupboard starting from top left towards bottom right: [labels]"
  - If the text is cut off from the left: "The text looks like it is cut off. Please move the camera to the left to see the full text."

  Keep the tone clear, natural, and easy to follow, like a friend reading aloud.
""";

  String _getSystemPrompt(InteractionMode mode) {
    switch (mode) {
      case InteractionMode.normal:
        return _systemPrompt;
      case InteractionMode.smartReading:
        return _readingModeSystemPrompt;
      case InteractionMode.autoReading:
        return _autoReadingSystemPrompt;
    }
  }

  AgentService(ConversationController controller) {
    controller.addListener(() {
      _appContentState = controller.state;
    });
  }

  void initialize(String apiKey, InteractionMode mode) {
    _generativeModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: _generationConfig,
      systemInstruction: Content.system(_getSystemPrompt(mode)),
    );
    _chat = _generativeModel.startChat();
  }

  bool checkIfIgnoreImage(String promptText) {
    promptText.toLowerCase();
    if (promptText.contains("ignore the image")) {
      return true; // Placeholder logic, replace with actual condition
    }
    return false; // Placeholder, replace with actual logic
  }

  String cleanAgentResponse(String responseText) {
    return responseText.replaceAll('*', ' ');
  }

  void reset() {
    _chat = _generativeModel.startChat();
  }

  Future<String> generateResponse(
    String prompt, {
    Uint8List? imageBytes,
  }) async {
    if (_appContentState.conversationState != ConversationState.processing)
      return "";

    late Content content;

    if (checkIfIgnoreImage(prompt) || imageBytes == null) {
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
      await updateResponseCount();
      return cleanAgentResponse(response.text!);
    } on GenerativeAIException catch (e) {
      await Analyticshelper.updateResponseCount("PromptErrorCount");
      print("Error from AI Service: $e");
      print(_chat.history);
      return "Error from AI Service: $e";
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  Future<void> updateResponseCount() async {
    var deviceId = await _getDeviceId();
    var temp = await FirebaseFirestore.instance
        .collection('Users')
        .where('deviceId', isEqualTo: deviceId)
        .get();

    var temp2 = temp.docs[0].data();

    for (var doc in temp.docs) {
      await doc.reference.update({
        'Analytics.ResponseCount': FieldValue.increment(1),
      });
    }
  }

  Future<String> _getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id;
  }
}
