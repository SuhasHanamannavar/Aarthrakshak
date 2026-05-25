import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:aarthrakshak/state/app_state.dart';
import 'package:aarthrakshak/screens/quiz_screen.dart';

void main() {
  testWidgets('Quiz screen renders opening card', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: QuizScreen()),
      ),
    );

    expect(find.text('Aarthrakshak'), findsOneWidget);
    expect(find.text('Apni Bachat Ka Rakshak'), findsOneWidget);
    expect(find.text('Shuru Karein'), findsOneWidget);
  });
}
