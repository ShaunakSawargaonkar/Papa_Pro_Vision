import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:papa_pro_vision/Txt2Speech/AudioPlayer/AudioPlayer.dart';
import 'package:papa_pro_vision/Txt2Speech/service_locator.dart';

class GoogleTTS implements TextToSpeechService {
  final GoogleTTSService _flutterTts = GoogleTTSService();
  @override
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

class GoogleTTSService {
  final String apiKey =
      '{Google_API_Key}'; // Replace with your actual Google API key

  final AudioPlayerService _audioPlayerService = AudioPlayerService();

  Future<void> speak(String text) async {
    print("Inside GoogleTTSService speak method with text: $text");
    final url = Uri.parse(
      'https://texttospeech.googleapis.com/v1/text:synthesize?key=$apiKey',
    );

    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      "input": {"text": text},
      "voice": {
        "languageCode": "en-IN",
        "name": "en-IN-Neural2-C",
        // "name": "en-IN-Chirp3-HD-Alnilam",
        "ssmlGender": "MALE",
      },
      "audioConfig": {"audioEncoding": "MP3", "speakingRate": 1.0},
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final audioContent = responseData['audioContent'];
      final audioBytes = base64.decode(audioContent);
      await _audioPlayerService.playAudio(audioBytes);
    } else {
      //TODO implement flutterTTS here
      throw Exception('TTS API error: ${response.body}');
    }
  }

  Future<void> stop() async {
    await _audioPlayerService.stop();
  }
}
