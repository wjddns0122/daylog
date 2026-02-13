import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test mounts a basic app shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('daylog')),
        ),
      ),
    );

    expect(find.text('daylog'), findsOneWidget);
  });
}
