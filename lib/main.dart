import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unify/custom_navbar.dart';
import 'package:unify/pages/add_post.dart';
import 'package:unify/pages/birthday.dart';
import 'package:unify/pages/chat.dart';
import 'package:unify/pages/chatMessage.dart';
import 'package:unify/pages/comments.dart';
import 'package:unify/pages/edit_profile.dart';
import 'package:unify/pages/followers.dart';
import 'package:unify/pages/following.dart';
import 'package:unify/pages/home.dart';
import 'package:unify/pages/likes.dart';
import 'package:unify/pages/login.dart';
import 'package:unify/pages/notifications.dart';
import 'package:unify/pages/profile.dart';
import 'package:unify/pages/register.dart';
import 'package:unify/pages/search.dart';
import 'package:unify/pages/splashscreen.dart';
import 'package:unify/pages/user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'auth_provider.dart';

// GoRouter configuration
final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;

    // Si l'utilisateur est authentifié, ne redirigez pas vers /home si la destination est déjà la page d'accueil
    if (isAuthenticated && (state.uri.toString() == '/login' || state.uri.toString() == '/birthday')) {
      return '/home'; // Rediriger vers /home si l'utilisateur est authentifié et essaie d'accéder à /login
    }

    // Si l'utilisateur n'est pas authentifié, ne redirigez pas vers /welcome si la destination est déjà la page de bienvenue
    if (!isAuthenticated && state.uri.toString() == '/home') {
      return '/login'; // Rediriger vers /welcome si l'utilisateur n'est pas authentifié
    }

    return null; // Pas de redirection si l'utilisateur est déjà à la bonne page
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        return FutureBuilder(
          future: Future.delayed(const Duration(seconds: 5)),  // Attente de 3 secondes
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // Utilisez WidgetsBinding pour effectuer la navigation après la construction
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (authProvider.isAuthenticated) {
                  // Si authentifié, redirige vers la page d'accueil
                  context.go('/home');
                } else {
                  // Si non authentifié, redirige vers la page de bienvenue
                  context.go('/login');
                }
              });
              return const Splashscreen();
            }
            return const Splashscreen();  // Afficher l'écran de splash pendant le délai
          },
        );
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => ProfileScreen(),
    ),
    GoRoute(
      path: '/birthday',
      builder: (context, state) => BirthdayScreen(),
    ),
    GoRoute(
      path: '/:postId/comments',
      builder: (context, state) {
        return CommentsScreen(postId: int.parse(state.pathParameters['postId']!));
      },
    ),
    GoRoute(
      path: '/:postId/like',
      builder: (context, state) => LikesScreen(post_id: state.pathParameters['postId']),
    ),
    GoRoute(
        path: '/chatMessage',
        builder: (context, state) {
          final sender = state.extra as Map<String, dynamic>;
          return ChatMessageScreen(sender: sender);
        }
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final query = state.uri.queryParameters['query'] ?? '';
        return SearchScreen(query: query);
      },
    ),
    GoRoute(
      path: '/followers',
      builder: (context, state) {
        final user = state.extra as Map<String, dynamic>;
        return FollowersScreen(user: user);
      }
    ),
    GoRoute(
        path: '/following',
        builder: (context, state) {
          final user = state.extra as Map<String, dynamic>;
          return FollowingScreen(user: user);
        }
    ),
    ShellRoute(
      builder: (context, state, child) {
        return CustomNavBarScreen(child: child); // Ici, le BottomNavigationBar est toujours affiché
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeScreen(),
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) => ChatScreen(),
        ),
        GoRoute(
          path: '/add_post',
          builder: (context, state) => AddPostScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => NotificationsScreen(),
        ),
        GoRoute(
          path: '/comments',
          builder: (context, state) {
            final post = state.extra as Map<String, dynamic>;
            return CommentsScreen(post: post);
          },
        ),
        GoRoute(
          path: '/user',
          builder: (context, state) => UserScreen(),
        ),
        GoRoute(
          path: '/user/:userId',
          builder: (context, state) => UserScreen(userId: state.pathParameters['userId']),
        ),
        GoRoute(
            path: '/editProfile',
            builder: (context, state) {
              final user = state.extra as Map<String, dynamic>;
              return EditProfileScreen(user: user);
            }
        ),
      ],
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          final currentLocation = GoRouter.of(context).routeInformationProvider.value.uri.toString();
          if (currentLocation == '/home' || currentLocation == '/login') {
            // Si l'utilisateur est sur la page d'accueil ou la page de bienvenue
            return true; // Quitte l'application
          } else {
            GoRouter.of(context).pop(); // Revient à la page précédente
            return false; // Intercepte le retour
          }
        },
        child: MaterialApp.router(
          routerConfig: _router,
          title: 'Unify',
          theme: ThemeData(
              scaffoldBackgroundColor: Colors.white,
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CB669)),
              useMaterial3: true,
              textTheme: const TextTheme(
                headlineLarge: TextStyle(
                    color: const Color(0xFF4CB669),
                    fontFamily: "Poppins",
                    fontSize: 32,
                    fontWeight: FontWeight.bold
                ),
                bodyLarge: TextStyle(
                  color: Colors.black,
                  fontFamily: "Montserrat",
                  fontSize: 16,
                ),
              )
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr'), // Français
          ],
          locale: const Locale('fr'),
        )
    );
  }
}
