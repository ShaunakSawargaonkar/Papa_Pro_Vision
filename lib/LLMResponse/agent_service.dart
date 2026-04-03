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
  int streamSessionId = -1;
  late ChatSession _chat;
  late AppContentState _appContentState;
  List<Content> chatHistory = [];
  StreamSubscription<void>? _streamSubscription;
  bool _isStopping = false; // guard against double stopStream calls

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
      Analyticshelper.updateResponseCount(
        "ResponseCount",
        _appContentState.userUID,
      );

      if (inputLanguage == 'en_IN') {
        Analyticshelper.updateResponseCount(
          "EnglishResponseCount",
          _appContentState.userUID,
        );
      } else {
        Analyticshelper.updateResponseCount(
          "MarathiResponseCount",
          _appContentState.userUID,
        );
      }
      return Devicehelper.cleanAgentResponse(response.text!);
    }
    //Error logging
    on GenerativeAIException catch (e) {
      Analyticshelper.updateResponseCount(
        "PromptErrorCount",
        _appContentState.userUID,
      );
      print("Error from AI Service: $e");
      return "Error from AI Service: $e";
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  Future<String> getResponseFromRender(String query, {String? userId}) async {
    String encodedQuery = Uri.encodeComponent(query);
    print("Encoded Query: $encodedQuery");

    String urlString =
        'https://vercelgooglesearch.onrender.com/search/$encodedQuery';

    // Add user_id parameter if provided
    if (userId != null) {
      urlString += '?user_id=${Uri.encodeComponent(userId)}';
    }

    final url = Uri.parse(urlString);

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
  // Future<String> getResponseFromRender(String query) async {
  //   String encodedQuery = Uri.encodeComponent(query);
  //   print("Encoded Query: $encodedQuery");

  //   final url = Uri.parse(
  //     'https://vercelgooglesearch.onrender.com/search/$encodedQuery',
  //   );

  //   final response = await http.get(
  //     url,
  //     headers: {'Content-Type': 'application/json'},
  //   );

  //   if (response.statusCode == 200) {
  //     return json.decode(response.body)['response'];
  //   } else {
  //     throw Exception('Failed to search: ${response.statusCode}');
  //   }
  // }

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
      Analyticshelper.updateResponseCount(
        "ResponseCount",
        _appContentState.userUID,
      );

      if (inputLanguage == 'en_IN') {
        Analyticshelper.updateResponseCount(
          "EnglishResponseCount",
          _appContentState.userUID,
        );
      } else {
        Analyticshelper.updateResponseCount(
          "MarathiResponseCount",
          _appContentState.userUID,
        );
      }
      return Devicehelper.cleanAgentResponse(response);
    }
    //Error logging
    on GenerativeAIException catch (e) {
      Analyticshelper.updateResponseCount(
        "PromptErrorCount",
        _appContentState.userUID,
      );
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

  Future<void> stopStream(
    String apiKey,
    InteractionMode mode,
    String communicationLanguage,
    bool enableTranslation,
  ) async {
    if (_isStopping) return; // already stopping — skip duplicate call
    _isStopping = true;
    try {
      final previousSessionId = streamSessionId;
      streamSessionId = -1;
      // Only add to chat history if there's an active response and we haven't already saved it
      if (previousSessionId != -1 && _appContentState.agentResponse.isNotEmpty) {
        chatHistory.add(Content.model([TextPart(_appContentState.agentResponse)]));
      }
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      initialize(apiKey, mode, communicationLanguage, enableTranslation);
      print('Stream stopped');
    } finally {
      _isStopping = false;
    }
  }

  // Method 1: Using sendMessageStream for continuous streaming
  Future<void> sendStreamingMessage(
    Content content,
    TextToSpeechService? ttsService,
    Function onStartSpeaking, {
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

      // Get the stream of responses
      final Stream<GenerateContentResponse> stream = _chat.sendMessageStream(
        content,
      );
      chatHistory = _chat.history.toList();

      final int localSessionId = await ttsService?.startSession() ?? 0;
      streamSessionId = localSessionId;

      Analyticshelper.updateResponseCount(
        "ResponseCount",
        _appContentState.userUID,
      );

      if (inputLanguage == 'en_IN') {
        Analyticshelper.updateResponseCount(
          "EnglishResponseCount",
          _appContentState.userUID,
        );
      } else {
        Analyticshelper.updateResponseCount(
          "MarathiResponseCount",
          _appContentState.userUID,
        );
      }

      String currentText = '';
      int wordCount = 0;
      int chunkCount = 0;
      int speakCount = 0;

      _streamSubscription = stream
          .asyncMap((chunk) async {
            chunkCount++;

            // 🔴 Stop requested
            if (streamSessionId != localSessionId) {
              print(
                '[STREAM] Stop requested – breaking loop at chunk $chunkCount',
              );
              await _streamSubscription?.cancel();
              return;
            }

            final text = chunk.text;

            print(
              '[][][][][STREAM CHUNK $chunkCount] textLength=${text?.length ?? 0} text=$text',
            );

            if (text == null || text.isEmpty) {
              return;
            }

            // Guard: only accumulate response if this session is still active
            if (streamSessionId != localSessionId) {
              print('[STREAM] Session invalidated — discarding chunk');
              await _streamSubscription?.cancel();
              return;
            }

            _appContentState.agentResponse += text;

            for (int i = 0; i < text.length; i++) {
              final char = text[i];
              currentText += char;

              if (char == ' ') wordCount++;

              final hitSentenceEnd = char == '.';
              final hitWordLimit = wordCount >= 100;

              if (hitSentenceEnd || hitWordLimit) {
                speakCount++;

                final speakText = Devicehelper.cleanAgentResponse(
                  currentText,
                ).trim();

                currentText = '';
                wordCount = 0;

                if (speakText.isNotEmpty) {
                  // 🔴 Double-check before speaking
                  if (streamSessionId != localSessionId) {
                    print(
                      '[STREAM] Stop detected before TTS at speakCount=$speakCount',
                    );
                    await _streamSubscription?.cancel();
                    return;
                  }

                  onStartSpeaking();

                  print(
                    '[][][][][TTS START #$speakCount] fromChunk=$chunkCount words=$wordCount len=${speakText.length} speakText=$speakText',
                  );

                  await ttsService?.speak(speakText, sessionId: localSessionId);
                } else {
                  print('[TTS SKIP] Empty after cleaning');
                }
              }
            }
          })
          .listen(
            (_) {},
            onDone: () async {
              print(
                '[STREAM DONE] chunkCount=$chunkCount speakCount=$speakCount',
              );

              if (streamSessionId != localSessionId) {
                print('[STREAM DONE] Ignored due to session mismatch');
                return;
              }

              if (currentText.trim().isNotEmpty) {
                speakCount++;

                final speakText = Devicehelper.cleanAgentResponse(
                  currentText,
                ).trim();

                if (speakText.isNotEmpty) {
                  print(
                    '[TTS FINAL START #$speakCount] textLength=${speakText.length}',
                  );

                  await ttsService?.speak(speakText, sessionId: localSessionId);
                }
              }
            },
            onError: (error) {
              print('Error in streaming: $error');
            },
            cancelOnError: true,
          );
      print('[STREAM DONE] chunks=$chunkCount spoken=$speakCount');
    } catch (e) {
      print('Error in streaming: $e');
    }
  }
}
