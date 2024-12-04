import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quirk/ui/screens/pomodoro_screen.dart';

void main() {
  testWidgets('PomodoroScreen shows correct initial state', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PomodoroScreen(),
      ),
    );

    // Test initial display
    expect(find.text('25:00'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    
    // Test initial cycle display
    expect(find.text('Cycle 0/4'), findsOneWidget);
    expect(find.text('Work Time'), findsOneWidget);
  });

  testWidgets('Timer controls work correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PomodoroScreen(),
      ),
    );

    // Start timer
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    // Verify pause button appears
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);

    // Pause timer
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();

    // Verify play button reappears
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
  });
}