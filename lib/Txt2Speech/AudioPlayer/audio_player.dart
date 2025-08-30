import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Uint8List> _queue = [];
  bool _isPlaying = false;
  bool _isStopped = false;

  AudioPlayerService() {
    print('AudioPlayerService constructor');
    _audioPlayer.onPlayerComplete.listen((_) {
      print('Some Audio complete ${_isStopped}');
      if (!_isStopped) {
        _playNext();
      }
    });
  }

  bool get isPlaying => _isPlaying;

  void reset() {
    print('Resetting audio player ${_isStopped}');
    _queue.clear();
    _isPlaying = false;
    _isStopped = false; // allow new session
  }

  Future<void> enqueue(Uint8List audioBytes) async {
    print('Enqueuing audio ${_isStopped}');
    if (_isStopped) return; // ignore if stopped
    _queue.add(audioBytes);
    if (!_isPlaying) {
      await _playNext();
    }
  }

  Future<void> _playNext() async {
    print('Playing audio ${_isStopped}');
    if (_queue.isEmpty || _isStopped) {
      _isPlaying = false;
      return;
    }
    _isPlaying = true;
    final bytes = _queue.removeAt(0);
    
    await _audioPlayer.play(BytesSource(bytes));
  }

  Future<void> stop() async {
    _isStopped = true;
    _queue.clear();
    _isPlaying = false;

    await _audioPlayer.stop();
    await _audioPlayer.release();
    
  }

  Future<void> dispose() async {
    _isStopped = true;
    _queue.clear();
    _isPlaying = false;
    await _audioPlayer.dispose();
    print("dispose called ${_isStopped}");
  }
}
