import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'screens/login_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transaction_screen.dart';
import 'screens/fraud_alert_screen.dart';
import 'screens/savings_simulator_screen.dart';
import 'screens/health_score_screen.dart';
import 'screens/manual_entry_screen.dart';
import 'screens/statement_upload_screen.dart';
import 'services/api_service.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) {
    ApiService.setToken(session.accessToken);
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const AarthrakshakApp(),
    ),
  );
}

class AarthrakshakApp extends StatelessWidget {
  const AarthrakshakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aarthrakshak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFFD700),
          surface: const Color(0xFF141832),
        ),
        cardColor: const Color(0xFF141832),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/': (_) => const QuizScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/transactions': (_) => const TransactionScreen(),
        '/goals': (_) => const SavingsSimulatorScreen(),
        '/health': (_) => const HealthScoreScreen(),
        '/fraud-alert': (_) => const FraudAlertScreen(),
        '/manual-entry': (_) => const ManualEntryScreen(),
        '/statement-upload': (_) => const StatementUploadScreen(),
      },
    );
  }
}

