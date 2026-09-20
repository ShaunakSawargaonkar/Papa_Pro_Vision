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
import 'package:papa_pro_vision/Txt2Speech/service_locator.dart';
import 'package:papa_pro_vision/text_service.dart';
import 'package:papa_pro_vision/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AgentService {
  late GenerativeModel _generativeModel;
  late ChatSession _chat;
  late AppContentState _appContentState;
  final ConversationController _controller;
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

  AgentService(ConversationController controller) : _controller = controller {
    _appContentState = controller.state;
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
        model: 'gemini-3.5-flash-lite',
        apiKey: apiKey,
      );
      _chat = _generativeModel.startChat(history: chatHistory);
    } else {
      _generativeModel = GenerativeModel(
        model: 'gemini-3.5-flash-lite',
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

Future<String> getResponseFromRender(String query, {String? userId}) async {
  final url = Uri.parse(
    'https://googlesearchmultipleuserworking.onrender.com/search',
  );

  final body = json.encode({
    'query': query,
    if (userId != null) 'user_id': userId,
  });

  print("Search POST -> $url  body: $body");

  Future<http.Response> send() => http
      .post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      )
      .timeout(const Duration(seconds: 90)); // Render free-tier cold start

  http.Response response;
  try {
    response = await send();
  } on TimeoutException {
    // one retry — first request often wakes a sleeping Render instance
    response = await send();
  }

  if (response.statusCode == 200) {
    return json.decode(response.body)['response'] as String;
  }

  // Surface the server's friendly message (e.g. "Please say what you'd like to search for.")
  String detail;
  try {
    detail = json.decode(response.body)['detail']?.toString() ?? response.body;
  } catch (_) {
    detail = response.body;
  }
  throw Exception('Failed to search (${response.statusCode}): $detail');
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
      final prefs = await SharedPreferences.getInstance();
      final contactNumber = prefs.getString('contactNumber');
      final response = await getResponseFromRender(
        inputText,
        userId: contactNumber,
      );
      Analyticshelper.updateResponseCount("ResponseCount", _appContentState.userUID);

      if (inputLanguage == 'en_IN') {
        Analyticshelper.updateResponseCount("EnglishResponseCount", _appContentState.userUID);
      } else {
        Analyticshelper.updateResponseCount("MarathiResponseCount", _appContentState.userUID);
      }
      return Devicehelper.cleanAgentResponse(response);
    }
    //Error logging
    on GenerativeAIException catch (e) {
      Analyticshelper.updateResponseCount("PromptErrorCount", _appContentState.userUID);
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
        print("Inside video setting content ${videoFile.path}");
        final videoBytes = await videoFile.readAsBytes();
        content = Content.multi([
          DataPart('video/mp4', videoBytes),
          TextPart(prompt),
        ]);
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
    // History belongs to ChatSession, which records a turn itself once the
    // request completes. Appending here pushed an unpaired — and on an early
    // cancel, empty — model turn into the history that initialize() seeds the
    // next chat with, which Gemini then rejects or answers incoherently from.
    chatHistory = _chat.history.toList();
    initialize(apiKey, mode, communicationLanguage, enableTranslation);
    print('Stream stopped');
  }

  // Method 1: Using sendMessageStream for continuous streaming
  Future<void> sendStreamingMessage(
    Content content,
    TextToSpeechService? ttsService,
    Function onStartSpeaking, {
    required int token,
    String inputLanguage = 'en_IN',
  }) async {
    try {
      var isInternetAvailable =
          await Devicehelper.hasInternetConnectionAndNotify(
            methodCallName: 'speakGoogleTTS',
          );
      if (!isInternetAvailable) {
        print("No internet connection. Cannot perform TTS.");
        return;
      }
      if (!_controller.isCurrentInteraction(token)) {
        print('[STREAM] Interaction $token superseded before start');
        return;
      }

      // Get the stream of responses
      final Stream<GenerateContentResponse> stream = _chat.sendMessageStream(
        content,
      );

      await ttsService?.startSession(token);

      Analyticshelper.updateResponseCount("ResponseCount", _appContentState.userUID);

      if (inputLanguage == 'en_IN') {
        Analyticshelper.updateResponseCount("EnglishResponseCount", _appContentState.userUID);
      } else {
        Analyticshelper.updateResponseCount("MarathiResponseCount", _appContentState.userUID);
      }
      // Local buffering variables captured by the listener closure.
      String currentText = '';
      int wordCount = 0;
      int chunkCount = 0;
      int speakCount = 0;

      // Iterate over the stream using await for so we can manage control flow directly.
      await for (final chunk in stream) {
        chunkCount++;
        if (!_controller.isCurrentInteraction(token)) {
          print('[STREAM] Superseded – breaking loop at chunk $chunkCount');
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
          final previousChar = i > 0 ? text[i - 1] : '';
          final nextChar = i < text.length - 1 ? text[i + 1] : '';
          currentText += char;
          if (char == ' ') wordCount++;

          final is_prev_last_number = int.tryParse(previousChar) != null && int.tryParse(nextChar) != null;
          final hitSentenceEnd =
              char == '.' && !is_prev_last_number; // Extend with other punctuation if desired.
          
          final hitWordLimit = wordCount >= 100;

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
              await ttsService?.speak(speakText, sessionId: token);
            } else {
              print('[TTS SKIP] Empty after cleaning');
            }
            currentText = '';
            wordCount = 0;
          }
        }
      }

      final stillCurrent = _controller.isCurrentInteraction(token);

      // Flush remainder after stream ends or stop requested.
      if (currentText.trim().isNotEmpty && stillCurrent) {
        speakCount++;
        final speakText = Devicehelper.cleanAgentResponse(currentText).trim();
        if (speakText.isNotEmpty) {
          // Same as the in-loop path: flip processing -> speaking BEFORE
          // speak(), otherwise speak()'s guard (conversationState != speaking)
          // silently drops audio for responses that had no mid-stream sentence
          // break and only reach this flush branch.
          onStartSpeaking();
          print(
            '[TTS FINAL START #$speakCount] textLength=${speakText.length}',
          );
          await ttsService?.speak(speakText, sessionId: token);
          print('[TTS FINAL DONE #$speakCount]');
        }
      }
      if (stillCurrent) {
        chatHistory = _chat.history.toList();
        // Tells the player that a drained queue now genuinely means "finished",
        // which is what eventually fires doneSpeaking().
        await ttsService?.endSession(token);
      }
      print('[STREAM DONE] chunks=$chunkCount spoken=$speakCount');
    } catch (e) {
      print('Error in streaming: $e');
    }
  }
}
