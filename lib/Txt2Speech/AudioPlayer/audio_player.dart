import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Uint8List> _queue = [];
  bool _isPlaying = false;
  bool _isStopped = false;
  // Session tagging, keyed on the controller's interaction token so the player,
  // the TTS service and the LLM stream all agree on what "current" means.
  // 0 means no session is open. Each clip records the session it started under
  // in _playingSession, so a completion event arriving after a session change
  // carries a stale tag and is ignored: it cannot advance the NEW queue,
  // double-drain it, or fire the queue-empty callback early.
  int _sessionId = 0;
  int _playingSession = -1;
  // Set by endSession() once the producer has emitted its final clip. Until
  // then an empty queue only means synthesis has not caught up with playback,
  // which must NOT be reported as "response finished".
  bool _producerDone = false;

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

  int get sessionId => _sessionId;

  /// Opens the queue for [token]. Idempotent: re-opening the session that is
  /// already current keeps whatever is queued, so an intermediate announcement
  /// spoken at the start of an interaction is not cut off when the response
  /// stream for the same interaction opens its session a moment later.
  void beginSession(int token) {
    if (_sessionId == token && !_isStopped) {
      _producerDone = false;
      return;
    }
    print('Audio player session $_sessionId -> $token');
    _queue.clear();
    _isPlaying = false;
    _isStopped = false;
    _producerDone = false;
    _sessionId = token;
  }

  /// Signals that no further clips will be produced for [token]. Only after
  /// this can a drained queue be reported as a completed response.
  void endSession(int token) {
    if (token != _sessionId || _isStopped) return;
    _producerDone = true;
    // The queue may have drained while the producer was still synthesising, in
    // which case the completion event has already been and gone and nothing
    // else will fire the callback.
    if (!_isPlaying && _queue.isEmpty) {
      _onQueueEmptyAndComplete?.call();
    }
  }

  Future<void> enqueue(Uint8List audioBytes, {int token = -1}) async {
    print('Enqueuing audio ${_isStopped}');
    if (_isStopped) return; // ignore if stopped
    if (token != -1 && token != _sessionId) {
      print('Dropping audio from stale session $token (current $_sessionId)');
      return;
    }
    _queue.add(audioBytes);
    if (!_isPlaying) {
      await _playNext();
    }
  }

  Future<void> _playNext() async {
    print('Playing audio ${_isStopped}');
    if (_queue.isEmpty || _isStopped) {
      // Report completion only once the producer has signalled that no more
      // clips are coming. A transient underrun (synthesis slower than
      // playback) must leave the session open, otherwise the state and session
      // guards upstream silently discard the rest of the response.
      if (_isPlaying && _queue.isEmpty && _producerDone && !_isStopped) {
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
    _producerDone = false;
    _sessionId = 0; // no session; tokens are strictly positive

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
