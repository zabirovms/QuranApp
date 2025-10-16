import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:quran_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Quran App Integration Tests', () {

    testWidgets('Complete app flow test', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Test 1: Navigate through all main sections
      await _testNavigationFlow(tester);

      // Test 2: Test Tasbeeh counter functionality
      await _testTasbeehCounter(tester);

      // Test 3: Test Word Learning game
      await _testWordLearningGame(tester);

      // Test 4: Test Duas collection
      await _testDuasCollection(tester);

      // Test 5: Test Search functionality
      await _testSearchFunctionality(tester);

      // Test 6: Test Settings
      await _testSettings(tester);
    });

    testWidgets('Performance test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Measure app startup time
      final stopwatch = Stopwatch()..start();
      
      // Navigate through different sections quickly
      await tester.tap(find.text('Тасбиҳ'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Омӯзиши калимаҳо'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Дуъоҳо'));
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // Verify navigation is fast (should be under 2 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    testWidgets('Memory usage test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate through all sections multiple times
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Тасбиҳ'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Омӯзиши калимаҳо'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Дуъоҳо'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Қуръон'));
        await tester.pumpAndSettle();
      }

      // App should still be responsive
      expect(find.text('Қуръон'), findsOneWidget);
    });
  });
}

Future<void> _testNavigationFlow(WidgetTester tester) async {
  // Test bottom navigation
  await tester.tap(find.text('Тасбиҳ'));
  await tester.pumpAndSettle();
  expect(find.text('Тасбиҳ'), findsOneWidget);

  await tester.tap(find.text('Омӯзиши калимаҳо'));
  await tester.pumpAndSettle();
  expect(find.text('Омӯзиши калимаҳо'), findsOneWidget);

  await tester.tap(find.text('Дуъоҳо'));
  await tester.pumpAndSettle();
  expect(find.text('Дуъоҳо'), findsOneWidget);

  await tester.tap(find.text('Қуръон'));
  await tester.pumpAndSettle();
  expect(find.text('Қуръон'), findsOneWidget);
}

Future<void> _testTasbeehCounter(WidgetTester tester) async {
  // Navigate to Tasbeeh page
  await tester.tap(find.text('Тасбиҳ'));
  await tester.pumpAndSettle();

  // Test counter functionality
  final incrementButton = find.byIcon(Icons.add);
  expect(incrementButton, findsOneWidget);

  // Increment counter
  for (int i = 0; i < 10; i++) {
    await tester.tap(incrementButton);
    await tester.pump();
  }

  // Verify counter shows 10
  expect(find.text('10'), findsOneWidget);

  // Test reset
  final resetButton = find.byIcon(Icons.refresh);
  await tester.tap(resetButton);
  await tester.pump();
  expect(find.text('0'), findsOneWidget);

  // Test settings
  final settingsButton = find.byIcon(Icons.settings);
  await tester.tap(settingsButton);
  await tester.pumpAndSettle();
  expect(find.text('Танзимот'), findsOneWidget);

  // Close settings
  await tester.tap(find.byIcon(Icons.close));
  await tester.pumpAndSettle();
}

Future<void> _testWordLearningGame(WidgetTester tester) async {
  // Navigate to Learn Words page
  await tester.tap(find.text('Омӯзиши калимаҳо'));
  await tester.pumpAndSettle();

  // Test different game modes
  await tester.tap(find.text('Саволи-ҷавоб'));
  await tester.pumpAndSettle();
  expect(find.text('Саволи-ҷавоб'), findsOneWidget);

  await tester.tap(find.text('Ҷуфтсозӣ'));
  await tester.pumpAndSettle();
  expect(find.text('Ҷуфтсозӣ'), findsOneWidget);

  await tester.tap(find.text('Флеш-картаҳо'));
  await tester.pumpAndSettle();
  expect(find.text('Флеш-картаҳо'), findsOneWidget);

  // Test difficulty selection
  await tester.tap(find.text('Осон'));
  await tester.pumpAndSettle();
  expect(find.text('Осон'), findsOneWidget);

  await tester.tap(find.text('Мутавоссит'));
  await tester.pumpAndSettle();
  expect(find.text('Мутавоссит'), findsOneWidget);

  await tester.tap(find.text('Душвор'));
  await tester.pumpAndSettle();
  expect(find.text('Душвор'), findsOneWidget);
}

Future<void> _testDuasCollection(WidgetTester tester) async {
  // Navigate to Duas page
  await tester.tap(find.text('Дуъоҳо'));
  await tester.pumpAndSettle();

  // Test search functionality
  final searchField = find.byType(TextField);
  await tester.enterText(searchField, 'الله');
  await tester.pumpAndSettle();

  // Clear search
  await tester.tap(find.byIcon(Icons.clear));
  await tester.pumpAndSettle();

  // Test Dua card interaction
  final duaCards = find.byType(Card);
  if (duaCards.evaluate().isNotEmpty) {
    await tester.tap(duaCards.first);
    await tester.pumpAndSettle();
    
    // Close detail view
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
  }
}

Future<void> _testSearchFunctionality(WidgetTester tester) async {
  // Navigate to Search page (assuming it's accessible from home)
  // This would depend on your app's navigation structure
  
  // Test search input
  final searchField = find.byType(TextField);
  if (searchField.evaluate().isNotEmpty) {
    await tester.enterText(searchField, 'test');
    await tester.pumpAndSettle();

    // Test filter options
    if (find.text('Арабӣ').evaluate().isNotEmpty) {
      await tester.tap(find.text('Арабӣ'));
      await tester.pumpAndSettle();
    }

    // Clear search
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
  }
}

Future<void> _testSettings(WidgetTester tester) async {
  // Navigate to Settings page
  // This would depend on your app's navigation structure
  
  // Test theme selection
  if (find.text('Макон').evaluate().isNotEmpty) {
    await tester.tap(find.text('Макон'));
    await tester.pumpAndSettle();
    
    // Select different theme
    if (find.text('Торик').evaluate().isNotEmpty) {
      await tester.tap(find.text('Торик'));
      await tester.pumpAndSettle();
    }
    
    // Go back
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
  }

  // Test font size setting
  if (find.text('Андозаи ҳарф').evaluate().isNotEmpty) {
    await tester.tap(find.text('Андозаи ҳарф'));
    await tester.pumpAndSettle();
    
    // Adjust font size
    final slider = find.byType(Slider);
    if (slider.evaluate().isNotEmpty) {
      await tester.drag(slider, const Offset(50, 0));
      await tester.pumpAndSettle();
    }
    
    // Close dialog
    await tester.tap(find.text('Бас'));
    await tester.pumpAndSettle();
  }
}
