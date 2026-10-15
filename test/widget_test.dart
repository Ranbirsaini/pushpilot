import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pushpilot/main.dart';
import 'package:pushpilot/providers/notification_provider.dart';
import 'package:pushpilot/providers/project_provider.dart';
import 'package:pushpilot/providers/theme_provider.dart';
import 'package:pushpilot/utils/validators.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Validators: Detects Android google-services.json mistake', () {
    const invalidJson = '''
    {
      "project_info": {"project_id": "test-project"},
      "client": [{"client_info": {"mobilesdk_app_id": "1:123:android:abc"}}]
    }
    ''';
    final result = AppValidators.validateServiceAccount(invalidJson);
    expect(result.isValid, false);
    expect(result.errorMessage?.contains('google-services.json'), true);
  });

  test('Validators: Parses tokens list correctly', () {
    const tokensRaw = '''
    token1
    token2, token3
    token1
    ''';
    final tokens = AppValidators.parseTokens(tokensRaw);
    expect(tokens.length, 3);
    expect(tokens.contains('token1'), true);
    expect(tokens.contains('token2'), true);
    expect(tokens.contains('token3'), true);
  });

  testWidgets('PushPilot smoke test: renders dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => ProjectProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const PushPilotApp(),
      ),
    );

    // Initial pump and settle
    await tester.pumpAndSettle();

    // Verify main brand and dashboard components appear
    expect(find.text('PushPilot'), findsAtLeastNWidgets(1));
    expect(find.text('Dashboard Overview'), findsOneWidget);
  });
}
