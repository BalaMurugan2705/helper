// test/core/widgets/glass_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helper/core/widgets/glass_tile.dart';
import 'package:helper/core/theme/app_colors.dart';

void main() {
  testWidgets('GlassTile renders title and subtitle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassTile(
            dotColor: AppColors.accentCleaning,
            title: 'Clean bathroom',
            subtitle: 'Due today',
          ),
        ),
      ),
    );
    expect(find.text('Clean bathroom'), findsOneWidget);
    expect(find.text('Due today'), findsOneWidget);
  });

  testWidgets('GlassTile calls onTap', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassTile(
            dotColor: AppColors.accentHealth,
            title: 'Exercise',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(GlassTile));
    expect(tapped, isTrue);
  });
}
