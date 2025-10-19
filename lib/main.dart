import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';
import 'screens/auth_gate.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/create_chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey, debug: true);
  runApp(const PlatyTribeApp());
}
class PlatyTribeApp extends StatelessWidget {
  const PlatyTribeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlatyTribe',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthGate(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/chat': (_) => const ChatScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/create_chat': (_) => const CreateChatScreen(),
      },
    );
  }
}
