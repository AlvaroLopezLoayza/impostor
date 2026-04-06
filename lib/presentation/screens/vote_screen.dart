import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../widgets/animated_gradient_bg.dart';

class VoteScreen extends ConsumerStatefulWidget {
  const VoteScreen({super.key});

  @override
  ConsumerState<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends ConsumerState<VoteScreen> {
  int _currentVoter = 0;
  int? _selectedSuspect;
  final Map<int, int> _votes = {};

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final session = gameState.session!;
    final totalPlayers = session.playerCount;
    final textTheme = Theme.of(context).textTheme;
    final allVoted = _currentVoter >= totalPlayers;

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedGradientBg(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // ── Header ─────────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.how_to_vote_rounded,
                            size: 40, color: AppTheme.primary),
                        const SizedBox(height: 8),
                        Text('Votación', style: textTheme.headlineLarge,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        if (!allVoted)
                          Text(
                            'Jugador ${_currentVoter + 1} vota', // who's voting
                            style: textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (!allVoted) ...[
                    // ── Vote prompt ────────────────────────────────────
                    Text(
                      '¿Quién crees que es el impostor?',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: totalPlayers,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          if (i == _currentVoter) return const SizedBox.shrink();
                          final selected = _selectedSuspect == i;
                          return Semantics(
                            button: true,
                            selected: selected,
                            label: 'Votar por jugador ${i + 1}',
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedSuspect = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: selected
                                    ? AppTheme.danger.withAlpha(30)
                                    : AppTheme.surface,
                                border: Border.all(
                                  color: selected
                                      ? AppTheme.danger
                                      : AppTheme.border,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: selected
                                        ? AppTheme.danger.withAlpha(50)
                                        : AppTheme.surfaceHigh,
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selected
                                            ? AppTheme.danger
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Jugador ${i + 1}',
                                    style: textTheme.titleLarge?.copyWith(
                                      color: selected
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (selected)
                                    const Icon(Icons.check_circle_rounded,
                                        color: AppTheme.danger),
                                ],
                              ),
                            ),
                          ));
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _selectedSuspect == null
                          ? null
                          : () {
                              _votes[_currentVoter] = _selectedSuspect!;
                              setState(() {
                                _currentVoter++;
                                _selectedSuspect = null;
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        disabledBackgroundColor:
                            AppTheme.surfaceHigh,
                      ),
                      child: Text(
                        _currentVoter == totalPlayers - 1
                            ? 'Finalizar votación'
                            : 'Confirmar voto',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ] else ...[
                    // ── Tally ──────────────────────────────────────────
                    Expanded(child: _VoteTally(votes: _votes, totalPlayers: totalPlayers)),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.bar_chart_rounded),
                      label: const Text('Ver resultado',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      onPressed: () {
                        for (final e in _votes.entries) {
                          ref.read(gameProvider.notifier).castVote(e.key, e.value);
                        }
                        ref.read(gameProvider.notifier).submitVotes();
                        context.go(AppRouter.result);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
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

class _VoteTally extends StatelessWidget {
  final Map<int, int> votes;
  final int totalPlayers;
  const _VoteTally({required this.votes, required this.totalPlayers});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Count votes per suspect
    final tally = <int, int>{};
    for (final suspect in votes.values) {
      tally[suspect] = (tally[suspect] ?? 0) + 1;
    }
    final sorted = tally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVotes = sorted.isNotEmpty ? sorted.first.value : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resultado de la votación', style: textTheme.headlineMedium),
        const SizedBox(height: 20),
        ...List.generate(
          totalPlayers,
          (i) {
            final voteCount = tally[i] ?? 0;
            final isTop = voteCount == maxVotes && voteCount > 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text('Jugador ${i + 1}',
                        style: textTheme.bodyLarge),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: maxVotes == 0 ? 0 : voteCount / totalPlayers,
                        backgroundColor: AppTheme.border,
                        color: isTop ? AppTheme.danger : AppTheme.primary,
                        minHeight: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$voteCount',
                      style: textTheme.titleLarge?.copyWith(
                        color: isTop ? AppTheme.danger : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
