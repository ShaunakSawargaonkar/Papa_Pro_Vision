// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:http/http.dart' as http;
// import 'package:papa_pro_vision/Txt2Speech/AudioPlayer/AudioPlayer.dart';
// import 'package:papa_pro_vision/Txt2Speech/Models/helper.dart';
// import 'package:papa_pro_vision/Txt2Speech/service_locator.dart';

// class EdgeTTS implements TextToSpeechService {
//   final EdgeTTSService _edgeTTSService = EdgeTTSService();
  
//   @override
//   Future<void> speak(String text) async {
//     await _edgeTTSService.speak(text);
//   }

//   @override
//   Future<void> stop() async {
//     await _edgeTTSService.stop();
//   }
// }

// class EdgeTTSService {
//   final AudioPlayerService _audioPlayerService = AudioPlayerService();
//   bool get isPlaying => _audioPlayerService.isPlaying;

//   int _sessionId = 0;

//   Future<void> speak(String text) async {
//     _audioPlayerService.reset();
//     _sessionId = DateTime.now().microsecond + DateTime.now().minute;
//     final currentSession = _sessionId;

//     final sentences = text.split('.');

//     for (final sentence in sentences) {
//       final trimmed = sentence.trim();
//       if (trimmed.isEmpty) continue;

//       print("Requesting EdgeTTS for: $trimmed");

//       try {
//         dynamic audioContent;
//         if (Helper.IsDevanagari(trimmed)) {
//           audioContent = await GetAudioFromEdgeTTS(trimmed, "mr-IN");
//         } else {
//           audioContent = await GetAudioFromEdgeTTS(trimmed, "en-IN");
//         }
        
//         if (currentSession != _sessionId) {
//           print("Skipping old audio (session invalidated)");
//           return;
//         }

//         print("Enqueuing audio for: $trimmed");
//         await _audioPlayerService.enqueue(audioContent);
//       } catch (e) {
//         print("EdgeTTS error for '$trimmed': $e");
//       }
//     }
//   }

//   Future<void> stop() async {
//     print("Stopping EdgeTTS playback");

//     _sessionId = DateTime.now().microsecond + DateTime.now().minute; // new session // invalidate current session
//     _audioPlayerService.reset(); // clear any queued audio
//     await _audioPlayerService.stop();
//   }
// }

// Future<Uint8List> GetAudioFromEdgeTTS(String text, String lang) async {
//   print("Inside EdgeTTSService with text: $text");

//   // EdgeTTS endpoint and voice selection
//   String voice;
//   String rate = "0%"; // Speaking rate adjustment
//   String volume = "25%"; // Volume adjustment
  
//   if (lang == "en-IN") {
//     voice = "en-IN-NeerjaNeural"; // English (India) - Female voice
//   } else if (lang == "mr-IN") {
//     voice = "mr-IN-AarohiNeural"; // Marathi (India) - Female voice
//   } else {
//     voice = "en-US-JennyNeural"; // Default to US English
//   }

//   // EdgeTTS uses SSML format for better control
//   final ssml = '''
// <speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="$lang">
//   <voice name="$voice">
//     <prosody rate="$rate" volume="$volume">
//       $text
//     </prosody>
//   </voice>
// </speak>
// ''';

//   // Using the free Edge TTS service endpoint
//   // This is the same service that Edge browser uses for text-to-speech
//   final url = Uri.parse(
//     'https://speech.platform.bing.com/consumer/speech/synthesize/',
//   );

//   final headers = {
//     'Content-Type': 'application/ssml+xml',
//     'X-Microsoft-OutputFormat': 'audio-16khz-128kbitrate-mono-mp3',
//     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Edg/91.0.864.59',
//     'X-Requested-With': 'XMLHttpRequest',
//     'Referer': 'https://www.bing.com/translator',
//     'Accept': 'audio/wav, audio/mp3, audio/*;q=0.9, */*;q=0.8',
//     'Accept-Language': 'en-US,en;q=0.9',
//     'Accept-Encoding': 'identity',
//     'Connection': 'keep-alive',
//   };

//   try {
//     final response = await http.post(url, headers: headers, body: ssml);

//     if (response.statusCode == 200) {
//       print("EdgeTTS API call successful");
//       return response.bodyBytes;
//     } else {
//       print("EdgeTTS API error: ${response.statusCode} - ${response.body}");
//       throw Exception(
//         'Failed to get audio from EdgeTTS: ${response.statusCode} - ${response.body}',
//       );
//     }
//   } catch (e) {
//     print("EdgeTTS API error: $e");
//     throw Exception('EdgeTTS API call failed: $e');
//   }
// }
