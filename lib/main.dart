import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Explicitly enable offline persistence for Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );


  // Initialize Google Sign-In (required by google_sign_in v7+)
  try {
    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb
          ? dotenv.get('GOOGLE_CLIENT_ID_WEB')
          : null,
    );
  } catch (e) {
    debugPrint('Google Sign-In initialization failed: $e');
  }

  runApp(const AIdea());
}

class AIdea extends StatelessWidget {
  const AIdea({super.key});

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
            theme: settings.getLightTheme(),
            darkTheme: settings.getDarkTheme(),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
