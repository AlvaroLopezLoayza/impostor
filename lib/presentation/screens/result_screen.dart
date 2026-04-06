import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../widgets/animated_gradient_bg.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _revealController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  late final AnimationController _confettiController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  late final Animation<double> _reveal = CurvedAnimation(
    parent: _revealController,
    curve: Curves.easeOutBack,
  );

  final List<_Particle> _particles = List.generate(
    60,
    (i) => _Particle(Random()),
  );

  @override
  void dispose() {
    _revealController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final session = gameState.session!;
    final textTheme = Theme.of(context).textTheme;

    final eliminatedIndex = notifier.eliminatedPlayerIndex;
    final eliminatedCard =
        eliminatedIndex >= 0 ? session.cards[eliminatedIndex] : null;
    final impostorsCaught = eliminatedCard?.isImpostor ?? false;

    // Start confetti if players win
    if (impostorsCaught && !_confettiController.isAnimating) {
      _confettiController.repeat();
    }

    final impostorIndexes = session.impostorIndexes;

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedGradientBg(),

          // Confetti layer
          if (impostorsCaught)
            AnimatedBuilder(
              animation: _confettiController,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(
                    _particles, _confettiController.value),
                child: const SizedBox.expand(),
              ),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // ── Result badge ─────────────────────────────────────
                  ScaleTransition(
                    scale: _reveal,
                    child: Column(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: impostorsCaught
                                ? AppTheme.success.withAlpha(30)
                                : AppTheme.danger.withAlpha(30),
                            border: Border.all(
                              color: impostorsCaught
                                  ? AppTheme.success
                                  : AppTheme.danger,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: impostorsCaught
                                    ? AppTheme.success.withAlpha(80)
                                    : AppTheme.danger.withAlpha(80),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            impostorsCaught
                                ? Icons.emoji_events_rounded
                                : Icons.sentiment_very_dissatisfied_rounded,
                            size: 56,
                            color: impostorsCaught
                                ? AppTheme.success
                                : AppTheme.danger,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          impostorsCaught
                              ? '¡Los jugadores ganan!'
                              : '¡El impostor escapa!',
                          style: textTheme.headlineLarge?.copyWith(
                            color: impostorsCaught
                                ? AppTheme.success
                                : AppTheme.danger,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Eliminated card ───────────────────────────────────
                  if (eliminatedCard != null)
                    FadeTransition(
                      opacity: _reveal,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            Text('Jugador eliminado',
                                style: textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            Text(
                              'Jugador ${eliminatedIndex + 1}',
                              style: textTheme.headlineMedium?.copyWith(
                                color: eliminatedCard.isImpostor
                                    ? AppTheme.danger
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: eliminatedCard.isImpostor
                                    ? AppTheme.danger.withAlpha(30)
                                    : AppTheme.success.withAlpha(30),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                eliminatedCard.isImpostor
                                    ? '🕵️ Era el Impostor'
                                    : '✅ Era inocente',
                                style: textTheme.labelLarge?.copyWith(
                                  color: eliminatedCard.isImpostor
                                      ? AppTheme.danger
                                      : AppTheme.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── Reveal section: correct word + impostors ──────────
                  FadeTransition(
                    opacity: _reveal,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: 'Categoría',
                            value: session.categoryName,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'La palabra era',
                            value: session.correctWord,
                            valueColor: AppTheme.primary,
                            large: true,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: impostorIndexes.length == 1
                                ? 'El impostor era'
                                : 'Los impostores eran',
                            value: impostorIndexes
                                .map((i) => 'Jugador ${i + 1}')
                                .join(', '),
                            valueColor: AppTheme.accent,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ── Actions ───────────────────────────────────────────
                  ElevatedButton.icon(
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Jugar de nuevo',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    onPressed: () {
                      notifier.resetGame();
                      context.go(AppRouter.config);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Inicio'),
                    onPressed: () {
                      notifier.resetGame();
                      context.go(AppRouter.home);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
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

// ── Info row ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool large;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: (large ? textTheme.headlineMedium : textTheme.titleLarge)
              ?.copyWith(
                  color: valueColor ?? AppTheme.textPrimary,
                  fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ── Confetti system ────────────────────────────────────────────────────────────

class _Particle {
  final double x;
  final double speed;
  final double size;
  final Color color;
  final double drift;

  _Particle(Random rng)
      : x = rng.nextDouble(),
        speed = 0.2 + rng.nextDouble() * 0.6,
        size = 4 + rng.nextDouble() * 8,
        color = [
          AppTheme.primary,
          AppTheme.accent,
          AppTheme.success,
          AppTheme.primaryLight,
          Colors.white,
        ][rng.nextInt(5)],
        drift = (rng.nextDouble() - 0.5) * 0.02;
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;

  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (t * p.speed) % 1.0;
      final x = p.x + p.drift * t * 10;
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size / 2,
        Paint()..color = p.color.withAlpha(200),
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
