import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/home_screen.dart';
import 'screens/note_editor_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: AIdea()));
}

class AIdea extends ConsumerWidget {
  const AIdea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final isAuthenticated = authState.value != null;
        final isAuthRoute =
            state.matchedLocation.startsWith('/login') ||
            state.matchedLocation.startsWith('/register');

        // Redirect to login if not authenticated and not on auth route
        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }

        // Redirect to home if authenticated and on auth route
        if (isAuthenticated && isAuthRoute) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/note/new',
          builder: (context, state) => const NoteEditorScreen(),
        ),
        GoRoute(
          path: '/note/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoteDetailScreen(noteId: id);
          },
        ),
        GoRoute(
          path: '/note/:id/edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoteEditorScreen(noteId: id);
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'PopSci Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
