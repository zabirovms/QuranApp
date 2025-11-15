  import 'package:just_audio/just_audio.dart';
  import 'package:audio_service/audio_service.dart';
  import 'package:path_provider/path_provider.dart';
  import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
  import 'dart:async';
  import '../../core/utils/compressed_json_loader.dart';

  // Removed unused ApiService import

  // Conditional import for File/Directory operations
  import 'audio_service_io.dart' if (dart.library.html) 'audio_service_web.dart';

class PlaybackStateInfo {
  final bool isPlaying;
  final ProcessingState processingState;
  final Duration position;
  final Duration bufferedPosition;
  final Duration? duration;
  final int? currentSurahNumber;
  final int? currentVerseNumber;
  final String? currentUrl;

  const PlaybackStateInfo({
    required this.isPlaying,
    required this.processingState,
    required this.position,
    required this.bufferedPosition,
    required this.duration,
    required this.currentSurahNumber,
    required this.currentVerseNumber,
    required this.currentUrl,
  });
}

  class QuranAudioService {
    static final QuranAudioService _instance = QuranAudioService._internal();
    late AudioPlayer _audioPlayer;
    AudioHandler? _audioHandler;
    String? _currentUrl;
    String _currentEdition = 'ar.alafasy';
    
    // Cache for surah names loaded from data source
    static Map<int, String>? _surahNamesCache;
    
    // Get surah name in Tajik from data source
    Future<String> _getSurahNameTajik(int surahNumber) async {
      // Load surah names from data source if not cached
      if (_surahNamesCache == null) {
        try {
          _surahNamesCache = {};
          final arabicData = await CompressedJsonLoader.loadCompressedJsonAsMap('assets/data/alquran_cloud_complete_quran.json.gz');
          
          if (arabicData.containsKey('data') && arabicData['data'] is Map) {
            final data = arabicData['data'] as Map<String, dynamic>;
            if (data.containsKey('surahs') && data['surahs'] is List) {
              final surahs = data['surahs'] as List;
              for (var surah in surahs) {
                if (surah is Map && surah.containsKey('number')) {
                  final number = surah['number'] as int;
                  // Try to get name_tajik if available, otherwise use name
                  final nameTajik = surah['name_tajik'] as String? ?? surah['name'] as String? ?? 'Сураи $number';
                  _surahNamesCache![number] = nameTajik;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[Audio] Failed to load surah names: $e');
          _surahNamesCache = {};
        }
      }
      
      return _surahNamesCache?[surahNumber] ?? 'Сураи $surahNumber';
    }
    
    // Get Qari name in English
    String _getQariName(String edition) {
      switch (edition) {
        case 'ar.alafasy':
          return 'Mishary Alafasy';
        case 'ar.husary':
          return 'Mahmoud Khalil Al-Husary';
        case 'ar.minshawi':
          return 'Muhammad Siddiq Al-Minshawi';
        default:
          return 'Qari';
      }
    }
  
  // Unified UI state stream to keep widgets in sync
  final StreamController<PlaybackStateInfo> _uiStateController = StreamController<PlaybackStateInfo>.broadcast();
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _bufferedSub;
  StreamSubscription<Duration?>? _durationSub;
    
    // Track current playing verse
    int? _currentSurahNumber;
    int? _currentVerseNumber;

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
      // Handler will be set after AudioService.init in main.dart
      // We'll get it lazily when needed
      // Keep internal state in sync with player lifecycle (release safety)
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          // Autoplay disabled - just stop at the end
          // User can manually play next verse or surah if desired
          debugPrint('[Audio] Playback completed - stopping (autoplay disabled)');
        }
        if (state.processingState == ProcessingState.idle) {
          // Player was stopped/released; clear URL reference
          _currentUrl = null;
        }
      _emitUiState();
      });

    // Forward core streams into a single UI state stream
    _positionSub = _audioPlayer.positionStream.listen((_) => _emitUiState());
    _bufferedSub = _audioPlayer.bufferedPositionStream.listen((_) => _emitUiState());
    _durationSub = _audioPlayer.durationStream.listen((_) => _emitUiState());
    // Seed initial UI state so subscribers have an immediate snapshot
    _emitUiState();
    }

    factory QuranAudioService() => _instance;

    // Removed unused _ensureInitialized method

    // Play surah audio using AlQuran Cloud CDN
    Future<void> playSurah(int surahNumber, {String edition = 'ar.alafasy'}) async {
      try {
        // Ensure handler is connected before starting playback
        _ensureHandlerConnected();
        
        final audioUrl = 'https://cdn.islamic.network/quran/audio-surah/128/$edition/$surahNumber.mp3';
        if (_currentUrl == audioUrl && _audioPlayer.playing) {
          return; // already playing this track
        }
        _currentUrl = audioUrl;
        _currentSurahNumber = surahNumber;
        _currentVerseNumber = null; // Clear verse number for surah playback
        _currentEdition = edition;
        debugPrint('[Audio] Play surah $surahNumber edition=$edition -> $audioUrl');
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
      _emitUiState();
      } catch (e) {
        debugPrint('[Audio][Error] playSurah failed: $e');
        throw Exception('Failed to play surah audio: $e');
      }
    }
    
    // Ensure handler is connected for notification controls
    // This gets the handler instance that AudioService.init() created
    // The static instance is set in QuranAudioHandler constructor, which is called by AudioService.init()
    void _ensureHandlerConnected() {
      if (_audioHandler == null) {
        _audioHandler = QuranAudioHandler.instance;
        if (_audioHandler != null) {
          debugPrint('[Audio] Handler connected: ${_audioHandler.runtimeType}');
          debugPrint('[Audio] Handler instance hash: ${identityHashCode(_audioHandler)}');
          debugPrint('[Audio] This is the same instance Android uses for notification controls');
        } else {
          debugPrint('[Audio] Warning: Handler not yet available - AudioService.init() may not have completed');
        }
      }
    }
    
    // Play previous surah
    Future<void> playPreviousSurah({String edition = 'ar.alafasy'}) async {
      _currentEdition = edition;
      if (_currentSurahNumber == null) return;
      
      int prevSurah = _currentSurahNumber! - 1;
      if (prevSurah < 1) {
        return; // Already at first surah
      }
      
      await playSurah(prevSurah, edition: _currentEdition);
    }
    
    // Play next surah
    Future<void> playNextSurah({String edition = 'ar.alafasy'}) async {
      _currentEdition = edition;
      if (_currentSurahNumber == null) return;
      
      int nextSurah = _currentSurahNumber! + 1;
      if (nextSurah > 114) {
        return; // Already at last surah
      }
      
      await playSurah(nextSurah, edition: _currentEdition);
    }

    // Play verse audio using AlQuran Cloud CDN
    Future<void> playVerse(int surahNumber, int verseNumber, {String edition = 'ar.alafasy'}) async {
      try {
        // Ensure handler is connected before starting playback
        _ensureHandlerConnected();
        
        final global = _globalAyahNumber(surahNumber, verseNumber);
        final audioUrl = 'https://cdn.islamic.network/quran/audio/128/$edition/$global.mp3';
        if (_currentUrl == audioUrl && _audioPlayer.playing) {
          return; // already playing this ayah
        }
        _currentUrl = audioUrl;
        _currentSurahNumber = surahNumber;
        _currentVerseNumber = verseNumber;
        _currentEdition = edition;
        debugPrint('[Audio] Play verse $surahNumber:$verseNumber edition=$edition -> $audioUrl');
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
      _emitUiState();
      } catch (e) {
        debugPrint('[Audio][Error] playVerse failed: $e');
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
      try {
        await _audioPlayer.pause();
      _emitUiState();
      } catch (e) {
        debugPrint('[Audio][Error] pause failed: $e');
      }
    }

    // Resume audio
    Future<void> resume() async {
      try {
        await _audioPlayer.play();
      _emitUiState();
      } catch (e) {
        debugPrint('[Audio][Error] resume failed: $e');
      }
    }

    // Stop audio
    Future<void> stop() async {
      try {
        await _audioPlayer.stop();
        _currentUrl = null;
        _currentSurahNumber = null;
        _currentVerseNumber = null;
      _emitUiState();
      } catch (e) {
        debugPrint('[Audio][Error] stop failed: $e');
      }
    }

    // Seek to position
    Future<void> seekTo(Duration position) async {
      await _audioPlayer.seek(position);
    }

    // Seek by delta (e.g., +/- 10 seconds)
    Future<void> seekBy(Duration delta) async {
      final current = _audioPlayer.position;
      final target = current + delta;
      final clip = target < Duration.zero ? Duration.zero : target;
      await _audioPlayer.seek(clip);
    }

    // Set volume
    Future<void> setVolume(double volume) async {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    _emitUiState();
    }

    // Set playback speed
    Future<void> setSpeed(double speed) async {
      await _audioPlayer.setSpeed(speed.clamp(0.25, 3.0));
    _emitUiState();
    }

    // Get current playing verse
    int? get currentSurahNumber => _currentSurahNumber;
    int? get currentVerseNumber => _currentVerseNumber;
    String get currentEdition => _currentEdition;
    
    // Check if a specific verse is currently playing
    bool isPlayingVerse(int surahNumber, int verseNumber) {
      return _currentSurahNumber == surahNumber && 
            _currentVerseNumber == verseNumber && 
            _audioPlayer.playing;
    }
    
    // Check if current playback is this surah (full surah mode)
    bool isPlayingSurah(int surahNumber) {
      return _currentSurahNumber == surahNumber && _currentVerseNumber == null && _audioPlayer.playing;
    }
    
    // Play previous verse
    Future<void> playPreviousVerse({String edition = 'ar.alafasy'}) async {
      _currentEdition = edition;
      if (_currentSurahNumber == null || _currentVerseNumber == null) {
        debugPrint('[Audio] playPreviousVerse: not in verse mode');
        return;
      }
      
      int prevSurah = _currentSurahNumber!;
      int prevVerse = _currentVerseNumber! - 1;
      
      if (prevVerse < 1) {
        // Go to previous surah
        if (prevSurah > 1) {
          prevSurah--;
          prevVerse = _versesPerSurah[prevSurah - 1];
        } else {
          debugPrint('[Audio] playPreviousVerse: already at first verse');
          return; // Already at first verse
        }
      }
      
      debugPrint('[Audio] playPreviousVerse: playing $prevSurah:$prevVerse');
      await playVerse(prevSurah, prevVerse, edition: _currentEdition);
    }
    
    // Play next verse
    Future<void> playNextVerse({String edition = 'ar.alafasy'}) async {
      _currentEdition = edition;
      if (_currentSurahNumber == null || _currentVerseNumber == null) {
        debugPrint('[Audio] playNextVerse: not in verse mode');
        return;
      }
      
      int nextSurah = _currentSurahNumber!;
      int nextVerse = _currentVerseNumber! + 1;
      
      if (nextVerse > _versesPerSurah[nextSurah - 1]) {
        // Go to next surah
        if (nextSurah < 114) {
          nextSurah++;
          nextVerse = 1;
        } else {
          debugPrint('[Audio] playNextVerse: already at last verse');
          return; // Already at last verse
        }
      }
      
      debugPrint('[Audio] playNextVerse: playing $nextSurah:$nextVerse');
      await playVerse(nextSurah, nextVerse, edition: _currentEdition);
    }

    // Get current position
    Duration get position => _audioPlayer.position;

    // Get duration
    Duration? get duration => _audioPlayer.duration;

    // Get player state
    PlayerState get playerState => _audioPlayer.playerState;

    // Get processing state
    ProcessingState get processingState => _audioPlayer.processingState;

    // Listen to position changes
    Stream<Duration> get positionStream => _audioPlayer.positionStream;

    // Listen to buffered position changes (for smooth progress UI)
    Stream<Duration> get bufferedPositionStream => _audioPlayer.bufferedPositionStream;

    // Listen to player state changes
    Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

    // Listen to processing state changes
    Stream<ProcessingState> get processingStateStream => _audioPlayer.processingStateStream;

    // Listen to duration changes
    Stream<Duration?> get durationStream => _audioPlayer.durationStream;

    // Check if playing
    bool get isPlaying => _audioPlayer.playing;

    // Check if paused
    bool get isPaused => !_audioPlayer.playing && _audioPlayer.playerState.processingState == ProcessingState.ready;

    // Check if stopped
    bool get isStopped => _audioPlayer.playerState.processingState == ProcessingState.idle;

    // Get available reciters (AlQuran Cloud editions)
    // Trimmed to reliably working editions (avoid 404s)
    List<String> getAvailableReciters() {
      return [
        'ar.alafasy',   // Mishary Alafasy
        'ar.husary',    // Mahmoud Khalil Al-Husary
        'ar.minshawi',  // Muhammad Siddiq Al-Minshawi
      ];
    }

    // Toggle play/pause for current or target item
    Future<void> togglePlayPause({int? surahNumber, int? verseNumber, String edition = 'ar.alafasy'}) async {
      try {
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
        _emitUiState();
          return;
        }

        // If specific target provided, start that
        if (surahNumber != null) {
        // If resuming the same loaded track, just play without resetting URL
        final isSameSurah = _currentSurahNumber == surahNumber && _currentVerseNumber == null;
        final isSameVerse = _currentSurahNumber == surahNumber && _currentVerseNumber == verseNumber;
        if (_currentUrl != null && (verseNumber == null ? isSameSurah : isSameVerse)) {
          await _audioPlayer.play();
          _emitUiState();
          return;
        }
        if (verseNumber == null) {
          await playSurah(surahNumber, edition: edition);
        } else {
          await playVerse(surahNumber, verseNumber, edition: edition);
        }
        return;
        }

        // Otherwise resume current
        if (_currentUrl != null) {
          await _audioPlayer.play();
        _emitUiState();
        }
      } catch (e) {
        debugPrint('[Audio][Error] togglePlayPause failed: $e');
      }
    }

  // Unified UI state stream
  Stream<PlaybackStateInfo> get uiStateStream => _uiStateController.stream;

  void _emitUiState() {
    final info = PlaybackStateInfo(
      isPlaying: _audioPlayer.playing,
      processingState: _audioPlayer.processingState,
      position: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      duration: _audioPlayer.duration,
      currentSurahNumber: _currentSurahNumber,
      currentVerseNumber: _currentVerseNumber,
      currentUrl: _currentUrl,
    );
    if (!_uiStateController.isClosed) {
      _uiStateController.add(info);
    }

    // Mirror state into system notification
    // Get handler instance (the one that AudioService.init() created)
    _ensureHandlerConnected();
    final handler = _audioHandler;
    if (handler != null) {
      final quranHandler = handler as QuranAudioHandler?;
      if (quranHandler != null && _currentSurahNumber != null) {
        // Build title in Tajik (async, but we'll handle it)
        _getSurahNameTajik(_currentSurahNumber!).then((surahName) {
          final String title;
          if (_currentVerseNumber == null) {
            // Full surah mode
            title = 'Сураи $surahName';
          } else {
            // Verse mode
            title = '$surahName - Ояти ${_currentVerseNumber}';
          }
          
          final qariName = _getQariName(_currentEdition);
          
          final media = MediaItem(
            id: _currentUrl ?? 'quran_stream',
            album: 'Қуръон',
            title: title,
            artist: qariName,
            duration: _audioPlayer.duration,
          );
          quranHandler.updateFromExternal(
            isPlaying: _audioPlayer.playing,
            processingState: _audioPlayer.processingState,
            position: _audioPlayer.position,
            item: media,
          );
        }).catchError((e) {
          debugPrint('[Audio] Error loading surah name: $e');
          // Fallback with surah number
          final String title;
          if (_currentVerseNumber == null) {
            title = 'Сураи ${_currentSurahNumber}';
          } else {
            title = 'Сураи ${_currentSurahNumber} - Ояти ${_currentVerseNumber}';
          }
          
          final qariName = _getQariName(_currentEdition);
          
          final media = MediaItem(
            id: _currentUrl ?? 'quran_stream',
            album: 'Қуръон',
            title: title,
            artist: qariName,
            duration: _audioPlayer.duration,
          );
          quranHandler.updateFromExternal(
            isPlaying: _audioPlayer.playing,
            processingState: _audioPlayer.processingState,
            position: _audioPlayer.position,
            item: media,
          );
        });
      }
    }
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
        await _audioPlayer.setUrl(url);
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
  class QuranAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
    static QuranAudioHandler? _instance;
    StreamSubscription<Duration>? _positionSubscription;
    Timer? _positionUpdateTimer;
    
    QuranAudioHandler() {
      _instance = this;
      // Initialize empty queue - will be populated when playback starts
      queue.add([]);
      debugPrint('[AudioHandler] ========== QuranAudioHandler instance created ==========');
      debugPrint('[AudioHandler] Instance hash: ${identityHashCode(this)}');
      debugPrint('[AudioHandler] This is the instance that AudioService.init() created');
      debugPrint('[AudioHandler] Android will use THIS instance for notification controls');
      
      // Initialize playbackState with idle state
      // This ensures the service is ready to receive commands
      playbackState.add(PlaybackState(
        controls: [],
        systemActions: const {},
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        speed: 1.0,
        queueIndex: 0,
      ));
      debugPrint('[AudioHandler] Initial playbackState set to idle');
      
      // Set up continuous position updates from the audio player
      _setupPositionUpdates();
    }
    
    @override
    Future<void> onTaskRemoved() async {
      debugPrint('[AudioHandler] onTaskRemoved called - stopping playback');
      await stop();
      await super.onTaskRemoved();
    }
    
    static QuranAudioHandler? get instance => _instance;
    
    void _setupPositionUpdates() {
      final audioService = QuranAudioService();
      // Subscribe to position stream for continuous updates
      _positionSubscription = audioService.positionStream.listen((position) {
        // Only update if we have an active media item
        final currentMediaItem = mediaItem.value;
        if (currentMediaItem != null && 
            currentMediaItem.id.isNotEmpty && 
            (audioService.isPlaying || audioService.isPaused)) {
          playbackState.add(playbackState.value.copyWith(
            updatePosition: position,
          ));
        }
      });
      
      // Also use a timer as a backup for position updates (every 200ms)
      // This ensures the notification bar always has up-to-date position
      _positionUpdateTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        final audioService = QuranAudioService();
        final currentMediaItem = mediaItem.value;
        if (currentMediaItem != null && 
            currentMediaItem.id.isNotEmpty && 
            (audioService.isPlaying || audioService.isPaused)) {
          final currentPosition = audioService.position;
          // CRITICAL: Always include controls when updating position
          // This ensures controls remain active even during position updates
          final currentState = playbackState.value;
          playbackState.add(currentState.copyWith(
            updatePosition: currentPosition,
            // Keep existing controls - don't lose them during position updates
            controls: currentState.controls,
            systemActions: currentState.systemActions,
          ));
        }
      });
    }
    
    void dispose() {
      debugPrint('[AudioHandler] dispose() called - cleaning up');
      _positionSubscription?.cancel();
      _positionUpdateTimer?.cancel();
    }

    void updateFromExternal({
      required bool isPlaying,
      required ProcessingState processingState,
      required Duration position,
      required MediaItem item,
    }) {
      debugPrint('[AudioHandler] updateFromExternal called: ${item.title}, isPlaying=$isPlaying');
      
      // CRITICAL: Update queue FIRST - this ensures proper service binding
      if (queue.value.isEmpty || queue.value.length != 1 || queue.value.first.id != item.id) {
        queue.add([item]);
        debugPrint('[AudioHandler] Queue updated with item: ${item.id}');
      }
      
      // Determine processing state and controls BEFORE setting mediaItem
      AudioProcessingState audioProc;
      switch (processingState) {
        case ProcessingState.idle:
          audioProc = AudioProcessingState.idle;
          break;
        case ProcessingState.loading:
          audioProc = AudioProcessingState.loading;
          break;
        case ProcessingState.buffering:
          audioProc = AudioProcessingState.buffering;
          break;
        case ProcessingState.ready:
          audioProc = AudioProcessingState.ready;
          break;
        case ProcessingState.completed:
          audioProc = AudioProcessingState.completed;
          break;
      }
      
      // Determine if we're in verse mode or surah mode (both support previous/next)
      final audioService = QuranAudioService();
      final isVerseMode = audioService.currentVerseNumber != null;
      final isSurahMode = audioService.currentSurahNumber != null && audioService.currentVerseNumber == null;
      
      // Build controls list with previous/next for both verse and surah mode
      final List<MediaControl> controls;
      if (isVerseMode || isSurahMode) {
        controls = isPlaying
            ? const [
                MediaControl.skipToPrevious,
                MediaControl.pause,
                MediaControl.skipToNext,
                MediaControl.stop,
              ]
            : const [
                MediaControl.skipToPrevious,
                MediaControl.play,
                MediaControl.skipToNext,
                MediaControl.stop,
              ];
      } else {
        controls = isPlaying
            ? const [MediaControl.pause, MediaControl.stop]
            : const [MediaControl.play, MediaControl.stop];
      }
      
      // Build system actions - include skip actions for both verse and surah mode
      // CRITICAL: systemActions must include ALL actions that correspond to controls
      final Set<MediaAction> systemActions = {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        // Always include play/pause actions
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
      };
      
      if (isVerseMode || isSurahMode) {
        systemActions.add(MediaAction.skipToNext);
        systemActions.add(MediaAction.skipToPrevious);
      }
      
      // CRITICAL: Set mediaItem and playbackState together
      // The audio_service package needs both set for proper MediaSession binding
      final wasIdle = playbackState.value.processingState == AudioProcessingState.idle;
      
      // Set mediaItem first to start the service
      mediaItem.add(item);
      debugPrint('[AudioHandler] MediaItem set: ${item.title}');
      
      // Set playbackState immediately after with all controls and actions
      // This ensures the MediaSession is fully configured
      final newState = PlaybackState(
        controls: controls,
        systemActions: systemActions,
        processingState: audioProc,
        playing: isPlaying,
        updatePosition: position,
        speed: 1.0,
        queueIndex: 0,
      );
      playbackState.add(newState);
      debugPrint('[AudioHandler] SystemActions include: play=${systemActions.contains(MediaAction.play)}, pause=${systemActions.contains(MediaAction.pause)}, skipNext=${systemActions.contains(MediaAction.skipToNext)}, skipPrev=${systemActions.contains(MediaAction.skipToPrevious)}');
      debugPrint('[AudioHandler] PlaybackState set: playing=$isPlaying, processingState=$audioProc');
      debugPrint('[AudioHandler] Controls: ${controls.length} controls, systemActions: ${systemActions.length} actions');
      debugPrint('[AudioHandler] MediaSession should now be active with all controls registered');
      
      // Log if this is the first time starting the service
      if (wasIdle && audioProc != AudioProcessingState.idle) {
        debugPrint('[AudioHandler] ========== Service starting with media item: ${item.title} ==========');
        debugPrint('[AudioHandler] Service should now be bound and ready for notification controls');
      }
    }

    @override
    Future<void> play() async {
      // Log to console AND system log for visibility
      debugPrint('[AudioHandler] ========== play() called from notification ==========');
      print('[AudioHandler] ========== play() called from notification ==========');
      debugPrint('[AudioHandler] Instance hash: ${identityHashCode(this)}');
      debugPrint('[AudioHandler] Current playbackState.playing: ${playbackState.value.playing}');
      try {
        // Update state immediately for responsive UI
        final currentState = playbackState.value;
        final updatedControls = _updateControlsForState(currentState.controls, true);
        playbackState.add(currentState.copyWith(
          playing: true,
          controls: updatedControls,
        ));
        debugPrint('[AudioHandler] Updated playbackState.playing to: true');
        final audioService = QuranAudioService();
        await audioService.resume();
        debugPrint('[AudioHandler] play() completed successfully');
      } catch (e, stackTrace) {
        debugPrint('[AudioHandler] play() error: $e');
        debugPrint('[AudioHandler] stackTrace: $stackTrace');
        // Revert state on error
        playbackState.add(playbackState.value.copyWith(playing: false));
      }
    }

    @override
    Future<void> pause() async {
      // Log to console AND system log for visibility
      debugPrint('[AudioHandler] ========== pause() called from notification ==========');
      print('[AudioHandler] ========== pause() called from notification ==========');
      debugPrint('[AudioHandler] Instance hash: ${identityHashCode(this)}');
      debugPrint('[AudioHandler] Current playbackState.playing: ${playbackState.value.playing}');
      try {
        // Update state immediately for responsive UI
        final currentState = playbackState.value;
        final updatedControls = _updateControlsForState(currentState.controls, false);
        playbackState.add(currentState.copyWith(
          playing: false,
          controls: updatedControls,
        ));
        debugPrint('[AudioHandler] Updated playbackState.playing to: false');
        final audioService = QuranAudioService();
        await audioService.pause();
        debugPrint('[AudioHandler] pause() completed successfully');
      } catch (e, stackTrace) {
        debugPrint('[AudioHandler] pause() error: $e');
        debugPrint('[AudioHandler] stackTrace: $stackTrace');
        // Revert state on error
        playbackState.add(playbackState.value.copyWith(playing: true));
      }
    }
    
    // Helper method to update controls based on playing state
    List<MediaControl> _updateControlsForState(List<MediaControl> currentControls, bool isPlaying) {
      // Check if we have skip controls (verse or surah mode)
      final hasSkipControls = currentControls.contains(MediaControl.skipToPrevious) || 
                             currentControls.contains(MediaControl.skipToNext);
      
      if (hasSkipControls) {
        return isPlaying
            ? const [
                MediaControl.skipToPrevious,
                MediaControl.pause,
                MediaControl.skipToNext,
                MediaControl.stop,
              ]
            : const [
                MediaControl.skipToPrevious,
                MediaControl.play,
                MediaControl.skipToNext,
                MediaControl.stop,
              ];
      } else {
        return isPlaying
            ? const [MediaControl.pause, MediaControl.stop]
            : const [MediaControl.play, MediaControl.stop];
      }
    }

    @override
    Future<void> stop() async {
      debugPrint('[AudioHandler] stop() called from notification');
      // Update state immediately
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ));
      await QuranAudioService().stop();
    }

    @override
    Future<void> seek(Duration position) async {
      debugPrint('[AudioHandler] seek() called from notification: $position');
      // Update position immediately
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
      await QuranAudioService().seekTo(position);
    }
    
    // Override skipToQueueItem to handle custom navigation
    @override
    Future<void> skipToQueueItem(int index) async {
      debugPrint('[AudioHandler] skipToQueueItem called with index: $index');
      // For our use case, we handle navigation via skipToNext/Previous
      // This method is called when queue navigation is used
      // We'll let the default behavior handle it, but log it
      return super.skipToQueueItem(index);
    }

    @override
    Future<void> skipToNext() async {
      debugPrint('[AudioHandler] ========== skipToNext() called from notification ==========');
      debugPrint('[AudioHandler] Instance hash: ${identityHashCode(this)}');
      try {
        final audioService = QuranAudioService();
        // Update to loading state immediately
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.loading,
        ));
        
        if (audioService.currentVerseNumber != null) {
          // Verse mode - play next verse
          debugPrint('[AudioHandler] skipToNext: verse mode, playing next verse');
          await audioService.playNextVerse(edition: audioService.currentEdition);
        } else if (audioService.currentSurahNumber != null) {
          // Surah mode - play next surah
          debugPrint('[AudioHandler] skipToNext: surah mode, playing next surah');
          await audioService.playNextSurah(edition: audioService.currentEdition);
        } else {
          debugPrint('[AudioHandler] skipToNext: no active playback');
          // Revert loading state if no playback
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.idle,
          ));
        }
      } catch (e) {
        debugPrint('[AudioHandler] skipToNext error: $e');
        // Revert to previous state on error
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.ready,
        ));
      }
    }

    @override
    Future<void> skipToPrevious() async {
      debugPrint('[AudioHandler] ========== skipToPrevious() called from notification ==========');
      debugPrint('[AudioHandler] Instance hash: ${identityHashCode(this)}');
      try {
        final audioService = QuranAudioService();
        // Update to loading state immediately
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.loading,
        ));
        
        if (audioService.currentVerseNumber != null) {
          // Verse mode - play previous verse
          debugPrint('[AudioHandler] skipToPrevious: verse mode, playing previous verse');
          await audioService.playPreviousVerse(edition: audioService.currentEdition);
        } else if (audioService.currentSurahNumber != null) {
          // Surah mode - play previous surah
          debugPrint('[AudioHandler] skipToPrevious: surah mode, playing previous surah');
          await audioService.playPreviousSurah(edition: audioService.currentEdition);
        } else {
          debugPrint('[AudioHandler] skipToPrevious: no active playback');
          // Revert loading state if no playback
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.idle,
          ));
        }
      } catch (e) {
        debugPrint('[AudioHandler] skipToPrevious error: $e');
        // Revert to previous state on error
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.ready,
        ));
      }
    }
  }
