import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/config_screen.dart';
import '../../presentation/screens/pass_phone_screen.dart';
import '../../presentation/screens/word_reveal_screen.dart';
import '../../presentation/screens/discussion_screen.dart';
import '../../presentation/screens/vote_screen.dart';
import '../../presentation/screens/result_screen.dart';

class AppRouter {
  static const home = '/';
  static const config = '/config';
  static const passPhone = '/pass-phone';
  static const wordReveal = '/word-reveal';
  static const discussion = '/discussion';
  static const vote = '/vote';
  static const result = '/result';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(
        path: home,
        name: 'home',
        pageBuilder: (context, state) => _fade(const HomeScreen(), state),
      ),
      GoRoute(
        path: config,
        name: 'config',
        pageBuilder: (context, state) => _slide(const ConfigScreen(), state),
      ),
      GoRoute(
        path: passPhone,
        name: 'pass-phone',
        pageBuilder: (context, state) => _fade(const PassPhoneScreen(), state),
      ),
      GoRoute(
        path: wordReveal,
        name: 'word-reveal',
        pageBuilder: (context, state) => _fade(const WordRevealScreen(), state),
      ),
      GoRoute(
        path: discussion,
        name: 'discussion',
        pageBuilder: (context, state) => _slide(const DiscussionScreen(), state),
      ),
      GoRoute(
        path: vote,
        name: 'vote',
        pageBuilder: (context, state) => _slide(const VoteScreen(), state),
      ),
      GoRoute(
        path: result,
        name: 'result',
        pageBuilder: (context, state) => _fade(const ResultScreen(), state),
      ),
    ],
  );

  static CustomTransitionPage _fade(Widget child, GoRouterState state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  static CustomTransitionPage _slide(Widget child, GoRouterState state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}
