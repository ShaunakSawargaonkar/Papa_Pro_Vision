import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:papa_pro_vision/Txt2Speech/AudioPlayer/AudioPlayer.dart';
import 'package:papa_pro_vision/Txt2Speech/Models/helper.dart';
import 'package:papa_pro_vision/Txt2Speech/service_locator.dart';
import 'package:papa_pro_vision/secrets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleTTS implements TextToSpeechService {
  final GoogleTTSService _googleTTSService = GoogleTTSService();

  bool get isPlaying => _googleTTSService.isPlaying;
  @override
  Future<void> speak(String text) async {
    _googleTTSService._isPlaying = true;
    await _googleTTSService.speak(text);
  }

  @override
  Future<void> stop() async {
    _googleTTSService._isPlaying = false;
    await _googleTTSService.stop();
  }
}

final String apiKey =  Secrets.googleApiKey;

class GoogleTTSService {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();

  bool _isPlaying = false;
  bool get isPlaying => _audioPlayerService.isPlaying;

  int _sessionId = 0;

  Future<void> speak(String text) async {
    _audioPlayerService.reset();
    _sessionId = DateTime.now().microsecond + DateTime.now().minute;
    final currentSession = _sessionId;

    final sentences = text.split('.');

    for (final sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.isEmpty) continue;
      if (!_isPlaying) return;

      print("Requesting TTS for: $trimmed");

      try {
        dynamic audioContent;
        if (Helper.IsDevanagari(trimmed)) {
          audioContent = await GetWAVFromGoogle(trimmed, "mr-IN");
        } else {
          audioContent = await GetWAVFromGoogle(trimmed, "en-IN");
        }
        if (currentSession != _sessionId) {
          print("Skipping old audio (session invalidated)");
          return;
        }

        final audioBytes = base64.decode(audioContent);

        print("Enqueuing audio for: $trimmed");
        await _audioPlayerService.enqueue(audioBytes);
      } catch (e) {
        print("TTS error for '$trimmed': $e");
      }
    }
    // _isPlaying =false;
  }

  Future<void> stop() async {
    print("Stopping playback");

    _sessionId =
        DateTime.now().microsecond +
        DateTime.now().minute; // new session // invalidate current session
    // _audioPlayerService.reset(); // clear any queued audio
    await _audioPlayerService.stop();
  }
}

Future<String> GetWAVFromGoogle(String text, String lang) async {
  print("Inside GoogleTTSService with text: $text");

  final prefs = await SharedPreferences.getInstance();
  double speechRate = prefs.getDouble('speechRate') ?? 1.0;
  final url = Uri.parse(
    'https://texttospeech.googleapis.com/v1/text:synthesize?key=$apiKey',
  );

  final headers = {'Content-Type': 'application/json'};
  dynamic body;
  if (lang == "en-IN") {
    body = jsonEncode({
      "input": {"text": text},
      "voice": {
        "languageCode": "en-IN",
        "name": "en-IN-Neural2-C",
        "ssmlGender": "MALE",
      },
      "audioConfig": {"audioEncoding": "MP3", "speakingRate": speechRate},
    });
  } else if (lang == "mr-IN") {
    body = jsonEncode({
      "input": {"text": text},
      "voice": {
        "languageCode": "mr-IN",
        "name": "mr-IN-Chirp3-HD-Achird",
        "ssmlGender": "MALE",
      },
      "audioConfig": {"audioEncoding": "MP3", "speakingRate": speechRate},
    });
  }

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    return responseData['audioContent'];
  } else {
    throw Exception(
      'Failed to get audio: ${response.statusCode} - ${response.body}',
    );
  }
}
