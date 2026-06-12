// test/core/widgets/status_chip_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helper/core/widgets/status_chip.dart';

void main() {
  testWidgets('StatusChip.done renders green label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatusChip.done())),
    );
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('StatusChip.pending renders amber label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatusChip.pending())),
    );
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('StatusChip.overdue renders rose label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatusChip.overdue())),
    );
    expect(find.text('Overdue'), findsOneWidget);
  });
}
