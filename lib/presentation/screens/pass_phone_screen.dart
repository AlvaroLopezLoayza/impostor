import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../widgets/animated_gradient_bg.dart';

/// Screen shown between players — instructs to hand the phone.
class PassPhoneScreen extends ConsumerWidget {
  const PassPhoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final playerNum = gameState.currentPlayerIndex + 1;
    final total = gameState.session?.playerCount ?? 0;

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedGradientBg(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  // ── Progress indicator ─────────────────────────────────
                  const SizedBox(height: 20),
                  Row(
                    children: List.generate(total, (i) {
                      final done = i < gameState.currentPlayerIndex;
                      final active = i == gameState.currentPlayerIndex;
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: done
                                ? AppTheme.success
                                : active
                                    ? AppTheme.primary
                                    : AppTheme.border,
                          ),
                        ),
                      );
                    }),
                  ),
                  const Spacer(flex: 2),

                  // ── Phone icon + instruction ───────────────────────────
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceHigh,
                      border: Border.all(color: AppTheme.border, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(60),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.smartphone_rounded,
                      size: 52,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Jugador $playerNum',
                    style: textTheme.displayMedium?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dale el teléfono al\nJugador $playerNum.',
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¡Que nadie más vea la pantalla!',
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 3),

                  // ── Reveal CTA ─────────────────────────────────────────
                  ElevatedButton(
                    onPressed: () {
                      notifier.showWordForCurrentPlayer();
                      context.go(AppRouter.wordReveal);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.visibility_rounded, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Ver mi palabra',
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
