import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
import 'package:papa_pro_vision/Helper/AnalyticsHelper.dart';
import 'package:papa_pro_vision/Helper/DeviceHelper.dart';
import 'package:http/http.dart' as http;
import 'package:papa_pro_vision/LLMResponse/system_prompt_enums.dart';
import 'package:papa_pro_vision/StateManagement/button_state_provider.dart';
import 'package:papa_pro_vision/UI/Txt2Speech/service_locator.dart';
import 'package:papa_pro_vision/text_service.dart';
import 'package:papa_pro_vision/enums.dart';

class AgentService {
  late GenerativeModel _generativeModel;
  int streamSessionId = -1;
  late ChatSession _chat;
  late AppContentState _appContentState;
  List<Content> chatHistory = [];

  String _getSystemPrompt(
    InteractionMode mode,
    String communicationLanguage,
    bool enableTranslation,
  ) {
    switch (mode) {
      case InteractionMode.video:
        return SystemPrompts.videoSystemPrompt.replaceAll(
          '{communicationLanguage}',
          communicationLanguage,
        );

      case InteractionMode.normal:
        return SystemPrompts.systemPrompt.replaceAll(
          '{communicationLanguage}',
          communicationLanguage,
        );
      case InteractionMode.smartView:
        if (enableTranslation) {
          return SystemPrompts.smartViewModeSystemPromptWithTranslation
              .replaceAll('{communicationLanguage}', communicationLanguage);
        }
        return SystemPrompts.smartViewModeSystemPrompt.replaceAll(
          '{communicationLanguage}',
          communicationLanguage,
        );
      case InteractionMode.autoReading:
        if (enableTranslation) {
          return SystemPrompts.autoReadingSystemPromptWithTranslation
              .replaceAll('{communicationLanguage}', communicationLanguage);
        }
        return SystemPrompts.autoReadingSystemPrompt.replaceAll(
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
      _chat = _generativeModel.startChat(history: chatHistory);
    } else {
      _generativeModel = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(
          _getSystemPrompt(mode, communicationLanguage, enableTranslation),
        ),
      );
      _chat = _generativeModel.startChat(history: chatHistory);
    }
  }

  void reset() {
    _chat = _generativeModel.startChat();
    chatHistory.clear();
  }

  Future<String> generateResponse(Content content, String inputLanguage) async {
    if (_appContentState.conversationState != ConversationState.processing) {
      return "";
    }
    // Get Response From Gemini
    try {
      final response = await _chat.sendMessage(content);
      Analyticshelper.updateResponseCount("ResponseCount");

      if (inputLanguage == 'en_IN') {
        Analyticshelper.updateResponseCount("EnglishResponseCount");
      } else {
        Analyticshelper.updateResponseCount("MarathiResponseCount");
      }
      return Devicehelper.cleanAgentResponse(response.text!);
    }
    //Error logging
    on GenerativeAIException catch (e) {
      Analyticshelper.updateResponseCount("PromptErrorCount");
      print("Error from AI Service: $e");
      return "Error from AI Service: $e";
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  Future<String> getResponseFromRender(String query) async {
    String encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
      'https://vercelgooglesearch.onrender.com/search/$encodedQuery',
    );

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['response'];
    } else {
      throw Exception('Failed to search: ${response.statusCode}');
    }
  }

  int chatHistoryCount() {
    print("Insideeee chat history length: ${_chat.history.length}");

    return _chat.history.length;
  }

