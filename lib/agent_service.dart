import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';


enum Mode{
  normal,
  reading
}


class AgentService{
  late GenerativeModel _generativeModel;
  late ChatSession _chat;
  final _generationConfig = GenerationConfig(temperature: 0);
  late AppContentState _appContentState;

  final String _systemPrompt = """
  You are a helpful, friendly assistant for blind users. Always respond in a warm and conversational tone, using simple and concise language.
  Keep answers short, clear, and easy to follow—like speaking to a friend.
  Avoid long lists or unnecessary details. Never be robotic—be natural, engaging, and supportive.
  """;

  final String _readingModeSystemPrompt = """
  You are in Reading Mode. The user is blind and has shared an image containing text. Your job is to read the text out loud in a natural, friendly, and helpful way.
  Begin with a short one-sentence description of the type of material and context (e.g., book page, newspaper, prescription, cupboard labels).
  Do not describe every small visual detail—focus only on what helps the user understand what they are reading.
  Read the main text in order, skipping unnecessary formatting, ads, page numbers (unless relevant), or distracting details.
  Be smart: infer context if possible.

  Examples:
  - If it's a book page: "Reading page number 5. [content]"
  - If it's a newspaper: "Reading newspaper dated July 20, 2023, section Sports. [content]"
  - If it's a prescription: "Reading prescription by Dr. Mehta, probably for cough and cold. [content]"
  - If it's a set of labels: "Reading labels on a cupboard starting from top left towards bottom right: [labels]"

  Keep the tone clear, natural, and easy to follow, like a friend reading aloud.
""";

  String _getSystemPrompt(Mode mode){
    return mode == Mode.reading ? _readingModeSystemPrompt : _systemPrompt;
  }

  AgentService(ConversationController controller){
    controller.addListener(() {
      _appContentState = controller.state;
    });
  }

  void initialize(String apiKey, Mode mode){
    _generativeModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: _generationConfig,
      systemInstruction: Content.system(_getSystemPrompt(mode))
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

  void reset(){
    _chat = _generativeModel.startChat();
  }

  Future<String> generateResponse(String prompt, Uint8List imageBytes) async {
    if(_appContentState.conversationState != ConversationState.processing) return "";

    late Content content;
    
    if(checkIfIgnoreImage(prompt)){
      content = Content.multi([TextPart(prompt)]);
    }else{
      content = Content.multi([DataPart('image/jpeg', imageBytes), TextPart(prompt)]);
    }
    try{
      final response = await _chat.sendMessage(content);
      return cleanAgentResponse(response.text!);
    }on GenerativeAIException catch (e){
      return "Error from AI Service: $e";
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

}