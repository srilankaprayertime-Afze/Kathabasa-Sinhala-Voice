import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Providers
import 'providers/theme_provider.dart';
import 'providers/history_provider.dart';
import 'services/tts_service.dart';

// Theme
import 'theme/app_theme.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safely load the .env configuration
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Could not load .env file: $e");
  }

  runApp(const KathabasaApp());
}

class KathabasaApp extends StatelessWidget {
  const KathabasaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TtsService()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Kathabasa Sinhala Voice',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const HomeScreen(),
              '/history': (context) => const HistoryScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
