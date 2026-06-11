// test/core/widgets/aurora_hero_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helper/core/widgets/aurora_hero.dart';
import 'package:helper/core/theme/app_colors.dart';

void main() {
  testWidgets('AuroraHero shows title and eyebrow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuroraHero(
            accent: AppColors.accentBudget,
            eyebrow: 'JUNE 2026',
            title: 'Budget',
          ),
        ),
      ),
    );
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('JUNE 2026'), findsOneWidget);
  });

  testWidgets('AuroraHero shows optional subtitle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuroraHero(
            accent: AppColors.accentHealth,
            eyebrow: 'TODAY',
            title: 'Health',
            subtitle: '4 habits done',
          ),
        ),
      ),
    );
    expect(find.text('4 habits done'), findsOneWidget);
  });
}
