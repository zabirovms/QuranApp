import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../../../data/models/tasbeeh_model.dart';
import '../../../data/datasources/local/json_data_source.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';

// Providers
final tasbeehDataProvider = FutureProvider<List<TasbeehModel>>((ref) async {
  final jsonDataSource = JsonDataSource();
  return await jsonDataSource.getTasbeehData();
});

final tasbeehSettingsProvider = StateNotifierProvider<TasbeehSettingsNotifier, TasbeehSettings>((ref) => TasbeehSettingsNotifier());

// Settings model
class TasbeehSettings {
  final int currentTasbeehIndex;
  final int count;
  final int targetCount;
  final bool vibrationEnabled;
  final bool saveHistory;
  final int completedTasbeehs;

  TasbeehSettings({
    this.currentTasbeehIndex = 0,
    this.count = 0,
    this.targetCount = 33,
    this.vibrationEnabled = true,
    this.saveHistory = true,
    this.completedTasbeehs = 0,
  });

  TasbeehSettings copyWith({
    int? currentTasbeehIndex,
    int? count,
    int? targetCount,
    bool? vibrationEnabled,
    bool? saveHistory,
    int? completedTasbeehs,
  }) {
    return TasbeehSettings(
      currentTasbeehIndex: currentTasbeehIndex ?? this.currentTasbeehIndex,
      count: count ?? this.count,
      targetCount: targetCount ?? this.targetCount,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      saveHistory: saveHistory ?? this.saveHistory,
      completedTasbeehs: completedTasbeehs ?? this.completedTasbeehs,
    );
  }
}

// Settings notifier
class TasbeehSettingsNotifier extends StateNotifier<TasbeehSettings> {
  TasbeehSettingsNotifier() : super(TasbeehSettings()) {
    _loadSettings();
  }

  static const String _keyCurrentTasbeehIndex = 'tasbeeh_current_index';
  static const String _keyCount = 'tasbeeh_count';
  static const String _keyTargetCount = 'tasbeeh_target_count';
  static const String _keyVibrationEnabled = 'tasbeeh_vibration_enabled';
  static const String _keySaveHistory = 'tasbeeh_save_history';
  static const String _keyCompletedTasbeehs = 'tasbeeh_completed_count';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    state = state.copyWith(
      currentTasbeehIndex: prefs.getInt(_keyCurrentTasbeehIndex) ?? 0,
      count: prefs.getInt(_keyCount) ?? 0,
      targetCount: prefs.getInt(_keyTargetCount) ?? 33,
      vibrationEnabled: prefs.getBool(_keyVibrationEnabled) ?? true,
      saveHistory: prefs.getBool(_keySaveHistory) ?? true,
      completedTasbeehs: prefs.getInt(_keyCompletedTasbeehs) ?? 0,
    );
  }

  Future<void> _saveSettings() async {
    if (!state.saveHistory) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentTasbeehIndex, state.currentTasbeehIndex);
    await prefs.setInt(_keyCount, state.count);
    await prefs.setInt(_keyTargetCount, state.targetCount);
    await prefs.setBool(_keyVibrationEnabled, state.vibrationEnabled);
    await prefs.setBool(_keySaveHistory, state.saveHistory);
    await prefs.setInt(_keyCompletedTasbeehs, state.completedTasbeehs);
  }

  void updateCurrentTasbeehIndex(int index) {
    state = state.copyWith(currentTasbeehIndex: index, count: 0);
    _saveSettings();
  }

  void incrementCount() {
    final newCount = state.count + 1;
    state = state.copyWith(count: newCount);
    _saveSettings();
  }

  void resetCount() {
    state = state.copyWith(count: 0);
    _saveSettings();
  }

  void setTargetCount(int targetCount) {
    state = state.copyWith(targetCount: targetCount);
    _saveSettings();
  }

  void setVibrationEnabled(bool enabled) {
    state = state.copyWith(vibrationEnabled: enabled);
    _saveSettings();
  }

  void setSaveHistory(bool saveHistory) {
    state = state.copyWith(saveHistory: saveHistory);
    _saveSettings();
  }

  void incrementCompletedTasbeehs() {
    state = state.copyWith(
      completedTasbeehs: state.completedTasbeehs + 1,
      count: 0,
    );
    _saveSettings();
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentTasbeehIndex);
    await prefs.remove(_keyCount);
    await prefs.remove(_keyCompletedTasbeehs);
    
    state = state.copyWith(
      currentTasbeehIndex: 0,
      count: 0,
      completedTasbeehs: 0,
      saveHistory: true,
    );
    _saveSettings();
  }
}

class TasbeehPage extends ConsumerStatefulWidget {
  const TasbeehPage({super.key});

  @override
  ConsumerState<TasbeehPage> createState() => _TasbeehPageState();
}

