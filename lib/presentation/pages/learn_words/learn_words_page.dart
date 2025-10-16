import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../../../data/models/word_learning_model.dart';
import '../../../data/datasources/local/json_data_source.dart';
import '../../../data/services/timer_service.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';

// Game modes
enum GameMode { flashcards, quiz, match, typing, listening }

// Difficulty levels
enum GameDifficulty { beginner, intermediate, advanced }

// Providers
final wordLearningDataProvider = FutureProvider<List<WordLearningModel>>((ref) async {
  final jsonDataSource = JsonDataSource();
  return await jsonDataSource.getWordLearningData();
});

final wordLearningGameProvider = StateNotifierProvider<WordLearningGameNotifier, WordLearningGameState>((ref) => WordLearningGameNotifier());

// Game state model
class WordLearningGameState {
  final GameMode gameMode;
  final GameDifficulty difficulty;
  final int currentWordIndex;
  final bool isFlipped;
  final bool showTranslation;
  final bool showTransliteration;
  final bool revealAnswers;
  final bool audioEnabled;
  final int score;
  final List<int> wordsLearned;
  final int streak;
  final int bestStreak;
  final List<WordLearningModel> quizOptions;
  final int? selectedAnswer;
  final List<MatchPair> matchPairs;
  final int? firstSelected;
  final bool gameCompleted;
  final int wordCount;
  final List<WordLearningModel> studyWords;
  final String typingInput;
  final bool isListening;
  final bool showExample;
  final int timer;
  final bool isTimerRunning;

  WordLearningGameState({
    this.gameMode = GameMode.flashcards,
    this.difficulty = GameDifficulty.beginner,
    this.currentWordIndex = 0,
    this.isFlipped = false,
    this.showTranslation = true,
    this.showTransliteration = true,
    this.revealAnswers = false,
    this.audioEnabled = true,
    this.score = 0,
    this.wordsLearned = const [],
    this.streak = 0,
    this.bestStreak = 0,
    this.quizOptions = const [],
    this.selectedAnswer,
    this.matchPairs = const [],
    this.firstSelected,
    this.gameCompleted = false,
    this.wordCount = 10,
    this.studyWords = const [],
    this.typingInput = '',
    this.isListening = false,
    this.showExample = false,
    this.timer = 0,
    this.isTimerRunning = false,
  });

  WordLearningGameState copyWith({
    GameMode? gameMode,
    GameDifficulty? difficulty,
    int? currentWordIndex,
    bool? isFlipped,
    bool? showTranslation,
    bool? showTransliteration,
    bool? revealAnswers,
    bool? audioEnabled,
    int? score,
    List<int>? wordsLearned,
    int? streak,
    int? bestStreak,
    List<WordLearningModel>? quizOptions,
    int? selectedAnswer,
    List<MatchPair>? matchPairs,
    int? firstSelected,
    bool? gameCompleted,
    int? wordCount,
    List<WordLearningModel>? studyWords,
    String? typingInput,
    bool? isListening,
    bool? showExample,
    int? timer,
    bool? isTimerRunning,
  }) {
    return WordLearningGameState(
      gameMode: gameMode ?? this.gameMode,
      difficulty: difficulty ?? this.difficulty,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      showTranslation: showTranslation ?? this.showTranslation,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      revealAnswers: revealAnswers ?? this.revealAnswers,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      score: score ?? this.score,
      wordsLearned: wordsLearned ?? this.wordsLearned,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      quizOptions: quizOptions ?? this.quizOptions,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      matchPairs: matchPairs ?? this.matchPairs,
      firstSelected: firstSelected ?? this.firstSelected,
      gameCompleted: gameCompleted ?? this.gameCompleted,
      wordCount: wordCount ?? this.wordCount,
      studyWords: studyWords ?? this.studyWords,
      typingInput: typingInput ?? this.typingInput,
      isListening: isListening ?? this.isListening,
      showExample: showExample ?? this.showExample,
      timer: timer ?? this.timer,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
    );
  }
}

