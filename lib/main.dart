
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/services/database_service.dart';
import 'providers/providers.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for Vietnamese locale
  await initializeDateFormatting('vi_VN', null);

  // Initialize Database
  final databaseService = DatabaseService();
  await databaseService.init();

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(databaseService),
      ],
      child: const AntigravityNoteApp(),
    ),
  );
}

class AntigravityNoteApp extends StatelessWidget {
  const AntigravityNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AntigravityNote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      home: const DashboardScreen(),
    );
  }
}