class _TasbeehPageState extends ConsumerState<TasbeehPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  PageController? _tasbeehSelectorController;
  int _currentTabIndex = 0;
  int _lastVibrationTime = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();
    _tasbeehSelectorController = PageController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _tasbeehSelectorController?.dispose();
    super.dispose();
  }

  void _incrementCount() {
    final settings = ref.read(tasbeehSettingsProvider);
    
    // Haptic feedback
    if (settings.vibrationEnabled) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastVibrationTime > 100) {
        HapticFeedback.lightImpact();
        _lastVibrationTime = now;
      }
    }

    ref.read(tasbeehSettingsProvider.notifier).incrementCount();
    
    // Check if target reached
    if (settings.count + 1 >= settings.targetCount) {
      ref.read(tasbeehSettingsProvider.notifier).incrementCompletedTasbeehs();
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => const CompletionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasbeehDataAsync = ref.watch(tasbeehDataProvider);
    final settings = ref.watch(tasbeehSettingsProvider);

    return Scaffold(
        appBar: AppBar(
          title: const Text('Зикрҳои исломӣ'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
              } else {
                GoRouter.of(context).go('/');
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsDialog(context),
            ),
          ],
        ),
         body: tasbeehDataAsync.when(
           data: (tasbeehs) => _buildContent(tasbeehs, settings),
           loading: () => const Center(child: LoadingWidget()),
           error: (error, stack) => Center(
             child: CustomErrorWidget(
               message: 'Хатогии боргирӣ: $error',
               onRetry: () => ref.refresh(tasbeehDataProvider),
             ),
           ),
         ),
         bottomNavigationBar: BottomNavigationBar(
           type: BottomNavigationBarType.fixed,
           currentIndex: _currentTabIndex,
           onTap: (index) {
             setState(() {
               _currentTabIndex = index;
             });
             _pageController.animateToPage(
               index,
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeInOut,
             );
           },
           items: const [
             BottomNavigationBarItem(
               icon: Icon(Icons.timer),
               label: 'Тасбеҳгӯяк',
             ),
             BottomNavigationBarItem(
               icon: Icon(Icons.book),
               label: 'Зикрҳо',
             ),
           ],
         ),
     );
  }

  Widget _buildContent(List<TasbeehModel> tasbeehs, TasbeehSettings settings) {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentTabIndex = index;
        });
        _tabController.animateTo(index);
      },
      children: [
        _buildCounterTab(tasbeehs, settings),
        _buildCollectionTab(tasbeehs, settings),
      ],
    );
  }

  Widget _buildCounterTab(List<TasbeehModel> tasbeehs, TasbeehSettings settings) {
    final currentTasbeeh = tasbeehs.isNotEmpty 
        ? tasbeehs[settings.currentTasbeehIndex] 
        : null;

    if (currentTasbeeh == null) {
      return const Center(child: Text('Маълумот нест'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
           // Tasbeeh selector
           SizedBox(
             height: 150,
             child: PageView.builder(
               controller: _tasbeehSelectorController,
               onPageChanged: (index) {
                 ref.read(tasbeehSettingsProvider.notifier)
                     .updateCurrentTasbeehIndex(index);
               },
               itemCount: tasbeehs.length,
               itemBuilder: (context, index) {
                 final tasbeeh = tasbeehs[index];
                 final isSelected = index == settings.currentTasbeehIndex;
                 final isDark = Theme.of(context).brightness == Brightness.dark;
                 final progressColor = isDark
                     ? const Color.fromARGB(255, 59, 104, 69) // bright color for dark mode
                     : Theme.of(context).primaryColor;
                 
                 return Card(
                   margin: const EdgeInsets.symmetric(horizontal: 8.0),
                   elevation: isSelected ? 4 : 1,
                   child: Container(
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                         colors: isSelected ? [
                           progressColor.withOpacity(0.2),
                           progressColor.withOpacity(0.3),
                         ] : [
                           progressColor.withOpacity(0.1),
                           progressColor.withOpacity(0.2),
                         ],
                       ),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(
                         color: isSelected 
                             ? progressColor.withOpacity(0.6)
                             : progressColor.withOpacity(0.3),
                         width: isSelected ? 2 : 1,
                       ),
                     ),
                     child: SingleChildScrollView(
                       padding: const EdgeInsets.all(16.0),
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text(
                             tasbeeh.arabic,
                             style: const TextStyle(
                               fontSize: 24,
                             ),
                             textAlign: TextAlign.center,
                           ),
                           const SizedBox(height: 8),
                           Text(
                             tasbeeh.tajikTransliteration,
                             style: TextStyle(
                               fontSize: 16,
                               color: const Color.fromARGB(221, 168, 167, 167),
                               fontWeight: FontWeight.w600,
                             ),
                             textAlign: TextAlign.center,
                           ),
                           const SizedBox(height: 4),
                           Text(
                             tasbeeh.tajikTranslation,
                             style: TextStyle(
                               fontSize: 14,
                               color: Theme.of(context).textTheme.bodySmall?.color,
                             ),
                             textAlign: TextAlign.center,
                           ),
                         ],
                       ),
                     ),
                   ),
                 );
               },
             ),
           ),
          
          const SizedBox(height: 16),
          
          // Counter info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Шумораи хатм: ${settings.completedTasbeehs}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.read(tasbeehSettingsProvider.notifier).resetCount();
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Counter circle
          Expanded(
            child: GestureDetector(
              onTap: _incrementCount,
              child: Center(
                child: Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final progressColor = isDark
                        ? const Color.fromARGB(255, 59, 104, 69) // bright color for dark mode
                        : Theme.of(context).primaryColor;

                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            progressColor.withOpacity(0.3),
                            progressColor.withOpacity(0.5),
                          ],
                        ),
                        border: Border.all(
                          color: progressColor.withOpacity(0.6),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: const Size(200, 200),
                            painter: ProgressCirclePainter(
                              progress: settings.count / settings.targetCount,
                              color: progressColor,
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    '${settings.count}',
                                    key: ValueKey(settings.count),
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white, // ensure visible on dark
                                    ),
                                  ),
                                ),
                                Text(
                                  'аз ${settings.targetCount}',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Inside _buildCollectionTab ---
Widget _buildCollectionTab(List<TasbeehModel> tasbeehs, TasbeehSettings settings) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: tasbeehs.length,
            itemBuilder: (context, index) {
              final tasbeeh = tasbeehs[index];
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final progressColor = isDark
                  ? const Color.fromARGB(255, 59, 104, 69) // bright color for dark mode
                  : Theme.of(context).primaryColor;
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        progressColor.withOpacity(0.1),
                        progressColor.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: progressColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          tasbeeh.arabic,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tasbeeh.tajikTransliteration,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodySmall?.color, // same as translation
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tasbeeh.tajikTranslation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                         SizedBox(
                           width: double.infinity,
                           child: OutlinedButton(
                             onPressed: () {
                               ref.read(tasbeehSettingsProvider.notifier).updateCurrentTasbeehIndex(index);
                                   
                                   // Switch to counter tab first
                                   _tabController.animateTo(0);
                                   _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                   
                                   // Wait until the tab switch is complete, THEN jump to the specific dhikr
                                   Future.delayed(const Duration(milliseconds: 350), () {
                                     if (_tasbeehSelectorController?.hasClients == true) {
                                       _tasbeehSelectorController!.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                     }
                                   });
                                 },                   
                                 child: const Text('Шуморидан', style: TextStyle(fontSize: 16)),
                           ),
                         ),
                      ],
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

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }
}

