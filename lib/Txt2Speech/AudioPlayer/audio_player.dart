import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Uint8List> _queue = [];
  bool _isPlaying = false;
  bool _isStopped = false;
  // Session tagging. reset()/stop() bump _sessionId. Each clip records the
  // session it started under in _playingSession. A completion event that
  // arrives after a reset/stop (e.g. delayed device audio callback) will carry
  // a stale session and is ignored, so it cannot advance the NEW queue,
  // double-drain it, or fire the queue-empty callback early.
  int _sessionId = 0;
  int _playingSession = -1;

  AudioPlayerService() {
    print('AudioPlayerService constructor');
    _audioPlayer.onPlayerComplete.listen((_) {
      print('Some Audio complete ${_isStopped}');
      if (!_isStopped && _playingSession == _sessionId) {
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
    _sessionId++; // invalidate any in-flight completion from the old session
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
      if(_isPlaying && _queue.isEmpty){
        _onQueueEmptyAndComplete?.call();
      }
      _isPlaying = false;
      return;
    }
    _isPlaying = true;
    final bytes = _queue.removeAt(0);
    _playingSession = _sessionId; // tag this clip with the current session

    await _audioPlayer.play(BytesSource(bytes));
  }

  Future<void> stop() async {
    _isStopped = true;
    _queue.clear();
    _isPlaying = false;
    _sessionId++; // invalidate any in-flight completion from the old session

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
