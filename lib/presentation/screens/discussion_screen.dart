import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../widgets/animated_gradient_bg.dart';

class DiscussionScreen extends ConsumerWidget {
  const DiscussionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final session = gameState.session!;
    final textTheme = Theme.of(context).textTheme;

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

                  // ── Header ─────────────────────────────────────────────
                  Text('¡Que empiece la discusión!',
                      style: textTheme.headlineLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Categoría: ${session.categoryName}',
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // ── Timer ring (Isolated Performance Optimization) ───────
                  const _TimerRing(),

                  const SizedBox(height: 40),

                  // ── Player list ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jugadores', style: textTheme.titleLarge),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            session.playerCount,
                            (i) => Chip(
                              avatar: CircleAvatar(
                                backgroundColor: AppTheme.primary.withAlpha(50),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              label: Text('Jugador ${i + 1}'),
                              backgroundColor: AppTheme.surfaceHigh,
                              side: const BorderSide(color: AppTheme.border),
                              labelStyle: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── Vote button ────────────────────────────────────────
                  ElevatedButton.icon(
                    icon: const Icon(Icons.how_to_vote_rounded),
                    label: const Text('Votar',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    onPressed: () {
                      notifier.startVoting();
                      context.go(AppRouter.vote);
                    },
                    style: ElevatedButton.styleFrom(
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

// ── Timer Ring (Isolated to prevent global UI repaints) ─────────────────────

class _TimerRing extends StatefulWidget {
  const _TimerRing();

  @override
  State<_TimerRing> createState() => _TimerRingState();
}

class _TimerRingState extends State<_TimerRing> {
  static const _totalSeconds = 180; // 3 minutes
  late int _remaining = _totalSeconds;
  Timer? _timer;
  bool _started = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _started = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0) {
        setState(() => _remaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  String get _timeLabel {
    final minutes = (_remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progress => _remaining / _totalSeconds;

  Color get _timerColor {
    if (_remaining > 60) return AppTheme.primary;
    if (_remaining > 30) return AppTheme.accent;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: _started ? 'Temporizador$_timeLabel' : 'Iniciar temporizador',
      child: GestureDetector(
        onTap: _started ? null : _startTimer,
        child: SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.border,
                  color: _timerColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _timeLabel,
                    style: textTheme.displayMedium?.copyWith(
                      color: _timerColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (!_started)
                    Text(
                      'Toca para\niniciar',
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