class ProgressCirclePainter extends CustomPainter {
  final double progress;
  final Color color;

  ProgressCirclePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CompletionDialog extends ConsumerWidget {
  const CompletionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(tasbeehSettingsProvider);
    final tasbeehDataAsync = ref.watch(tasbeehDataProvider);
    
    return AlertDialog(
      title: Column(
        children: [
          const Text('✨ Тасбеҳ пурра шуд ✨'),
          Text(
            'Шумо ${settings.targetCount} маротиба ин зикрро хондед',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      content: tasbeehDataAsync.when(
        data: (tasbeehs) {
          if (tasbeehs.isEmpty) return const SizedBox.shrink();
          final currentTasbeeh = tasbeehs[settings.currentTasbeehIndex];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentTasbeeh.arabic,
                style: const TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                currentTasbeeh.tajikTransliteration,
                style: TextStyle(fontSize: 16, color: const Color.fromARGB(221, 37, 36, 36)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                currentTasbeeh.tajikTranslation,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Идома додан'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Мубодила карда шуд')),
            );
          },
          icon: const Icon(Icons.share),
          label: const Text('Мубодила'),
        ),
      ],
    );
  }
}

// --- Updated SettingsDialog ---
class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(tasbeehSettingsProvider);
    final availableTargetCounts = [33, 99, 100, 500];

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Танзимот', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              SwitchListTile(
                subtitle: const Text('Ларзиши телефон ҳангоми зер кардан'),
                value: settings.vibrationEnabled,
                onChanged: (value) {
                  ref.read(tasbeehSettingsProvider.notifier)
                      .setVibrationEnabled(value);
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Ҳадаф', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableTargetCounts.map((count) {
                  final isSelected = settings.targetCount == count;
                  return ChoiceChip(
                    label: Text('$count'),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(tasbeehSettingsProvider.notifier)
                          .setTargetCount(count);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                subtitle: const Text('Нигоҳдории шумора ва танзимот'),
                value: settings.saveHistory,
                onChanged: (value) {
                  ref.read(tasbeehSettingsProvider.notifier)
                      .setSaveHistory(value);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(tasbeehSettingsProvider.notifier).resetAll();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ҳамаи маълумот тоза карда шуд')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.8),
                  ),
                  child: const Text('Тоза кардани ҳамаи маълумот', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Пӯшидан'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
