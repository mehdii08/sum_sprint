import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'providers/player_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/result_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/mind_timer_provider.dart';
import 'providers/pair_hunt_provider.dart';
import 'providers/tic_tac_toe_provider.dart';
import 'providers/tg_home_provider.dart';
import 'screens/splash_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  runApp(const SumSprintApp());
}

class SumSprintApp extends StatelessWidget {
  const SumSprintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => ChallengeProvider()),
        ChangeNotifierProvider(create: (_) => ResultProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MindTimerProvider()),
        ChangeNotifierProvider(create: (_) => PairHuntProvider()),
        ChangeNotifierProvider(create: (_) => TicTacToeProvider()),
        ChangeNotifierProvider(create: (_) => TgHomeProvider()),
      ],
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A237E),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
