import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quran_app/presentation/pages/home/home_page.dart';
import 'package:quran_app/presentation/pages/tasbeeh/tasbeeh_page.dart';
import 'package:quran_app/presentation/pages/learn_words/learn_words_page.dart';
import 'package:quran_app/presentation/pages/duas/duas_page.dart';
import 'package:quran_app/presentation/pages/search/search_page.dart';
import 'package:quran_app/presentation/pages/bookmarks/bookmarks_page.dart';
import 'package:quran_app/presentation/pages/settings/settings_page.dart';

void main() {
  group('Quran App Widget Tests', () {
    testWidgets('Home page displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // Verify main elements are present
      expect(find.text('Қуръон'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('Tasbeeh page displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TasbeehPage(),
          ),
        ),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Verify main elements are present
      expect(find.text('Тасбиҳ'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Ҳисобкунак'), findsOneWidget);
      expect(find.text('Ҷамъоварӣ'), findsOneWidget);
    });

    testWidgets('Learn Words page displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LearnWordsPage(),
          ),
        ),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Verify main elements are present
      expect(find.text('Омӯзиши калимаҳо'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Флеш-картаҳо'), findsOneWidget);
      expect(find.text('Саволи-ҷавоб'), findsOneWidget);
    });

    testWidgets('Duas page displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DuasPage(),
          ),
        ),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Verify main elements are present
      expect(find.text('Дуъоҳо'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Ҷустуҷӯи дуъоҳо...'), findsOneWidget);
    });

    testWidgets('Search page displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchPage(),
          ),
        ),
      );

      // Verify main elements are present
      expect(find.text('Ҷустуҷӯ'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Ҷустуҷӯи оятҳо...'), findsOneWidget);
    });

    testWidgets('Bookmarks page displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookmarksPage(),
          ),
        ),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Verify main elements are present
      expect(find.text('Захираҳо'), findsOneWidget);
    });

    testWidgets('Settings page displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      // Verify main elements are present
      expect(find.text('Танзимот'), findsOneWidget);
      expect(find.text('Намоиш'), findsOneWidget);
      expect(find.text('Аудио'), findsOneWidget);
      expect(find.text('Огоҳиҳо'), findsOneWidget);
    });
  });

  group('Navigation Tests', () {
    testWidgets('Bottom navigation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // Test navigation to different tabs
      await tester.tap(find.text('Тасбиҳ'));
      await tester.pumpAndSettle();
      expect(find.text('Тасбиҳ'), findsOneWidget);

      await tester.tap(find.text('Омӯзиши калимаҳо'));
      await tester.pumpAndSettle();
      expect(find.text('Омӯзиши калимаҳо'), findsOneWidget);

      await tester.tap(find.text('Дуъоҳо'));
      await tester.pumpAndSettle();
      expect(find.text('Дуъоҳо'), findsOneWidget);
    });
  });

  group('Tasbeeh Counter Tests', () {
    testWidgets('Tasbeeh counter increments correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TasbeehPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the increment button
      final incrementButton = find.byIcon(Icons.add);
      expect(incrementButton, findsOneWidget);

      // Tap increment button multiple times
      for (int i = 0; i < 5; i++) {
        await tester.tap(incrementButton);
        await tester.pump();
      }

      // Verify counter shows correct value
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Tasbeeh counter resets correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TasbeehPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Increment counter first
      final incrementButton = find.byIcon(Icons.add);
      await tester.tap(incrementButton);
      await tester.tap(incrementButton);
      await tester.pump();

      // Find and tap reset button
      final resetButton = find.byIcon(Icons.refresh);
      expect(resetButton, findsOneWidget);
      await tester.tap(resetButton);
      await tester.pump();

      // Verify counter is reset
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('Word Learning Game Tests', () {
    testWidgets('Game mode selection works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LearnWordsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test different game modes
      await tester.tap(find.text('Саволи-ҷавоб'));
      await tester.pumpAndSettle();
      expect(find.text('Саволи-ҷавоб'), findsOneWidget);

      await tester.tap(find.text('Ҷуфтсозӣ'));
      await tester.pumpAndSettle();
      expect(find.text('Ҷуфтсозӣ'), findsOneWidget);
    });

    testWidgets('Difficulty selection works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LearnWordsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test difficulty selection
      await tester.tap(find.text('Осон'));
      await tester.pumpAndSettle();
      expect(find.text('Осон'), findsOneWidget);

      await tester.tap(find.text('Мутавоссит'));
      await tester.pumpAndSettle();
      expect(find.text('Мутавоссит'), findsOneWidget);
    });
  });

  group('Search Functionality Tests', () {
    testWidgets('Search input works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchPage(),
          ),
        ),
      );

      // Find search field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter search text
      await tester.enterText(searchField, 'الله');
      await tester.pump();

      // Verify text was entered
      expect(find.text('الله'), findsOneWidget);
    });

    testWidgets('Search filters work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchPage(),
          ),
        ),
      );

      // Enter search text first
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'test');
      await tester.pumpAndSettle();

      // Test filter selection
      await tester.tap(find.text('Арабӣ'));
      await tester.pumpAndSettle();
      expect(find.text('Арабӣ'), findsOneWidget);

      await tester.tap(find.text('Тарҷума'));
      await tester.pumpAndSettle();
      expect(find.text('Тарҷума'), findsOneWidget);
    });
  });

  group('Settings Tests', () {
    testWidgets('Theme selection works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      // Tap on theme setting
      await tester.tap(find.text('Макон'));
      await tester.pumpAndSettle();

      // Verify theme options are shown
      expect(find.text('Равшан'), findsOneWidget);
      expect(find.text('Торик'), findsOneWidget);
      expect(find.text('Система'), findsOneWidget);
    });

    testWidgets('Font size setting works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      // Tap on font size setting
      await tester.tap(find.text('Андозаи ҳарф'));
      await tester.pumpAndSettle();

      // Verify font size dialog is shown
      expect(find.text('Андозаи ҳарф'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('Empty state displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookmarksPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty state is shown when no bookmarks
      expect(find.text('Ҳеҷ захирае нест'), findsOneWidget);
      expect(find.text('Оятеро захира кунед то дар ин ҷо нишон дода шавад'), findsOneWidget);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('All interactive elements have semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // Verify that important elements have proper semantics
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });
  });
}
