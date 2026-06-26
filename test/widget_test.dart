import 'package:edugain/features/auth/domain/models.dart';
import 'package:edugain/features/auth/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUser.fromJson', () {
    test('parses the backend user shape', () {
      final user = AppUser.fromJson(const {
        'id': 'u-1',
        'role': 'user',
        'phone': '+998901234567',
        'cefr_level': 'B1',
        'current_xp': 120,
        'level': 2,
        'streak_count': 5,
      });
      expect(user.id, 'u-1');
      expect(user.cefrLevel, 'B1');
      expect(user.currentXp, 120);
      expect(user.streakCount, 5);
      expect(user.displayName, '+998901234567');
    });

    test('tolerates missing optional fields', () {
      final user = AppUser.fromJson(const {'id': 'u-2', 'role': 'user'});
      expect(user.level, 1);
      expect(user.currentXp, 0);
      expect(user.displayName, 'Foydalanuvchi');
    });
  });

  testWidgets('SplashScreen renders the brand', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    expect(find.text('EduGain'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
