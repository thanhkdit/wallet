
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/services/database_service.dart';
import 'providers/providers.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';



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
      // We need to pass the initial route/home logic or check inside the app
      // But Since Main App is const, we can pass it as a parameter or just rely on the overrides
      // Actually, we can just pass the database service to the app widget or rely on riverpod
      // better to pass the initial widget to home
      child: AntigravityNoteApp(isOnboardingComplete: databaseService.isOnboardingComplete()),
    ),
  );
}

class AntigravityNoteApp extends ConsumerStatefulWidget {
  final bool isOnboardingComplete;
  const AntigravityNoteApp({super.key, required this.isOnboardingComplete});

  @override
  ConsumerState<AntigravityNoteApp> createState() => _AntigravityNoteAppState();
}

class _AntigravityNoteAppState extends ConsumerState<AntigravityNoteApp> {
  @override
  void initState() {
    super.initState();

  }

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
      home: ref.watch(databaseServiceProvider).isOnboardingComplete() 
          ? const MainScreen() 
          : const OnboardingScreen(),
    );
  }
}
