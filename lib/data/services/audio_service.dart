import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../datasources/remote/api_service.dart';

// Conditional import for File/Directory operations
import 'audio_service_io.dart' if (dart.library.html) 'audio_service_web.dart';

class QuranAudioService {
  static final QuranAudioService _instance = QuranAudioService._internal();
  late AudioPlayer _audioPlayer;
  AudioHandler? _audioHandler;
  final ApiService _apiService = ApiService();
  bool _isInitialized = false;

  // Number of verses per surah (1..114)
  static const List<int> _versesPerSurah = <int>[
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111,
    110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45,
    83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55,
    78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20,
    56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21,
    11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
  ];

  static int _globalAyahNumber(int surahNumber, int verseNumber) {
    int offset = 0;
    for (int i = 0; i < surahNumber - 1; i++) {
      offset += _versesPerSurah[i];
    }
    return offset + verseNumber;
  }

  QuranAudioService._internal() {
    _audioPlayer = AudioPlayer();
  }

  factory QuranAudioService() => _instance;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized && !kIsWeb) {
      // AudioService is not supported on web, only initialize on mobile platforms
      try {
        _audioHandler = await AudioService.init(
          builder: () => QuranAudioHandler(),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.tajikquran.audio',
            androidNotificationChannelName: 'Quran Audio',
            androidNotificationOngoing: true,
            androidStopForegroundOnPause: true,
          ),
        );
      } catch (e) {
        // Ignore audio service errors on unsupported platforms
      }
      _isInitialized = true;
    }
  }

  // Play surah audio
  Future<void> playSurah(int surahNumber, {String reciter = 'Abdul_Basit_Murattal'}) async {
    try {
      // Play first ayah of surah using CDN as a simple behavior
      final global = _globalAyahNumber(surahNumber, 1);
      final edition = 'ar.alafasy';
      final audioUrl = 'https://cdn.islamic.network/quran/audio/192/$edition/$global.mp3';
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      throw Exception('Failed to play surah audio: $e');
    }
  }

  // Play verse audio
  Future<void> playVerse(int surahNumber, int verseNumber, {String reciter = 'Abdul_Basit_Murattal'}) async {
    try {
      final global = _globalAyahNumber(surahNumber, verseNumber);
      final edition = 'ar.alafasy';
      final audioUrl = 'https://cdn.islamic.network/quran/audio/192/$edition/$global.mp3';
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      throw Exception('Failed to play verse audio: $e');
    }
  }

  // Play by direct URL (from AlQuran Cloud per-ayah audio)
  Future<void> playUrl(String url) async {
    try {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      throw Exception('Failed to play audio url: $e');
    }
  }

  // Pause audio
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  // Resume audio
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  // Stop audio
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  // Seek to position
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // Set volume
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  // Set playback speed
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed.clamp(0.25, 3.0));
  }

  // Get current position
  Duration? get position => _audioPlayer.position;

  // Get duration
  Duration? get duration => _audioPlayer.duration;

  // Get player state
  PlayerState get playerState => _audioPlayer.playerState;

  // Get processing state
  ProcessingState get processingState => _audioPlayer.processingState;

  // Listen to position changes
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  // Listen to player state changes
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  // Listen to processing state changes
  Stream<ProcessingState> get processingStateStream => _audioPlayer.processingStateStream;

  // Check if playing
  bool get isPlaying => _audioPlayer.playing;

  // Check if paused
  bool get isPaused => _audioPlayer.playerState.processingState == ProcessingState.completed && !_audioPlayer.playing;

  // Check if stopped
  bool get isStopped => _audioPlayer.playerState.processingState == ProcessingState.idle;

  // Get available reciters
  List<String> getAvailableReciters() {
    return [
      'Abdul_Basit_Murattal',
      'Abdul_Basit_Mujawwad',
      'Abdullah_Matroud',
      'Abdurrahmaan_As_Sudais',
      'Abdurrahmaan_As_Sudais_192kbps',
      'Abdussamad',
      'Abdussamad_192kbps',
      'Ahmed_ibn_Ali_al_Ajamy',
      'Ahmed_ibn_Ali_al_Ajamy_192kbps',
      'Alafasy',
      'Alafasy_192kbps',
      'Ali_Hajjaj_Al_Suwaysi',
      'Ali_Hajjaj_Al_Suwaysi_192kbps',
      'Fares_Abbad',
      'Fares_Abbad_192kbps',
      'Hani_Rifai',
      'Hani_Rifai_192kbps',
      'Husary',
      'Husary_192kbps',
      'Husary_Muallim',
      'Husary_Muallim_192kbps',
      'Ibrahim_Akhdar',
      'Ibrahim_Akhdar_192kbps',
      'Maher_Al_Muaiqly',
      'Maher_Al_Muaiqly_192kbps',
      'Mishary_Rashid_Alafasy',
      'Mishary_Rashid_Alafasy_192kbps',
      'Muhammad_AbdulKareem',
      'Muhammad_AbdulKareem_192kbps',
      'Muhammad_Ayyoub',
      'Muhammad_Ayyoub_192kbps',
      'Muhammad_Jibreel',
      'Muhammad_Jibreel_192kbps',
      'Saad_Al_Ghamdi',
      'Saad_Al_Ghamdi_192kbps',
      'Salah_Al_Budair',
      'Salah_Al_Budair_192kbps',
      'Saud_Al_Shuraim',
      'Saud_Al_Shuraim_192kbps',
      'Tareq_Abdul_Wahed',
      'Tareq_Abdul_Wahed_192kbps',
      'Yasser_Ad_Dussary',
      'Yasser_Ad_Dussary_192kbps',
      'Yasser_Ad_Dussary_192kbps',
      'Yasser_Ad_Dussary_192kbps',
    ];
  }

  // Download audio file for offline use (not supported on web)
  Future<String> downloadAudioFile(String url, String fileName) async {
    if (kIsWeb) {
      // On web, we can't download files for offline use
      // Just return the URL for streaming
      return url;
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      
      final filePath = '${audioDir.path}/$fileName';
      final file = File(filePath);
      
      if (await file.exists()) {
        return filePath; // File already exists
      }
      
      // Download the file
      final response = await _audioPlayer.setUrl(url);
      // Note: This is a simplified implementation
      // In a real app, you'd use a proper download manager
      
      return filePath;
    } catch (e) {
      throw Exception('Failed to download audio file: $e');
    }
  }

  // Check if audio file exists locally (not supported on web)
  Future<bool> isAudioFileCached(String fileName) async {
    if (kIsWeb) {
      return false; // No caching on web
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/audio/$fileName');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get cached audio file path (not supported on web)
  Future<String?> getCachedAudioPath(String fileName) async {
    if (kIsWeb) {
      return null; // No local files on web
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/audio/$fileName');
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _audioHandler?.stop();
  }
}

// Audio handler for background playback
class QuranAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  QuranAudioHandler() {
    _init();
  }

  void _init() {
    // Listen to player state changes and update the media item
    _player.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = playerState.processingState;
      
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        playbackState.add(playbackState.value.copyWith(
          controls: [MediaControl.pause, MediaControl.stop],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          processingState: AudioProcessingState.loading,
        ));
      } else if (playing != true) {
        playbackState.add(playbackState.value.copyWith(
          controls: [MediaControl.play, MediaControl.stop],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          processingState: AudioProcessingState.ready,
        ));
      } else {
        playbackState.add(playbackState.value.copyWith(
          controls: [MediaControl.pause, MediaControl.stop],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          processingState: AudioProcessingState.ready,
        ));
      }
    });
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> setUrl(String url) async {
    await _player.setUrl(url);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}
