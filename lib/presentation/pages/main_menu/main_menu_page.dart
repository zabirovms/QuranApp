import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

import '../../providers/verse_of_day_provider.dart';
import '../../providers/dua_of_day_provider.dart';
import '../../providers/quran_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/user_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../data/models/verse_model.dart';
import '../../../data/models/dua_model.dart';

class MainMenuPage extends ConsumerWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final hasAnyBookmarks = ref.watch(bookmarkNotifierProvider(userId)).bookmarks.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Қуръон бо Тафсири Осонбаён'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
            tooltip: 'Ҷустуҷӯ',
          ),
          IconButton(
            icon: Icon(hasAnyBookmarks ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => context.push('/bookmarks'),
            tooltip: 'Захираҳо',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Танзимот',
          ),
        ],
      ),
      body: const _HomeScreen(),
    );
  }
}

// Home Screen - Main Menu Content
class _HomeScreen extends ConsumerWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseOfDayAsync = ref.watch(verseOfDayProvider);
    final duaOfDayAsync = ref.watch(duaOfDayProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verse of the day section
            verseOfDayAsync.when(
              data: (result) => _VerseOfDayCard(
                verse: result.verse,
                surahNumber: result.surahNumber,
                onTap: () {
                  context.push('/surah/${result.surahNumber}/verse/${result.verse.verseNumber}');
                },
              ),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: LoadingCircularWidget(),
                ),
              ),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            
            // Featured surahs section
            _FeaturedSurahsWidget(),
            const SizedBox(height: 24),
            
            // Main menu items
            Text(
              'Менюи асосӣ',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            // Menu grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _MenuCard(
                  title: 'Тасбеҳ',
                  icon: FlutterIslamicIcons.tasbih,
                  color: Colors.blue,
                  onTap: () => context.push('/tasbeeh'),
                ),
                _MenuCard(
                  title: 'Дуоҳо',
                  icon: FlutterIslamicIcons.prayer,
                  color: Colors.purple,
                  onTap: () => context.push('/duas'),
                ),
                _MenuCard(
                  title: 'Пайғамбарон',
                  icon: Icons.person,
                  color: Colors.teal,
                  onTap: () => context.push('/prophets'),
                ),
                _MenuCard(
                  title: 'Асмоул Ҳусно',
                  icon: Icons.star,
                  color: Colors.indigo,
                  onTap: () => context.push('/asmaul-husna'),
                ),
                _MenuCard(
                  title: 'Омӯхтани калимаҳо',
                  icon: Icons.school,
                  color: Colors.orange,
                  onTap: () => context.push('/learn-words'),
                ),
                _MenuCard(
                  title: 'Маккаи Мукаррама',
                  icon: Icons.live_tv,
                  color: Colors.red,
                  onTap: () => context.push('/live-makkah'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Dua of the day section
            duaOfDayAsync.when(
              data: (dua) => _DuaOfDayCard(
                dua: dua,
                onTap: () {
                  context.push('/duas/rabbano');
                },
              ),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: LoadingCircularWidget(),
                ),
              ),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FeaturedSurahsWidget extends StatelessWidget {
  const _FeaturedSurahsWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final featuredSurahs = [
      _FeaturedSurah(name: 'Сураи Ал-Каҳф', surahNumber: 18, isVerse: false),
      _FeaturedSurah(name: 'Оят-ал-Курси', surahNumber: 2, verseNumber: 255, isVerse: true),
      _FeaturedSurah(name: 'Сураи Ёсин', surahNumber: 36, isVerse: false),
      _FeaturedSurah(name: 'Сураи Ал-Мулк', surahNumber: 67, isVerse: false),
      _FeaturedSurah(name: 'Сураи Ар-Раҳмон', surahNumber: 55, isVerse: false),
      _FeaturedSurah(name: 'Сураи Ал-Ҷумъа', surahNumber: 62, isVerse: false),
      _FeaturedSurah(name: 'Сураи Ал-Ҳашр', surahNumber: 59, isVerse: false),
      _FeaturedSurah(name: 'Сураи Ал-Фотиҳа', surahNumber: 1, isVerse: false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Сураҳои машҳур',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemCount: featuredSurahs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final surah = featuredSurahs[index];
              return _FeaturedSurahCard(
                name: surah.name,
                surahNumber: surah.surahNumber,
                verseNumber: surah.verseNumber,
                isVerse: surah.isVerse,
                onTap: () {
                  if (surah.isVerse && surah.verseNumber != null) {
                    context.push('/surah/${surah.surahNumber}/verse/${surah.verseNumber}');
                  } else {
                    context.push('/surah/${surah.surahNumber}');
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedSurah {
  final String name;
  final int surahNumber;
  final int? verseNumber;
  final bool isVerse;

  _FeaturedSurah({
    required this.name,
    required this.surahNumber,
    this.verseNumber,
    required this.isVerse,
  });
}

class _FeaturedSurahCard extends StatelessWidget {
  final String name;
  final int surahNumber;
  final int? verseNumber;
  final bool isVerse;
  final VoidCallback onTap;

  const _FeaturedSurahCard({
    required this.name,
    required this.surahNumber,
    this.verseNumber,
    required this.isVerse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 160,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.1),
                  theme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$surahNumber',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerseOfDayCard extends ConsumerWidget {
  final VerseModel verse;
  final int surahNumber;
  final VoidCallback onTap;

  const _VerseOfDayCard({
    required this.verse,
    required this.surahNumber,
    required this.onTap,
  });

  String _getSurahName(int surahNumber) {
    final surahNames = {
      1: 'Ал-Фотиҳа', 2: 'Ал-Бақара', 3: 'Оли Имрон', 4: 'Ан-Нисо', 5: 'Ал-Маида',
      6: 'Ал-Анъом', 7: 'Ал-Аъроф', 8: 'Ал-Анфол', 9: 'Ат-Тавба', 10: 'Юнус',
      11: 'Ҳуд', 12: 'Юсуф', 13: 'Ар-Раъд', 14: 'Иброҳим', 15: 'Ал-Ҳиҷр',
      16: 'Ан-Наҳл', 17: 'Ал-Исро', 18: 'Ал-Каҳф', 19: 'Марям', 20: 'Тоҳо',
      21: 'Ал-Анбиё', 22: 'Ал-Ҳаҷҷ', 23: 'Ал-Муъминун', 24: 'Ан-Нур', 25: 'Ал-Фурқон',
      26: 'Аш-Шуъаро', 27: 'Ан-Намл', 28: 'Ал-Қасас', 29: 'Ал-Анкабут', 30: 'Ар-Рум',
      31: 'Луқмон', 32: 'Ас-Саҷда', 33: 'Ал-Аҳзоб', 34: 'Сабаъ', 35: 'Фотир',
      36: 'Ясин', 37: 'Ас-Соффот', 38: 'Сод', 39: 'Аз-Зумар', 40: 'Ғофир',
      41: 'Фуссилат', 42: 'Аш-Шуро', 43: 'Аз-Зухруф', 44: 'Ад-Духон', 45: 'Ал-Ҷосия',
      46: 'Ал-Аҳқоф', 47: 'Муҳаммад', 48: 'Ал-Фатҳ', 49: 'Ал-Ҳуҷурот', 50: 'Қоф',
      51: 'Аз-Зориёт', 52: 'Ат-Тур', 53: 'Ан-Наҷм', 54: 'Ал-Қамар', 55: 'Ар-Раҳмон',
      56: 'Ал-Воқиа', 57: 'Ал-Ҳадид', 58: 'Ал-Муҷодала', 59: 'Ал-Ҳашр', 60: 'Ал-Мумтаҳана',
      61: 'Ас-Сафф', 62: 'Ал-Ҷумъа', 63: 'Ал-Мунофиқун', 64: 'Ат-Тағобун', 65: 'Ат-Талақ',
      66: 'Ат-Таҳрим', 67: 'Ал-Мулк', 68: 'Ал-Қалам', 69: 'Ал-Ҳоққа', 70: 'Ал-Маъориҷ',
      71: 'Нуҳ', 72: 'Ал-Ҷинн', 73: 'Ал-Муззаммил', 74: 'Ал-Муддассир', 75: 'Ал-Қиёма',
      76: 'Ал-Инсон', 77: 'Ал-Мурсалот', 78: 'Ан-Набоъ', 79: 'Ан-Назиъот', 80: 'Абаса',
      81: 'Ат-Таквир', 82: 'Ал-Инфитор', 83: 'Ал-Мутоффифин', 84: 'Ал-Иншиқоқ', 85: 'Ал-Буруҷ',
      86: 'Ат-Ториқ', 87: 'Ал-Аъло', 88: 'Ал-Ғошия', 89: 'Ал-Фаҷр', 90: 'Ал-Балад',
      91: 'Аш-Шамс', 92: 'Ал-Лайл', 93: 'Аз-Зуҳо', 94: 'Ал-Иншироҳ', 95: 'Ат-Тин',
      96: 'Ал-Алақ', 97: 'Ал-Қадр', 98: 'Ал-Байина', 99: 'Аз-Залзала', 100: 'Ал-Одиёт',
      101: 'Ал-Қориа', 102: 'Ат-Такосур', 103: 'Ал-Аср', 104: 'Ал-Ҳумаза', 105: 'Ал-Фил',
      106: 'Қурайш', 107: 'Ал-Маъун', 108: 'Ал-Кавсар', 109: 'Ал-Кофирун', 110: 'Ан-Наср',
      111: 'Ал-Масад', 112: 'Ал-Ихлос', 113: 'Ал-Фалақ', 114: 'Ан-Нас',
    };
    return surahNames[surahNumber] ?? 'Сураи $surahNumber';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahProvider(surahNumber));
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.1),
                theme.primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    FlutterIslamicIcons.quran,
                    size: 24,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ояти рӯз',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Arabic verse - right aligned
              Directionality(
                textDirection: TextDirection.rtl,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    verse.arabicText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'Amiri',
                      fontSize: 22,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              // Translation (Tajik only) - no spacing
              Text(
                verse.tajikText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              // Reference - format: Сураи Фотиҳа 1:5
              surahAsync.when(
                data: (surah) => Text(
                  'Сураи ${surah?.nameTajik ?? _getSurahName(surahNumber)} $surahNumber:${verse.verseNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => Text(
                  'Сураи ${_getSurahName(surahNumber)} $surahNumber:${verse.verseNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Navigation button at bottom
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: Icon(
                    Icons.arrow_forward,
                    color: theme.primaryColor,
                    size: 18,
                  ),
                  label: Text(
                    'Ба сура',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DuaOfDayCard extends ConsumerWidget {
  final DuaModel dua;
  final VoidCallback onTap;

  const _DuaOfDayCard({
    required this.dua,
    required this.onTap,
  });

  String _getSurahName(int surahNumber) {
    final surahNames = {
      1: 'Ал-Фотиҳа', 2: 'Ал-Бақара', 3: 'Оли Имрон', 4: 'Ан-Нисо', 5: 'Ал-Маида',
      6: 'Ал-Анъом', 7: 'Ал-Аъроф', 8: 'Ал-Анфол', 9: 'Ат-Тавба', 10: 'Юнус',
      11: 'Ҳуд', 12: 'Юсуф', 13: 'Ар-Раъд', 14: 'Иброҳим', 15: 'Ал-Ҳиҷр',
      16: 'Ан-Наҳл', 17: 'Ал-Исро', 18: 'Ал-Каҳф', 19: 'Марям', 20: 'Тоҳо',
      21: 'Ал-Анбиё', 22: 'Ал-Ҳаҷҷ', 23: 'Ал-Муъминун', 24: 'Ан-Нур', 25: 'Ал-Фурқон',
      26: 'Аш-Шуъаро', 27: 'Ан-Намл', 28: 'Ал-Қасас', 29: 'Ал-Анкабут', 30: 'Ар-Рум',
      31: 'Луқмон', 32: 'Ас-Саҷда', 33: 'Ал-Аҳзоб', 34: 'Сабаъ', 35: 'Фотир',
      36: 'Ясин', 37: 'Ас-Соффот', 38: 'Сод', 39: 'Аз-Зумар', 40: 'Ғофир',
      41: 'Фуссилат', 42: 'Аш-Шуро', 43: 'Аз-Зухруф', 44: 'Ад-Духон', 45: 'Ал-Ҷосия',
      46: 'Ал-Аҳқоф', 47: 'Муҳаммад', 48: 'Ал-Фатҳ', 49: 'Ал-Ҳуҷурот', 50: 'Қоф',
      51: 'Аз-Зориёт', 52: 'Ат-Тур', 53: 'Ан-Наҷм', 54: 'Ал-Қамар', 55: 'Ар-Раҳмон',
      56: 'Ал-Воқиа', 57: 'Ал-Ҳадид', 58: 'Ал-Муҷодала', 59: 'Ал-Ҳашр', 60: 'Ал-Мумтаҳана',
      61: 'Ас-Сафф', 62: 'Ал-Ҷумъа', 63: 'Ал-Мунофиқун', 64: 'Ат-Тағобун', 65: 'Ат-Талақ',
      66: 'Ат-Таҳрим', 67: 'Ал-Мулк', 68: 'Ал-Қалам', 69: 'Ал-Ҳоққа', 70: 'Ал-Маъориҷ',
      71: 'Нуҳ', 72: 'Ал-Ҷинн', 73: 'Ал-Муззаммил', 74: 'Ал-Муддассир', 75: 'Ал-Қиёма',
      76: 'Ал-Инсон', 77: 'Ал-Мурсалот', 78: 'Ан-Набоъ', 79: 'Ан-Назиъот', 80: 'Абаса',
      81: 'Ат-Таквир', 82: 'Ал-Инфитор', 83: 'Ал-Мутоффифин', 84: 'Ал-Иншиқоқ', 85: 'Ал-Буруҷ',
      86: 'Ат-Ториқ', 87: 'Ал-Аъло', 88: 'Ал-Ғошия', 89: 'Ал-Фаҷр', 90: 'Ал-Балад',
      91: 'Аш-Шамс', 92: 'Ал-Лайл', 93: 'Аз-Зуҳо', 94: 'Ал-Иншироҳ', 95: 'Ат-Тин',
      96: 'Ал-Алақ', 97: 'Ал-Қадр', 98: 'Ал-Байина', 99: 'Аз-Залзала', 100: 'Ал-Одиёт',
      101: 'Ал-Қориа', 102: 'Ат-Такосур', 103: 'Ал-Аср', 104: 'Ал-Ҳумаза', 105: 'Ал-Фил',
      106: 'Қурайш', 107: 'Ал-Маъун', 108: 'Ал-Кавсар', 109: 'Ал-Кофирун', 110: 'Ан-Наср',
      111: 'Ал-Масад', 112: 'Ал-Ихлос', 113: 'Ал-Фалақ', 114: 'Ан-Нас',
    };
    return surahNames[surahNumber] ?? 'Сураи $surahNumber';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahProvider(dua.surah));
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.1),
                theme.primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    FlutterIslamicIcons.prayer,
                    size: 24,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Дуои рӯз',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Arabic dua - right aligned
              Directionality(
                textDirection: TextDirection.rtl,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    dua.arabic,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'Amiri',
                      fontSize: 22,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              // Translation (Tajik only) - no spacing
              Text(
                dua.tajik,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              // Reference - format: Сураи Фотиҳа 1:5
              surahAsync.when(
                data: (surah) => Text(
                  'Сураи ${surah?.nameTajik ?? _getSurahName(dua.surah)} ${dua.surah}:${dua.verse}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => Text(
                  'Сураи ${_getSurahName(dua.surah)} ${dua.surah}:${dua.verse}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Navigation button at bottom
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: Icon(
                    Icons.arrow_forward,
                    color: theme.primaryColor,
                    size: 18,
                  ),
                  label: Text(
                    'Ба дуоҳо',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
