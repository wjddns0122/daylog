import 'package:daylog/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('CalendarScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));

    expect(find.text('Today_log'), findsOneWidget);
    expect(find.text('Show me your day today'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);

    // Dispose the widget tree to cancel Marquee timers
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
