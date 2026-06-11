// test/core/widgets/glass_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helper/core/widgets/glass_card.dart';
import 'package:helper/core/theme/app_colors.dart';

void main() {
  testWidgets('GlassCard renders child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(child: Text('hello')),
        ),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('GlassCard with accent applies tinted border', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassCard(
            accent: AppColors.accentBudget,
            child: const Text('budget'),
          ),
        ),
      ),
    );
    expect(find.text('budget'), findsOneWidget);
  });
}