  Future<String> sendGoogleSearchMessage(
    String inputText,
    String inputLanguage,
  ) async {
    if (_appContentState.conversationState != ConversationState.processing) {
      return "";
    }
    // Get Response From Render
    try {
      final response = await getResponseFromRender(inputText);
      Analyticshelper.updateResponseCount("ResponseCount");

      if (inputLanguage == 'en_IN') {
        Analyticshelper.updateResponseCount("EnglishResponseCount");
      } else {
        Analyticshelper.updateResponseCount("MarathiResponseCount");
      }
      return Devicehelper.cleanAgentResponse(response);
    }
    //Error logging
    on GenerativeAIException catch (e) {
      Analyticshelper.updateResponseCount("PromptErrorCount");
      print("Error from AI Service: $e");
      return "Error from AI Service: $e";
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  Future<Content> CreateContentForResponse(
    String prompt,
    String inputLanguage, {
    Uint8List? imageBytes,
    File? videoFile,
  }) async {
    late Content content;

    // Content Creation
    //Video content
    try {
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

      return content;
    } catch (e) {
      print("Error in CreateContentForResponse: $e");
      return Content.text("Error in CreateContentForResponse: $e");
    } finally {
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

  void stopStream(
    String apiKey,
    InteractionMode mode,
    String communicationLanguage,
    bool enableTranslation,
  ) {
    streamSessionId = -1;
    chatHistory.add(Content.model([TextPart(_appContentState.agentResponse)]));
    initialize(apiKey, mode, communicationLanguage, enableTranslation);
    print('Stream stopped');
  }

  // Method 1: Using sendMessageStream for continuous streaming
  Future<void> sendStreamingMessage(
    Content content,
    TextToSpeechService? ttsService,
    Function onStartSpeaking,
  ) async {
    try {
      var isInternetAvailable =
          await Devicehelper.hasInternetConnectionAndNotify(
            methodCallName: 'speakGoogleTTS',
          );
      if (!isInternetAvailable) {
        print("No internet connection. Cannot perform TTS.");
        return;
      }

      // Get the stream of responses
      final Stream<GenerateContentResponse> stream = _chat.sendMessageStream(
        content,
      );
      chatHistory = _chat.history.toList();

      streamSessionId = await ttsService?.startSession() ?? 0;

      // Local buffering variables captured by the listener closure.
      String currentText = '';
      int wordCount = 0;
      int chunkCount = 0;
      int speakCount = 0;

      // Iterate over the stream using await for so we can manage control flow directly.
      await for (final chunk in stream) {
        chunkCount++;
        if (streamSessionId == -1) {
          print('[STREAM] Stop requested – breaking loop at chunk $chunkCount');
          break; // Exit loop; any remaining chunks will be dropped.
        }

        final text = chunk.text;
        print(
          '[][][][][STREAM CHUNK $chunkCount] textLength=${text?.length ?? 0}',
        );
        if (text == null || text.isEmpty) {
          continue; // Still counted, but nothing to process.
        }

        _appContentState.agentResponse += text;

        for (int i = 0; i < text.length; i++) {
          final char = text[i];
          currentText += char;
          if (char == ' ') wordCount++;

          final hitSentenceEnd =
              char == '.'; // Extend with other punctuation if desired.
          final hitWordLimit = wordCount >= 50;

          if (hitSentenceEnd || hitWordLimit) {
            speakCount++;
            final speakText = Devicehelper.cleanAgentResponse(
              currentText,
            ).trim();
            if (speakText.isNotEmpty) {
              onStartSpeaking();
              print(
                '[][][][][TTS START #$speakCount] fromChunk=$chunkCount words=$wordCount len=${speakText.length}',
              );
              // Await so playback order matches text order.
              await ttsService?.speak(speakText, sessionId: streamSessionId);
            } else {
              print('[TTS SKIP] Empty after cleaning');
            }
            currentText = '';
            wordCount = 0;
          }
        }
      }

      // Flush remainder after stream ends or stop requested.
      if (currentText.trim().isNotEmpty && streamSessionId != -1) {
        speakCount++;
        final speakText = Devicehelper.cleanAgentResponse(currentText).trim();
        if (speakText.isNotEmpty) {
          print('[TTS FINAL START #$speakCount] textLength=${speakText.length}');
          await ttsService?.speak(speakText, sessionId: streamSessionId);
          print('[TTS FINAL DONE #$speakCount]');
        }
      }
      print('[STREAM DONE] chunks=$chunkCount spoken=$speakCount');
    } catch (e) {
      print('Error in streaming: $e');
    }
  }
}
