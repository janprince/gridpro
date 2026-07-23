import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_professionals/app/app.dart';
import 'package:grid_professionals/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(preferences)],
      child: const GridProfessionalsApp(),
    ),
  );
}
