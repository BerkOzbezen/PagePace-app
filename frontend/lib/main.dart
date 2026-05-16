import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/router/go_router_refresh_stream.dart';
import 'core/theme/app_colors.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/books/screens/add_book_screen.dart';
import 'features/books/screens/book_detail_screen.dart';
import 'features/books/screens/books_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/social/screens/friend_profile_screen.dart';
import 'features/social/screens/social_screen.dart';
import 'features/stats/screens/stats_screen.dart';
import 'features/timer/screens/timer_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final _authRefresh = GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  );

  static final GoRouter _router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _authRefresh,
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (user == null && !isAuthRoute) return '/login';
      if (user != null && isAuthRoute) return '/books';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return _HomeShell(
            location: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/books',
            builder: (context, state) => const BooksScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddBookScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => BookDetailScreen(bookId: state.pathParameters['id'] ?? ''),
              ),
            ],
          ),
          GoRoute(
            path: '/timer',
            builder: (context, state) => const TimerScreen(),
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: '/social',
            builder: (context, state) => const SocialScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => FriendProfileScreen(friendId: state.pathParameters['id'] ?? ''),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PagePace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.location, required this.child});

  final String location;
  final Widget child;

  int get _currentIndex {
    if (location.startsWith('/timer')) return 1;
    if (location.startsWith('/stats')) return 2;
    if (location.startsWith('/social')) return 3;
    return 0; // /books (+ nested)
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/books');
        return;
      case 1:
        context.go('/timer');
        return;
      case 2:
        context.go('/stats');
        return;
      case 3:
        context.go('/social');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => _onTap(context, i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: scheme.onSurface.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Kitaplık'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Oku'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'İstatistik'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Sosyal'),
        ],
      ),
    );
  }
}
