import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:papa_pro_vision/LLMResponse/system_prompt_enums.dart';
import 'package:papa_pro_vision/secrets.dart';
import 'dart:convert';

class ImageCorrectionResponse {
  final String? response;
  final bool isImageCorrect;
  final bool? recaptureRequired;

  ImageCorrectionResponse({
    this.response,
    required this.isImageCorrect,
    this.recaptureRequired = false,
  });
}

class ImageCorrectionService {
  late GenerativeModel _generativeModel;
  late ChatSession _chat;

  static const String defaultImageCorrectionResponse = 'recapture the image.';

  ImageCorrectionService() {
    initializeModel();
    _chat = _generativeModel.startChat();
  }

  void initializeModel() {
    _generativeModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: Secrets.geminiApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema(
          SchemaType.object,
          description: 'The response schema for the image correction service',
          properties: {
            'reason': Schema(
              SchemaType.string,
              description:
                  'Explain briefly why the user query is not answerable or the answer is improvable given the image.',
            ),
            'part_of_query_answer_improvable': Schema(
              SchemaType.string,
              description:
                  'Quoting the exact part from the user query whose answer is improvable given the image.',
              nullable: true,
            ),
            'part_of_query_parially_unanswerable': Schema(
              SchemaType.string,
              description:
                  'Quoting the exact part from the user query that is not answerable or partially answerable given the image.',
              nullable: true,
            ),
            'movement': Schema(
              SchemaType.string,
              description:
                  'Concrete instructions (e.g., “move camera left”, “raise phone”, “move closer”, etc.) to take a better photo.',
              nullable: true,
            ),
          },
        ),
      ),
    );
  }

  void resetChat() {
    _chat = _generativeModel.startChat();
  }

  String getPrompt(String userQuery) {
    return SystemPrompts.detectIfImageIsCorrectSystemPrompt.replaceAll(
      '{user_query}',
      userQuery,
    );
  }

  Future<ImageCorrectionResponse> checkIfImageIsCorrect(
    String userQuery,
    Uint8List? imageBytes,
  ) async {
    if (imageBytes == null || imageBytes.isEmpty) {
      return ImageCorrectionResponse(isImageCorrect: true);
    }
    resetChat();
    String prompt = getPrompt(userQuery);
    Content content = Content.multi([
      DataPart('image/jpeg', imageBytes),
      TextPart(prompt),
    ]);
    final response = await _chat.sendMessage(content);
    print("IMAGE CORRECTION: Response: ${response.text}");
    try {
      Map<String, dynamic> jsonResponse = jsonDecode(response.text!);
      if (jsonResponse['part_of_query_parially_unanswerable'] != null) {
        String movement =
            jsonResponse['movement'] ?? defaultImageCorrectionResponse;
        movement = movement.toLowerCase();
        return ImageCorrectionResponse(
          response:
              'Your request is not completely answerable given the image. Please ${movement}',
          isImageCorrect: false,
          recaptureRequired: true,
        );
      } else if (jsonResponse['part_of_query_answer_improvable'] != null) {
        String movement =
            jsonResponse['movement'] ?? defaultImageCorrectionResponse;
        movement = movement.toLowerCase();
        return ImageCorrectionResponse(
          response:
              'If you want an improved answer to your query, Please ${movement}',
          isImageCorrect: false,
        );
      } else {
        return ImageCorrectionResponse(isImageCorrect: true);
      }
    } catch (e) {
      print("IMAGE CORRECTION: Error converting response to json: $e");
      return ImageCorrectionResponse(isImageCorrect: true);
    }
  }
}
