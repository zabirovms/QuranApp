import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Audio player widget for Quran verses
class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onStop;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.onPlay,
    this.onPause,
    this.onStop,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading = state.processingState == ProcessingState.loading ||
                     state.processingState == ProcessingState.buffering;
        });
      }
    });
  }

  Future<void> _play() async {
    try {
      setState(() => _isLoading = true);
      await _audioPlayer.setUrl(widget.audioUrl);
      await _audioPlayer.play();
      widget.onPlay?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pause() async {
    await _audioPlayer.pause();
    widget.onPause?.call();
  }

  Future<void> _stop() async {
    await _audioPlayer.stop();
    widget.onStop?.call();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _isLoading ? null : (_isPlaying ? _pause : _play),
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
        ),
        IconButton(
          onPressed: _stop,
          icon: const Icon(Icons.stop),
        ),
      ],
    );
  }
}
