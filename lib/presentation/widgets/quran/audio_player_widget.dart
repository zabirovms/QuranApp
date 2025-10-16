import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/audio_service.dart';

class AudioPlayerWidget extends ConsumerStatefulWidget {
  final int? surahNumber;
  final int? verseNumber;
  final bool isCompact;
  final VoidCallback? onClose;

  const AudioPlayerWidget({
    super.key,
    this.surahNumber,
    this.verseNumber,
    this.isCompact = false,
    this.onClose,
  });

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  late QuranAudioService _audioService;
  double _volume = 1.0;
  double _speed = 1.0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioService = QuranAudioService();
    _initializeAudio();
  }

  void _initializeAudio() {
    // Listen to position changes
    _audioService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listen to player state changes
    _audioService.playerStateStream.listen((playerState) {
      if (mounted) {
        setState(() {
          _isPlaying = playerState.playing;
        });
      }
    });

    // Listen to duration changes
    _audioService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    });
  }

  Future<void> _playAudio() async {
    try {
      // Avoid redundant reloads: if already playing same source, do nothing
      // For surah-level play, verseNumber is null
      // We rely on service-level duplicate guard too
      if (widget.surahNumber != null && widget.verseNumber != null) {
        await _audioService.playVerse(widget.surahNumber!, widget.verseNumber!, edition: 'ar.alafasy');
      } else if (widget.surahNumber != null) {
        await _audioService.playSurah(widget.surahNumber!, edition: 'ar.alafasy');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  Future<void> _pauseAudio() async {
    await _audioService.pause();
  }

  Future<void> _stopAudio() async {
    await _audioService.stop();
  }

  Future<void> _seekTo(Duration position) async {
    await _audioService.seekTo(position);
  }

  Future<void> _setVolume(double volume) async {
    try {
      await _audioService.setVolume(volume);
      if (mounted) {
        setState(() {
          _volume = volume;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хатои тағйири садо: $e')),
        );
      }
    }
  }

  Future<void> _setSpeed(double speed) async {
    try {
      await _audioService.setSpeed(speed);
      if (mounted) {
        setState(() {
          _speed = speed;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хатои тағйири суръат: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.isCompact) {
      return _buildCompactPlayer(theme, colorScheme);
    }

    return _buildFullPlayer(theme, colorScheme);
  }

  Widget _buildCompactPlayer(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Play/Pause button
          IconButton(
            onPressed: _isPlaying ? _pauseAudio : _playAudio,
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: colorScheme.primary,
            ),
          ),
          
          // Progress bar
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: _duration.inMilliseconds > 0
                      ? _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble()
                      : 0.0,
                  max: (_duration.inMilliseconds > 0)
                      ? _duration.inMilliseconds.toDouble()
                      : 0.0,
                  onChanged: (_duration.inMilliseconds > 0)
                      ? (value) {
                          _seekTo(Duration(milliseconds: value.toInt()));
                        }
                      : null,
                  activeColor: colorScheme.primary,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Volume control
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildVolumeControl(theme, colorScheme),
              );
            },
            icon: Icon(
              _volume > 0.5 ? Icons.volume_up : Icons.volume_down,
            ),
          ),
          
          // Close button
          if (widget.onClose != null)
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  Widget _buildFullPlayer(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            widget.surahNumber != null && widget.verseNumber != null
                ? 'Surah ${widget.surahNumber}, Verse ${widget.verseNumber}'
                : 'Surah ${widget.surahNumber}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Progress bar
          Slider(
            value: _duration.inMilliseconds > 0
                ? _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble()
                : 0.0,
            max: (_duration.inMilliseconds > 0)
                ? _duration.inMilliseconds.toDouble()
                : 0.0,
            onChanged: (_duration.inMilliseconds > 0)
                ? (value) {
                    _seekTo(Duration(milliseconds: value.toInt()));
                  }
                : null,
            activeColor: colorScheme.primary,
          ),
          
          // Time display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                _formatDuration(_duration),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Stop button
              IconButton(
                onPressed: _stopAudio,
                icon: const Icon(Icons.stop),
                iconSize: 32,
              ),
              
              // Play/Pause button
              IconButton(
                onPressed: _isPlaying ? _pauseAudio : _playAudio,
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 48,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
              
              // Speed control
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => _buildSpeedControl(theme, colorScheme),
                  );
                },
                icon: const Icon(Icons.speed),
                iconSize: 32,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Volume and speed indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('Volume: ${(_volume * 100).toInt()}%'),
              Text('Speed: ${_speed}x'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Volume Control',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Slider(
            value: _volume,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: _setVolume,
            activeColor: colorScheme.primary,
          ),
          Text('${(_volume * 100).toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildSpeedControl(ThemeData theme, ColorScheme colorScheme) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Playback Speed',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: speeds.map((speed) {
              final isSelected = _speed == speed;
              return FilterChip(
                label: Text('${speed}x'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _setSpeed(speed);
                  }
                  Navigator.of(context).pop();
                },
                selectedColor: colorScheme.primary.withOpacity(0.2),
                checkmarkColor: colorScheme.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
