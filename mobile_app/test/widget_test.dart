import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/core/network/network_config.dart';
import 'package:mobile_app/core/storage/secure_storage.dart';
import 'package:mobile_app/features/auth/presentation/login_screen.dart';

class MockSecureStorage implements SecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> saveToken(String token) async {
    _data['jwt_token'] = token;
  }

  @override
  Future<String?> getToken() async {
    return _data['jwt_token'];
  }

  @override
  Future<void> saveUser(Map<String, dynamic> user) async {
    _data['user_data'] = jsonEncode(user);
  }

  @override
  Future<Map<String, dynamic>?> getUser() async {
    final val = _data['user_data'];
    if (val == null) return null;
    return jsonDecode(val) as Map<String, dynamic>;
  }

  @override
  Future<void> clearAll() async {
    _data.clear();
  }
}

void main() {
  testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Pump to let the state notifier initialize and complete its async secure storage check
    await tester.pumpAndSettle();

    // Verify header title "Flash" and "Dash" are rendered
    expect(find.text('Flash'), findsOneWidget);
    expect(find.text('Dash'), findsOneWidget);

    // Verify fields are present
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email & Password
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
