import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../widgets/animated_gradient_bg.dart';

/// Reveals the current player's word. Animates in from hidden state.
class WordRevealScreen extends ConsumerStatefulWidget {
  const WordRevealScreen({super.key});

  @override
  ConsumerState<WordRevealScreen> createState() => _WordRevealScreenState();
}

class _WordRevealScreenState extends ConsumerState<WordRevealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  late final Animation<double> _fadeIn =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<double> _scaleIn = Tween<double>(begin: 0.85, end: 1.0)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  bool _hidden = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reveal() {
    setState(() => _hidden = false);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final session = gameState.session!;
    final playerIndex = gameState.currentPlayerIndex;
    final card = session.cards[playerIndex];
    final isImpostor = card.isImpostor;
    final word = card.assignedWord;

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedGradientBg(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Jugador ${playerIndex + 1}',
                    style: textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Categoría: ${session.categoryName}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 2),

                  // ── Word card ─────────────────────────────────────────
                  Semantics(
                    button: true,
                    label: _hidden ? 'Revelar palabra' : 'Palabra revelada',
                    child: GestureDetector(
                      onTap: _hidden ? _reveal : null,
                      child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 48),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isImpostor && !_hidden
                              ? [
                                  AppTheme.danger.withAlpha(50),
                                  AppTheme.accent.withAlpha(30),
                                ]
                              : [
                                  AppTheme.surface,
                                  AppTheme.surfaceHigh,
                                ],
                        ),
                        border: Border.all(
                          color: _hidden
                              ? AppTheme.border
                              : isImpostor
                                  ? AppTheme.danger.withAlpha(120)
                                  : AppTheme.primary.withAlpha(120),
                          width: 1.5,
                        ),
                        boxShadow: _hidden
                            ? []
                            : [
                                BoxShadow(
                                  color: isImpostor
                                      ? AppTheme.danger.withAlpha(50)
                                      : AppTheme.primary.withAlpha(50),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                              ],
                      ),
                      child: _hidden
                          ? _HiddenState()
                          : _RevealedState(
                              fadeIn: _fadeIn,
                              scaleIn: _scaleIn,
                              isImpostor: isImpostor,
                              word: word,
                            ),
                    ),
                  ),
                  ),

                  const Spacer(flex: 3),

                  if (!_hidden) ...[
                    Semantics(
                      button: true,
                      label: 'Listo, pasar al siguiente jugador',
                      child: ElevatedButton(
                        onPressed: () {
                          notifier.doneRevealing();
                        final newState = ref.read(gameProvider);
                        if (newState.phase == GamePhase.discussion) {
                          context.go(AppRouter.discussion);
                        } else {
                          context.go(AppRouter.passPhone);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                        'Listo — pasar al siguiente',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ] else ...[
                    Text(
                      'Toca la tarjeta para revelar tu palabra',
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hidden state ───────────────────────────────────────────────────────────────

class _HiddenState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.lock_rounded,
          size: 52,
          color: AppTheme.textMuted,
        ),
        const SizedBox(height: 16),
        Text(
          'Toca para ver',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textMuted,
              ),
        ),
      ],
    );
  }
}

// ── Revealed state ─────────────────────────────────────────────────────────────

class _RevealedState extends StatelessWidget {
  final Animation<double> fadeIn;
  final Animation<double> scaleIn;
  final bool isImpostor;
  final String? word;

  const _RevealedState({
    required this.fadeIn,
    required this.scaleIn,
    required this.isImpostor,
    required this.word,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FadeTransition(
      opacity: fadeIn,
      child: ScaleTransition(
        scale: scaleIn,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isImpostor) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withAlpha(40),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppTheme.danger.withAlpha(100)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppTheme.danger, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'ERES EL IMPOSTOR',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppTheme.danger,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (word != null) ...[
                Text(
                  'Tu pista:',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  word!,
                  style: textTheme.displayMedium?.copyWith(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Text(
                  'No tienes pista.\n¡Actúa natural!',
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppTheme.accent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ] else ...[
              Text(
                'Tu palabra es:',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                word ?? '—',
                style: textTheme.displayMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Recuérdala. ¡No la digas directamente!',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
