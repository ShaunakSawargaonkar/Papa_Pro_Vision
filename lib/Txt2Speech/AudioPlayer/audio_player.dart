import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Uint8List> _queue = [];
  bool _isPlaying = false;
  bool _isStopped = false;
  int _playGeneration = 0; // tracks stop/reset cycles to discard stale plays

  AudioPlayerService() {
    print('AudioPlayerService constructor');
    _audioPlayer.onPlayerComplete.listen((_) {
      print('Some Audio complete ${_isStopped}');
      if (!_isStopped) {
        _playNext();
      }
    });
  }

  // Add callback function type
  Function()? _onQueueEmptyAndComplete;

  // Add getter for the callback
  Function()? get onQueueEmptyAndComplete => _onQueueEmptyAndComplete;

  // Add setter for the callback
  set onQueueEmptyAndComplete(Function()? callback) {
    _onQueueEmptyAndComplete = callback;
  }

  bool get isPlaying => _isPlaying;

  void reset() {
    print('Resetting audio player ${_isStopped}');
    _queue.clear();
    _isPlaying = false;
    _isStopped = false; // allow new session
    _playGeneration++;
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
      if (_isPlaying && _queue.isEmpty) {
        _onQueueEmptyAndComplete?.call();
      }
      _isPlaying = false;
      return;
    }
    _isPlaying = true;
    final gen = _playGeneration;
    final bytes = _queue.removeAt(0);

    try {
      await _audioPlayer.play(BytesSource(bytes));
    } catch (e) {
      print('AudioPlayer play error: $e');
      // If generation changed during play, this was expected (stop was called)
      if (gen != _playGeneration) return;
      // Otherwise try to continue with next chunk
      _playNext();
    }
  }

  Future<void> stop() async {
    _isStopped = true;
    _queue.clear();
    _isPlaying = false;
    _playGeneration++;

    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('AudioPlayer stop error: $e');
    }
  }

  Future<void> dispose() async {
    _isStopped = true;
    _queue.clear();
    _isPlaying = false;
    _playGeneration++;
    await _audioPlayer.dispose();
    print("dispose called ${_isStopped}");
  }
}
