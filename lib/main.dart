import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Explicitly enable offline persistence for Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const aidea());
}

class aidea extends StatelessWidget {
  const aidea({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'AIdea',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: settings.getLightTheme().copyWith(
              textTheme: GoogleFonts.interTextTheme(
                settings.getLightTheme().textTheme,
              ),
            ),
            darkTheme: settings.getDarkTheme().copyWith(
              textTheme: GoogleFonts.interTextTheme(
                settings.getDarkTheme().textTheme,
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
