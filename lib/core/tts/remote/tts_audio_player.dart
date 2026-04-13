import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'tts_remote_types.dart';

/// Remote TTS 오디오 재생.
///
/// 임시 파일에 쓰고 just_audio로 재생.
/// StreamAudioSource는 Android ExoPlayer에서 Source error를 내므로 파일 방식 사용.
class TtsAudioPlayer {
  TtsAudioPlayer();

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  String? _currentId;
  StreamSubscription? _stateSubscription;
  File? _tempFile;

  /// [TTSResponse] 재생. 같은 id가 재생 중이면 정지.
  Future<void> play(TTSResponse response, {String? id}) async {
    if (_currentId == id && isPlaying.value) {
      await stop();
      return;
    }
    await stop();
    _currentId = id;

    final audioBytes = base64Decode(response.audioBase64);
    await _playFromTempFile(audioBytes, response.mimeType);
  }

  /// Raw bytes 직접 재생.
  Future<void> playBytes(Uint8List audio, String mimeType, {String? id}) async {
    if (_currentId == id && isPlaying.value) {
      await stop();
      return;
    }
    await stop();
    _currentId = id;

    await _playFromTempFile(audio, mimeType);
  }

  Future<void> _playFromTempFile(Uint8List audio, String mimeType) async {
    final ext = mimeType.contains('mpeg') ? 'mp3' : 'wav';
    final dir = await getTemporaryDirectory();
    _tempFile = File('${dir.path}/tts_audio.$ext');
    await _tempFile!.writeAsBytes(audio, flush: true);

    await _player.setFilePath(_tempFile!.path);
    _listenState();
    await _player.play();
  }

  void _listenState() {
    _stateSubscription?.cancel();
    isPlaying.value = true;
    _stateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        isPlaying.value = false;
        _currentId = null;
        _cleanupTempFile();
      }
    });
  }

  Future<void> stop() async {
    _stateSubscription?.cancel();
    _stateSubscription = null;
    await _player.stop();
    isPlaying.value = false;
    _currentId = null;
    _cleanupTempFile();
  }

  void _cleanupTempFile() {
    try {
      _tempFile?.deleteSync();
    } catch (_) {}
    _tempFile = null;
  }

  bool isPlayingId(String id) => _currentId == id && isPlaying.value;

  void dispose() {
    _stateSubscription?.cancel();
    _player.dispose();
    _cleanupTempFile();
    isPlaying.dispose();
  }
}