// Match pair model
class MatchPair {
  final int id;
  final WordLearningModel word;
  final bool isMatched;
  final bool isSelected;

  MatchPair({
    required this.id,
    required this.word,
    this.isMatched = false,
    this.isSelected = false,
  });

  MatchPair copyWith({
    int? id,
    WordLearningModel? word,
    bool? isMatched,
    bool? isSelected,
  }) {
    return MatchPair(
      id: id ?? this.id,
      word: word ?? this.word,
      isMatched: isMatched ?? this.isMatched,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

// Game notifier
class WordLearningGameNotifier extends StateNotifier<WordLearningGameState> {
  WordLearningGameNotifier() : super(WordLearningGameState()) {
    _loadSettings();
  }

  static const String _keyWordsLearned = 'words_learned';
  static const String _keyDifficulty = 'words_difficulty';
  static const String _keyWordCount = 'words_count';
  static const String _keyTimer = 'words_timer';
  static const String _keyBestStreak = 'best_streak';
  static const String _keyShowTranslation = 'show_translation';
  static const String _keyShowTransliteration = 'show_transliteration';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    state = state.copyWith(
      wordsLearned: (prefs.getStringList(_keyWordsLearned) ?? [])
          .map((e) => int.parse(e))
          .toList(),
      difficulty: GameDifficulty.values.firstWhere(
        (d) => d.name == prefs.getString(_keyDifficulty),
        orElse: () => GameDifficulty.beginner,
      ),
      wordCount: prefs.getInt(_keyWordCount) ?? 10,
      timer: prefs.getInt(_keyTimer) ?? 0,
      bestStreak: prefs.getInt(_keyBestStreak) ?? 0,
      showTranslation: prefs.getBool(_keyShowTranslation) ?? true,
      showTransliteration: prefs.getBool(_keyShowTransliteration) ?? true,
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyWordsLearned,
      state.wordsLearned.map((e) => e.toString()).toList(),
    );
    await prefs.setString(_keyDifficulty, state.difficulty.name);
    await prefs.setInt(_keyWordCount, state.wordCount);
    await prefs.setInt(_keyTimer, state.timer);
    await prefs.setInt(_keyBestStreak, state.bestStreak);
    await prefs.setBool(_keyShowTranslation, state.showTranslation);
    await prefs.setBool(_keyShowTransliteration, state.showTransliteration);
  }

  void initializeStudyWords(List<WordLearningModel> allWords) {
    int poolSize;
    switch (state.difficulty) {
      case GameDifficulty.beginner:
        poolSize = 10;
        break;
      case GameDifficulty.intermediate:
        poolSize = 20;
        break;
      case GameDifficulty.advanced:
        poolSize = 30;
        break;
    }

    final wordPool = allWords.take(poolSize).toList();
    final shuffled = List<WordLearningModel>.from(wordPool)..shuffle();
    final studyWords = shuffled.take(state.wordCount).toList();

    state = state.copyWith(
      studyWords: studyWords,
      currentWordIndex: 0,
      isFlipped: false,
      score: 0,
      streak: 0,
      gameCompleted: false,
      typingInput: '',
      isListening: false,
      showExample: false,
      selectedAnswer: null,
    );

    if (state.gameMode == GameMode.quiz) {
      generateQuizOptions(0, studyWords);
    } else if (state.gameMode == GameMode.match) {
      generateMatchPairs(studyWords.take(8).toList());
    }

    _saveSettings();
  }

  void generateQuizOptions(int index, List<WordLearningModel> wordsList) {
    if (wordsList.isEmpty || index >= wordsList.length) return;

    final correctWord = wordsList[index];
    final otherWords = state.studyWords
        .where((w) => w.rank != correctWord.rank)
        .toList()
      ..shuffle();
    
    final options = [correctWord, ...otherWords.take(3)].take(4).toList()
      ..shuffle();

    state = state.copyWith(
      quizOptions: options,
      selectedAnswer: null,
      revealAnswers: false,
    );
  }

  void generateMatchPairs(List<WordLearningModel> wordsList) {
    if (wordsList.length < 2) {
      state = state.copyWith(matchPairs: []);
      return;
    }

    final gameWords = wordsList.take(8).toList();
    final pairs = <MatchPair>[];

    for (int i = 0; i < gameWords.length; i++) {
      final word = gameWords[i];
      pairs.addAll([
        MatchPair(id: i * 2, word: word),
        MatchPair(id: i * 2 + 1, word: word),
      ]);
    }

    pairs.shuffle();

    state = state.copyWith(
      matchPairs: pairs,
      firstSelected: null,
    );
  }

  void flipCard() {
    state = state.copyWith(isFlipped: !state.isFlipped);
    
    if (state.audioEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void navigateWord(String direction) {
    if (state.studyWords.isEmpty) return;

    int newIndex;
    if (direction == 'next') {
      newIndex = state.currentWordIndex + 1;
      if (newIndex >= state.studyWords.length) {
        state = state.copyWith(
          gameCompleted: true,
          isTimerRunning: false,
        );
        return;
      }
    } else {
      newIndex = (state.currentWordIndex - 1 + state.studyWords.length) % state.studyWords.length;
    }

    state = state.copyWith(
      currentWordIndex: newIndex,
      isFlipped: false,
      typingInput: '',
      showExample: false,
    );

    if (state.gameMode == GameMode.quiz) {
      generateQuizOptions(newIndex, state.studyWords);
    }

    if (state.audioEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void markAsLearned(int rank) {
    if (!state.wordsLearned.contains(rank)) {
      final newWordsLearned = [...state.wordsLearned, rank];
      final newScore = state.score + 5;
      final newStreak = state.streak + 1;
      final newBestStreak = math.max(state.bestStreak, newStreak);

      state = state.copyWith(
        wordsLearned: newWordsLearned,
        score: newScore,
        streak: newStreak,
        bestStreak: newBestStreak,
      );
      _saveSettings();
    }
  }

  void checkAnswer(int index) {
    if (state.selectedAnswer != null || state.revealAnswers) return;

    state = state.copyWith(
      selectedAnswer: index,
      revealAnswers: true,
    );

    final isCorrect = state.quizOptions[index].rank == state.studyWords[state.currentWordIndex].rank;

    if (isCorrect) {
      final newScore = state.score + 10;
      final newStreak = state.streak + 1;
      final newBestStreak = math.max(state.bestStreak, newStreak);

      state = state.copyWith(
        score: newScore,
        streak: newStreak,
        bestStreak: newBestStreak,
      );

      markAsLearned(state.studyWords[state.currentWordIndex].rank);
    } else {
      state = state.copyWith(streak: 0);
    }

    _saveSettings();
  }

  void handleMatchSelection(int id) {
    if (state.firstSelected == null) {
      state = state.copyWith(
        firstSelected: id,
        matchPairs: state.matchPairs.map((pair) => 
          pair.id == id ? pair.copyWith(isSelected: true) : pair
        ).toList(),
      );
    } else {
      final firstPair = state.matchPairs.firstWhere((p) => p.id == state.firstSelected);
      final secondPair = state.matchPairs.firstWhere((p) => p.id == id);
      
      if (firstPair.word.rank == secondPair.word.rank) {
        // Match found
        final newScore = state.score + 15;
        final newStreak = state.streak + 1;
        final newBestStreak = math.max(state.bestStreak, newStreak);

        state = state.copyWith(
          score: newScore,
          streak: newStreak,
          bestStreak: newBestStreak,
          matchPairs: state.matchPairs.map((pair) => 
            pair.id == id || pair.id == state.firstSelected
              ? pair.copyWith(isMatched: true, isSelected: false)
              : pair
          ).toList(),
          firstSelected: null,
        );

        markAsLearned(firstPair.word.rank);

        // Check if all pairs are matched
        final allMatched = state.matchPairs.every((pair) => 
          pair.isMatched || pair.id == id || pair.id == state.firstSelected
        );
        if (allMatched) {
          state = state.copyWith(
            gameCompleted: true,
            isTimerRunning: false,
          );
        }
      } else {
        // No match
        state = state.copyWith(
          streak: 0,
          matchPairs: state.matchPairs.map((pair) => 
            pair.id == id || pair.id == state.firstSelected
              ? pair.copyWith(isSelected: false)
              : pair
          ).toList(),
          firstSelected: null,
        );
      }
    }
  }

  void handleTyping(String input) {
    state = state.copyWith(typingInput: input);

    if (state.studyWords.isNotEmpty && 
        input.toLowerCase() == state.studyWords[state.currentWordIndex].translationTajik.toLowerCase()) {
      final newScore = state.score + 10;
      final newStreak = state.streak + 1;
      final newBestStreak = math.max(state.bestStreak, newStreak);

      state = state.copyWith(
        score: newScore,
        streak: newStreak,
        bestStreak: newBestStreak,
      );

      markAsLearned(state.studyWords[state.currentWordIndex].rank);

      // Auto-advance after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        navigateWord('next');
      });
    }
  }

  void handleListening() {
    if (!state.isListening && state.studyWords.isNotEmpty) {
      state = state.copyWith(isListening: true);
      
      // Text-to-speech would be implemented here
      // For now, just simulate with a delay
      Future.delayed(const Duration(seconds: 2), () {
        state = state.copyWith(isListening: false);
      });
    }
  }

  void resetGame() {
    state = state.copyWith(
      currentWordIndex: 0,
      isFlipped: false,
      score: 0,
      streak: 0,
      gameCompleted: false,
      typingInput: '',
      isListening: false,
      showExample: false,
      selectedAnswer: null,
      timer: 0,
      isTimerRunning: false,
    );
  }

  void changeGameMode(GameMode mode) {
    state = state.copyWith(
      gameMode: mode,
      isTimerRunning: false,
    );
    resetGame();
  }

  void changeDifficulty(GameDifficulty difficulty) {
    int wordCount;
    switch (difficulty) {
      case GameDifficulty.beginner:
        wordCount = 10;
        break;
      case GameDifficulty.intermediate:
        wordCount = 20;
        break;
      case GameDifficulty.advanced:
        wordCount = 30;
        break;
    }

    state = state.copyWith(
      difficulty: difficulty,
      wordCount: wordCount,
      isTimerRunning: false,
    );
    resetGame();
  }

  void toggleTimer() {
    state = state.copyWith(isTimerRunning: !state.isTimerRunning);
  }

  void setShowTranslation(bool show) {
    state = state.copyWith(showTranslation: show);
    _saveSettings();
  }

  void setShowTransliteration(bool show) {
    state = state.copyWith(showTransliteration: show);
    _saveSettings();
  }

  void setAudioEnabled(bool enabled) {
    state = state.copyWith(audioEnabled: enabled);
  }

  double calculateProgress() {
    if (state.studyWords.isEmpty) return 0;
    return (state.currentWordIndex / state.studyWords.length * 100).clamp(0, 100);
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class LearnWordsPage extends ConsumerStatefulWidget {
  const LearnWordsPage({super.key});

  @override
  ConsumerState<LearnWordsPage> createState() => _LearnWordsPageState();
}

class _LearnWordsPageState extends ConsumerState<LearnWordsPage>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _timerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordDataAsync = ref.watch(wordLearningDataProvider);
    final gameState = ref.watch(wordLearningGameProvider);
    final timerValue = ref.watch(timerServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Омӯзиши калимаҳо'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
              } else {
                GoRouter.of(context).go('/');
              }
            } catch (e) {
              GoRouter.of(context).go('/');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatsDialog(context),
          ),
        ],
      ),
      body: wordDataAsync.when(
        data: (words) {
          if (words.isEmpty) {
            return const Center(
              child: Text('Маълумот нест'),
            );
          }

          // Initialize study words if not already done
          if (gameState.studyWords.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(wordLearningGameProvider.notifier).initializeStudyWords(words);
            });
          }

          return _buildGameContent(words, gameState);
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (error, stack) => Center(
          child: CustomErrorWidget(
            message: 'Хатогии боргирӣ: $error',
            onRetry: () => ref.refresh(wordLearningDataProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildGameContent(List<WordLearningModel> words, WordLearningGameState state) {
    final timerValue = ref.watch(timerServiceProvider);
    
    return Column(
      children: [
        // Progress bar
        if (state.gameMode != GameMode.match)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LinearProgressIndicator(
              value: ref.read(wordLearningGameProvider.notifier).calculateProgress() / 100,
            ),
          ),

        // Timer
        if (state.isTimerRunning)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, size: 16),
                const SizedBox(width: 8),
                Text(ref.read(wordLearningGameProvider.notifier).formatTime(timerValue)),
              ],
            ),
          ),

        // Game completion message
        if (state.gameCompleted)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Бозӣ ба охир расид!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Ҳисоб: ${state.score}'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(wordLearningGameProvider.notifier).resetGame();
                        ref.read(wordLearningGameProvider.notifier).initializeStudyWords(words);
                      },
                      child: const Text('Бозӣ оғоз кардан'),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Game content
        if (!state.gameCompleted && state.studyWords.isNotEmpty)
          Expanded(
            child: _buildGameMode(state),
          ),
      ],
    );
  }

  Widget _buildGameMode(WordLearningGameState state) {
    switch (state.gameMode) {
      case GameMode.flashcards:
        return _buildFlashcardsMode(state);
      case GameMode.quiz:
        return _buildQuizMode(state);
      case GameMode.match:
        return _buildMatchMode(state);
      case GameMode.typing:
        return _buildTypingMode(state);
      case GameMode.listening:
        return _buildListeningMode(state);
    }
  }

  Widget _buildFlashcardsMode(WordLearningGameState state) {
    final currentWord = state.studyWords[state.currentWordIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Card
          Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(wordLearningGameProvider.notifier).flipCard();
                _flipController.forward().then((_) {
                  _flipController.reverse();
                });
              },
              child: AnimatedBuilder(
                animation: _flipController,
                builder: (context, child) {
                  final isShowingBack = state.isFlipped;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_flipController.value * math.pi),
                    child: Card(
                      elevation: 8,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24.0),
                        child: isShowingBack
                            ? _buildCardBack(currentWord, state)
                            : _buildCardFront(currentWord, state),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => ref.read(wordLearningGameProvider.notifier).navigateWord('prev'),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Қаблӣ'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(wordLearningGameProvider.notifier).markAsLearned(currentWord.rank);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Калима омӯхта шуд!')),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Омӯхта шуд'),
              ),
              ElevatedButton.icon(
                onPressed: () => ref.read(wordLearningGameProvider.notifier).navigateWord('next'),
                icon: const Icon(Icons.chevron_right),
                label: const Text('Навбатӣ'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront(WordLearningModel word, WordLearningGameState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          word.word,
          style: const TextStyle(
            fontSize: 48,
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Зер кунед то тарҷумаро бинед',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCardBack(WordLearningModel word, WordLearningGameState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          word.word,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (state.showTransliteration)
          Text(
            word.transliterationTajik,
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        if (state.showTransliteration) const SizedBox(height: 8),
        if (state.showTranslation)
          Text(
            word.translationTajik,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        if (state.showExample)
          Column(
            children: [
              Text(
                word.example,
                style: const TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                word.exampleTranslation,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildQuizMode(WordLearningGameState state) {
    final currentWord = state.studyWords[state.currentWordIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Question
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    'Ин калимаро интихоб кунед:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentWord.word,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Options
          Expanded(
            child: ListView.builder(
              itemCount: state.quizOptions.length,
              itemBuilder: (context, index) {
                final option = state.quizOptions[index];
                final isSelected = state.selectedAnswer == index;
                final isCorrect = state.revealAnswers && 
                    option.rank == currentWord.rank;
                final isWrong = state.revealAnswers && 
                    isSelected && 
                    option.rank != currentWord.rank;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  color: isCorrect
                      ? Colors.green.withOpacity(0.1)
                      : isWrong
                          ? Colors.red.withOpacity(0.1)
                          : isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : null,
                  child: ListTile(
                    title: Text(option.translationTajik),
                    subtitle: Text(option.transliterationTajik),
                    onTap: state.revealAnswers
                        ? null
                        : () => ref.read(wordLearningGameProvider.notifier).checkAnswer(index),
                    trailing: isCorrect
                        ? const Icon(Icons.check, color: Colors.green)
                        : isWrong
                            ? const Icon(Icons.close, color: Colors.red)
                            : null,
                  ),
                );
              },
            ),
          ),

          // Next button
          if (state.revealAnswers)
            ElevatedButton(
              onPressed: () => ref.read(wordLearningGameProvider.notifier).navigateWord('next'),
              child: const Text('Навбатӣ'),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchMode(WordLearningGameState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Калимаҳоро бо тарҷумаҳояшон ҷудо кунед',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: state.matchPairs.length,
              itemBuilder: (context, index) {
                final pair = state.matchPairs[index];
                return GestureDetector(
                  onTap: pair.isMatched
                      ? null
                      : () => ref.read(wordLearningGameProvider.notifier).handleMatchSelection(pair.id),
                  child: Card(
                    color: pair.isMatched
                        ? Colors.green.withOpacity(0.2)
                        : pair.isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.2)
                            : null,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          pair.isMatched || pair.id % 2 == 0
                              ? pair.word.word
                              : pair.word.translationTajik,
                          style: TextStyle(
                            fontSize: pair.isMatched || pair.id % 2 == 0 ? 16 : 14,
                            fontFamily: null,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingMode(WordLearningGameState state) {
    final currentWord = state.studyWords[state.currentWordIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Word to translate
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    'Ин калимаро бо тоҷикӣ нависед:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentWord.word,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentWord.transliterationTajik,
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Input field
          TextField(
            onChanged: (value) => ref.read(wordLearningGameProvider.notifier).handleTyping(value),
            decoration: const InputDecoration(
              labelText: 'Ҷавоб',
              hintText: 'Калимаро нависед...',
              border: OutlineInputBorder(),
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 16),

          // Show example button
          ElevatedButton.icon(
            onPressed: () {
              // Toggle example visibility
            },
            icon: const Icon(Icons.help),
            label: const Text('Мисол'),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningMode(WordLearningGameState state) {
    final currentWord = state.studyWords[state.currentWordIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Listen button
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.volume_up,
                    size: 80,
                    color: state.isListening ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Гӯш кунед ва ҷавоб диҳед',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: state.isListening
                        ? null
                        : () => ref.read(wordLearningGameProvider.notifier).handleListening(),
                    icon: Icon(state.isListening ? Icons.volume_up : Icons.play_arrow),
                    label: Text(state.isListening ? 'Гӯш карда истода...' : 'Гӯш кунед'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Answer options (show after listening)
          if (state.isListening)
            Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  'Ҷавоби дурустро интихоб кунед:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                // This would show multiple choice options
                // For now, just show the correct answer
                Card(
                  child: ListTile(
                    title: Text(currentWord.translationTajik),
                    subtitle: Text(currentWord.transliterationTajik),
                    onTap: () {
                      ref.read(wordLearningGameProvider.notifier).markAsLearned(currentWord.rank);
                      ref.read(wordLearningGameProvider.notifier).navigateWord('next');
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  void _showStatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const StatsDialog(),
    );
  }
}

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wordLearningGameProvider);

    return AlertDialog(
      title: const Text('Танзимоти бозӣ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Difficulty selection
            const Text('Сатҳи душворӣ'),
            const SizedBox(height: 8),
            DropdownButton<GameDifficulty>(
              value: state.difficulty,
              isExpanded: true,
              items: GameDifficulty.values.map((difficulty) {
                String label;
                switch (difficulty) {
                  case GameDifficulty.beginner:
                    label = 'Осон (10 калима)';
                    break;
                  case GameDifficulty.intermediate:
                    label = 'Миёна (20 калима)';
                    break;
                  case GameDifficulty.advanced:
                    label = 'Душвор (30 калима)';
                    break;
                }
                return DropdownMenuItem(
                  value: difficulty,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (difficulty) {
                if (difficulty != null) {
                  ref.read(wordLearningGameProvider.notifier).changeDifficulty(difficulty);
                }
              },
            ),

            const SizedBox(height: 16),

            // Game mode selection
            const Text('Намуди бозӣ'),
            const SizedBox(height: 8),
            DropdownButton<GameMode>(
              value: state.gameMode,
              isExpanded: true,
              items: GameMode.values.map((mode) {
                String label;
                switch (mode) {
                  case GameMode.flashcards:
                    label = 'Флешкартаҳо';
                    break;
                  case GameMode.quiz:
                    label = 'Саволу ҷавоб';
                    break;
                  case GameMode.match:
                    label = 'Мувофиқат';
                    break;
                  case GameMode.typing:
                    label = 'Навиштан';
                    break;
                  case GameMode.listening:
                    label = 'Гӯш кардан';
                    break;
                }
                return DropdownMenuItem(
                  value: mode,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(wordLearningGameProvider.notifier).changeGameMode(mode);
                }
              },
            ),

            const SizedBox(height: 16),

            // Timer toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Вақтсанҷ'),
                Switch(
                  value: state.isTimerRunning,
                  onChanged: (value) {
                    ref.read(wordLearningGameProvider.notifier).toggleTimer();
                    if (value) {
                      ref.read(timerServiceProvider.notifier).start();
                    } else {
                      ref.read(timerServiceProvider.notifier).pause();
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Display options
            SwitchListTile(
              title: const Text('Тарҷумаро нишон диҳед'),
              value: state.showTranslation,
              onChanged: (value) {
                ref.read(wordLearningGameProvider.notifier).setShowTranslation(value);
              },
            ),
            SwitchListTile(
              title: const Text('Транслитератсияро нишон диҳед'),
              value: state.showTransliteration,
              onChanged: (value) {
                ref.read(wordLearningGameProvider.notifier).setShowTransliteration(value);
              },
            ),
            SwitchListTile(
              title: const Text('Аудио фаъол аст'),
              value: state.audioEnabled,
              onChanged: (value) {
                ref.read(wordLearningGameProvider.notifier).setAudioEnabled(value);
              },
            ),

            const SizedBox(height: 16),

            // Reset button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(wordLearningGameProvider.notifier).resetGame();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Бозӣ оғоз кардан'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Бас'),
        ),
      ],
    );
  }
}

class StatsDialog extends ConsumerWidget {
  const StatsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wordLearningGameProvider);
    final timerValue = ref.watch(timerServiceProvider);

    return AlertDialog(
      title: const Text('Омори бозӣ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatRow('Ҳисоб', '${state.score}'),
          _buildStatRow('Калимаҳои омӯхта', '${state.wordsLearned.length}'),
          _buildStatRow('Зуҳури ҳозира', '${state.streak}'),
          _buildStatRow('Беҳтарин зуҳур', '${state.bestStreak}'),
          _buildStatRow('Вақт', ref.read(wordLearningGameProvider.notifier).formatTime(timerValue)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Бас'),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}