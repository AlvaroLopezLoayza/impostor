import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/animated_gradient_bg.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedGradientBg(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),

                  // ── Logo / Title ──────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.primary.withAlpha(180),
                                AppTheme.primary.withAlpha(0),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'IMPOSTOR',
                          style: textTheme.displayMedium?.copyWith(
                            letterSpacing: 8,
                            fontWeight: FontWeight.w900,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [AppTheme.primaryLight, AppTheme.primary],
                              ).createShader(
                                const Rect.fromLTWH(0, 0, 300, 60),
                              ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¿Quién es el infiltrado?',
                          style: textTheme.bodyMedium?.copyWith(
                            letterSpacing: 1.5,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── CTA ───────────────────────────────────────────────────
                  _PulsingButton(
                    label: 'Nueva Partida',
                    onTap: () => context.go(AppRouter.config),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed: () => _showHowToPlay(context),
                      child: Text(
                        '¿Cómo se juega?',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _HowToPlaySheet(),
    );
  }
}

// ── Pulsing CTA Button ────────────────────────────────────────────────────────

class _PulsingButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PulsingButton({required this.label, required this.onTap});

  @override
  State<_PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 1.03)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: ScaleTransition(
        scale: _scale,
        child: ElevatedButton(
          onPressed: widget.onTap,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: AppTheme.primary,
            shadowColor: AppTheme.primary.withAlpha(100),
            elevation: 12,
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  letterSpacing: 1,
                ),
          ),
        ),
      ),
    );
  }
}

// ── How To Play Sheet ─────────────────────────────────────────────────────────

class _HowToPlaySheet extends StatelessWidget {
  const _HowToPlaySheet();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Cómo se juega?', style: textTheme.headlineMedium),
          const SizedBox(height: 20),
          ..._steps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_steps.indexOf(s) + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(s, style: textTheme.bodyLarge)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static const _steps = [
    'Configura el número de jugadores e impostores.',
    'Cada jugador ve su palabra en privado.',
    'Todos hablan sobre su palabra sin decirla directamente.',
    'Votan para eliminar al impostor.',
    '¡El equipo gana si elimina al impostor, y el impostor si escapa!',
  ];
}
