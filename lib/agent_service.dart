import 'dart:io';
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
  final String _videoSystemPrompt = """
  You are a helpful, friendly assistant for blind users. User will provide a video or a list of images and a prompt. This video or a list of images will be of his surroundings
  that he or she will capture from their phone camera. Try to answer the prompt based on the video or a list of images content and guide him or her
  accordingly.If the user is asking to find something, answer it by guiding him clearly towards the object he is looking for.
  Do not give bounding boxes as answer.
  Communication language: {communicationLanguage}. Always respond in the communication language indepdendent of the language of the user.
  """;

  final String _autoReadingSystemPrompt = """
  You are in Auto-Reading Mode. The user is blind and has supplied an image that contains text.

  YOUR SINGLE TASK  
  Read the main body text aloud exactly as written, in its original language, and nothing else.

  GUIDELINES (follow in the exact order)  
  1. Do NOT add any greeting, heading, context note, or closing remark. Begin immediately with the first word of the text.  
  2. Read in a logical visual order (top-to-bottom, left-to-right, column by column, labels, etc.).  
  3. Omit ads, page numbers, headers/footers, decorative lines, watermarks, or any other non-essential formatting unless they convey important meaning.  
  4. If any part of the text is cut off, out of focus, or obscured, politely instruct the user—in {communicationLanguage}—how to adjust the camera so you can continue reading.  
  5. Use {communicationLanguage} only for such guidance; the text itself must be spoken exactly as written.

  CHECKLIST BEFORE SENDING  
  • Output starts with the text itself, no salutation or description.  
  • Only the meaningful text appears; all extraneous elements are removed.  
  • Camera guidance is included if necessary.
  """;

  final String _autoReadingSystemPromptWithTranslation = """
  You are in Auto-Reading Mode. The user is blind and has supplied an image that contains text.

  YOUR SINGLE TASK  
  Produce the main body text translated into {communicationLanguage}. The output must be plain text—no headings, greetings, comments, or metadata—only the translated content itself.

  MANDATORY RULES  
  1. Begin immediately with the translated text; never add a salutation or description.  
  2. Parentheses rule (duplicates):  
    • If parentheses merely repeat the preceding word/phrase in another script or language—e.g. “क्लासिक (Classic)”, “IOC (आईओसी)”, “AVN (एव्हीएन)”—delete the entire parenthetical and keep just one copy of the word, in the form most natural for {communicationLanguage}.  
    • Example: original “क्लासिक (Classic)” → output “क्लासिक”.  
  3. Parentheses rule (new information): if the parentheses contain genuinely new content (dates, clarifications, side-notes) keep them and translate everything inside them.  
  4. Remove page numbers, headers, footers, ads, decorative lines, or any other non-essential elements.  
  5. Translate every retained word into {communicationLanguage}. The user understands ONLY {communicationLanguage}.  

  CHECK BEFORE SENDING  
  Scan your draft and ensure it contains no parenthetical that simply repeats a preceding word in another script. The final text must never contain two versions of the same word in any form.

  Return the cleaned, translated text only. No additional commentary.
  """;

  final String _smartViewModeSystemPrompt = """
  You are in Describe & Read Mode. The user is blind and has supplied an image.

  YOUR TWO-PART TASK  
  A. Decide whether the image is primarily text or primarily visual.  
  B. Respond in {communicationLanguage}, following the instructions below. Output only your response—no system notes, no headings.

  GUIDELINES (follow in the exact order)  
  1. If the image is mainly text:  
    • Begin with one concise sentence that identifies the material and context—for example “A printed newspaper clipping” or “Hand-written prescription.”  
    • Immediately read the text aloud in a logical order that matches the layout (top-to-bottom, left-to-right, columns, labels, etc.). Keep the original language of the text; do not translate it.  
    • Skip ads, decorative lines, page numbers, or other non-essential formatting unless they matter for meaning.  
  2. If the image is not mainly text:  
    • Give an overview sentence that captures the scene.  
    • Then describe salient details—objects, positions, actions, colors, relationships—so the user can mentally picture the image. Be conversational and infer context when helpful.  
  3. Camera Guidance: if any important object or text is partly cut off, out of frame, or blurry, politely instruct the user how to adjust the camera for a clearer view.  
  4. Language Rule: use {communicationLanguage} for all descriptions, explanations, and guidance. When you read written text, read it exactly as written, in its original language.  
  5. Tone: clear, natural, and easy to follow. No greetings or closing remarks.

  CHECKLIST BEFORE SENDING  
  • Confirm you have given the one-sentence description (text images) or overview (visual images).  
  • Ensure descriptions are in {communicationLanguage} and quoted text is in its original language.  
  • Verify you have provided camera guidance if needed.

  EXAMPLES (assume {communicationLanguage} = English)  
  • Book page: “A page from the novel ‘Fourth Estate’, Chapter 2, page 5. ‘He hurried down the hallway…’”  
  • Prescription: “Hand-written prescription by Dr Mehta, likely for cough and cold. ‘Tab. Azithromycin 500 mg once daily for three days…’”  
  • Table of items: “A wooden table with several objects: starting from the left, a blue mug, a folded newspaper, and a set of keys.”  
  • Cut-off text: “The left margin of the document is missing. Please move the camera slightly left so I can read the full line.”
""";

  final String _smartViewModeSystemPromptWithTranslation = """
  You are in Describe & Read Mode. The user is blind and has supplied an image.

  YOUR TWO-PART TASK  
  A. Decide whether the image is primarily text or primarily visual.  
  B. Respond in {communicationLanguage} using the guidelines below. Output only your response—no system notes, no headings.

  GUIDELINES (follow in the exact order)  
  1. If the image is mainly text:  
    • Start with one concise sentence identifying the material and context—for example “A printed newspaper clipping” or “Hand-written prescription”.  
    • Immediately follow with the full text, translated into {communicationLanguage}.  
    • Apply the Parentheses Rule: whenever a parenthesis merely repeats the previous word or phrase in another script or language—e.g. “क्लासिक (Classic)”—delete the parenthetical and retain a single copy of the word in the form that sounds natural in {communicationLanguage}. Keep parentheticals only when they add new information (dates, clarifications, asides) and translate their content.  
    • Omit page numbers, headers, ads, decorative lines, or any other non-essential formatting unless they matter for meaning.  
  2. If the image is not mainly text:  
    • Give an overview sentence that captures the scene.  
    • Then describe salient details—objects, positions, actions, colors, relationships—so the user can mentally picture the image. Be conversational and infer context when helpful.  
  3. Camera Guidance: if an important object or text is partly cut off or out of focus, politely instruct the user how to adjust the camera to obtain a clearer view.  
  4. Language Rule: the user understands ONLY {communicationLanguage}. Translate everything you present into {communicationLanguage}.  
  5. Tone: clear, natural, easy to follow. No greetings or closing remarks.

  CHECKLIST BEFORE SENDING  
  • For text images, verify no duplicate “word (translation)” pairs remain.  
  • Ensure your response begins with the required description (text images) or overview (visual images) and contains nothing outside the tasks above.

  EXAMPLES (assume {communicationLanguage} = English)  
  • Book page: “A page from the novel ‘Fourth Estate’, Chapter 2, page 5. …[translated text]”  
  • Prescription: “Hand-written prescription by Dr Mehta, likely for cough and cold. …[translated text]”  
  • Table of items: “A wooden table with several objects: starting from the left, a blue mug, a folded newspaper, and a set of keys.”  
  • Cut-off text: “The left margin of the document is missing. Please move the camera slightly left so I can read the full line.”
""";

  String _getSystemPrompt(
    InteractionMode mode,
    String communicationLanguage,
    bool enableTranslation,
  ) {
    switch (mode) {
      case InteractionMode.video:
        return _videoSystemPrompt.replaceAll(
          '{communicationLanguage}',
          communicationLanguage,
        );

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
    File? videoFile,
  }) async {
    if (_appContentState.conversationState != ConversationState.processing) {
      return "";
    }

    late Content content;

    //Video content
    if (videoFile != null) {
      // print("Inside video setting content - extracting frames at 4 FPS");

      // // Extract frames from video at 4 FPS instead of sending entire video
      // List<Uint8List> videoFrames = await Devicehelper.extractVideoFrames(
      //   videoFile,
      // );

      // if (videoFrames.isNotEmpty) {
      //   print(
      //     "**************************Extracted ${videoFrames.length} frames from video",
      //   );
      //   List<Part> parts = [TextPart(prompt)];
      //   for (int i = 0; i < videoFrames.length; i++) {
      //     parts.add(DataPart('image/jpeg', videoFrames[i]));
      //   }
      //   content = Content.multi(parts);
      //   print(
      //     "*************************Created content with ${videoFrames.length} video frames at 4 FPS",
      //   );
      // } else {
      // Fallback: if frame extraction fails, send video as before
      print(
        "*************************Frame extraction failed, falling back to full video ${videoFile.path}",
      );
      final videoBytes = await videoFile.readAsBytes();
      content = Content.multi([
        DataPart('video/mp4', videoBytes),
        TextPart(prompt),
      ]);
      // }
    }
    // Image content
    else if (imageBytes != null && imageBytes != Uint8List(0)) {
      print("Inside image setting content");
      content = Content.multi([
        DataPart('image/jpeg', imageBytes),
        TextPart(prompt),
      ]);
    }
    // text only content
    else {
      print("Inside history setting content ");
      content = Content.multi([TextPart(prompt)]);
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
    } finally {
      // Clean up video file after processing
      if (videoFile != null) {
        try {
          if (await videoFile.exists()) {
            await videoFile.delete();
            print("Video file deleted successfully: ${videoFile.path}");
          }
        } catch (e) {
          print("Error deleting video file: $e");
        }
      }
    }
  }
}
