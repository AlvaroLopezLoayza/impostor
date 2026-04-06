import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/game_entities.dart';
import '../providers/categories_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/animated_gradient_bg.dart';

class ConfigScreen extends ConsumerWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final config = gameState.config;
    final notifier = ref.read(gameProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final maxImpostors = (config.playerCount / 3).floor().clamp(1, 3);

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedGradientBg(),
          SafeArea(
            child: Column(
              children: [
                // ── AppBar ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => context.go(AppRouter.home),
                      ),
                      Expanded(
                        child: Text(
                          'Configurar Partida',
                          style: textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Players ────────────────────────────────────────
                        _SectionCard(
                          icon: Icons.people_rounded,
                          title: 'Jugadores',
                          trailing: Text(
                            '${config.playerCount}',
                            style: textTheme.headlineMedium?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          child: Slider(
                            value: config.playerCount.toDouble(),
                            min: 2,
                            max: 12,
                            divisions: 10,
                            onChanged: (v) => notifier.setPlayerCount(v.round()),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Impostors ──────────────────────────────────────
                        _SectionCard(
                          icon: Icons.psychology_alt_rounded,
                          title: 'Impostores',
                          trailing: Text(
                            '${config.impostorCount}',
                            style: textTheme.headlineMedium?.copyWith(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          child: Slider(
                            value: config.impostorCount.toDouble(),
                            min: 1,
                            max: maxImpostors.toDouble(),
                            divisions: (maxImpostors - 1).clamp(1, 10),
                            onChanged: (v) => notifier.setImpostorCount(v.round()),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Difficulty ─────────────────────────────────────
                        _SectionCard(
                          icon: Icons.bolt_rounded,
                          title: 'Dificultad',
                          child: Row(
                            children: [
                              _DiffChip(
                                label: 'Fácil',
                                selected: config.difficulty == Difficulty.easy,
                                onTap: () => notifier.setDifficulty(Difficulty.easy),
                              ),
                              const SizedBox(width: 12),
                              _DiffChip(
                                label: 'Difícil',
                                selected: config.difficulty == Difficulty.hard,
                                color: AppTheme.danger,
                                onTap: () => notifier.setDifficulty(Difficulty.hard),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Impostor Mode ──────────────────────────────────
                        _SectionCard(
                          icon: Icons.help_outline_rounded,
                          title: 'Pista para el impostor',
                          subtitle: 'El impostor recibe...',
                          child: Column(
                            children: [
                              _ModeOption(
                                label: 'Nada — solo sabe que es impostor',
                                selected: config.impostorMode == ImpostorMode.none,
                                onTap: () => notifier.setImpostorMode(ImpostorMode.none),
                              ),
                              const SizedBox(height: 8),
                              _ModeOption(
                                label: 'Una palabra diferente de la misma categoría',
                                selected: config.impostorMode == ImpostorMode.differentWord,
                                onTap: () => notifier.setImpostorMode(ImpostorMode.differentWord),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Error message ──────────────────────────────────
                        if (gameState.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.danger.withAlpha(80)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    gameState.error!,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Start Button ───────────────────────────────────
                        _StartButton(
                          isLoading: gameState.isLoading,
                          onTap: () async {
                            await notifier.startGame();
                            if (context.mounted && ref.read(gameProvider).error == null) {
                              context.go(AppRouter.passPhone);
                            }
                          },
                        ),
                        const SizedBox(height: 8),

                        // ── Refresh categories ─────────────────────────────
                        Center(
                          child: TextButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Actualizar palabras'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                            ),
                            onPressed: () =>
                                ref.read(categoriesProvider.notifier).refresh(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleLarge),
                    if (subtitle != null)
                      Text(subtitle!, style: textTheme.bodyMedium),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DiffChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _DiffChip({
    required this.label,
    required this.selected,
    this.color = AppTheme.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(40) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppTheme.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? color : AppTheme.textSecondary,
                ),
          ),
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppTheme.primary : AppTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _StartButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            )
          : const Text('¡Comenzar!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
    );
  }
}
