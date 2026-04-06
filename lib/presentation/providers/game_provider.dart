import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/game_entities.dart';
import '../../domain/usecases/build_game_usecase.dart';
import 'categories_provider.dart';

// ─── Game configuration state ────────────────────────────────────────────────

class GameConfig {
  final int playerCount;
  final int impostorCount;
  final ImpostorMode impostorMode;
  final Difficulty difficulty;
  final List<String> playerNames;
  final String? selectedCategoryName;

  const GameConfig({
    this.playerCount = 4,
    this.impostorCount = 1,
    this.impostorMode = ImpostorMode.none,
    this.difficulty = Difficulty.easy,
    this.playerNames = const ['', '', '', ''],
    this.selectedCategoryName,
  });

  GameConfig copyWith({
    int? playerCount,
    int? impostorCount,
    ImpostorMode? impostorMode,
    Difficulty? difficulty,
    List<String>? playerNames,
    String? selectedCategoryName,
    bool clearCategory = false,
  }) {
    return GameConfig(
      playerCount: playerCount ?? this.playerCount,
      impostorCount: impostorCount ?? this.impostorCount,
      impostorMode: impostorMode ?? this.impostorMode,
      difficulty: difficulty ?? this.difficulty,
      playerNames: playerNames ?? this.playerNames,
      selectedCategoryName: clearCategory ? null : (selectedCategoryName ?? this.selectedCategoryName),
    );
  }
}

// ─── Game session state ───────────────────────────────────────────────────────

enum GamePhase { config, passing, revealing, discussion, voting, result }

class GameState {
  final GameConfig config;
  final GameSession? session;
  final GamePhase phase;
  final int currentPlayerIndex;
  final Map<int, int> votes; // voter → suspect
  final bool isLoading;
  final String? error;

  const GameState({
    this.config = const GameConfig(),
    this.session,
    this.phase = GamePhase.config,
    this.currentPlayerIndex = 0,
    this.votes = const {},
    this.isLoading = false,
    this.error,
  });

  bool get allCardsRevealed =>
      session != null &&
      currentPlayerIndex >= session!.playerCount;

  GameState copyWith({
    GameConfig? config,
    GameSession? session,
    GamePhase? phase,
    int? currentPlayerIndex,
    Map<int, int>? votes,
    bool? isLoading,
    String? error,
  }) {
    return GameState(
      config: config ?? this.config,
      session: session ?? this.session,
      phase: phase ?? this.phase,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      votes: votes ?? this.votes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─── Game Notifier ────────────────────────────────────────────────────────────

class GameNotifier extends Notifier<GameState> {
  @override
  GameState build() => const GameState();

  // Config updates
  void setPlayerCount(int count) {
    final maxImpostors = (count / 3).floor().clamp(1, 3);
    final newImpostorCount = state.config.impostorCount.clamp(1, maxImpostors);
    
    // Adjust player names list
    List<String> newNames = List.from(state.config.playerNames);
    if (count > newNames.length) {
      newNames.addAll(List.generate(count - newNames.length, (_) => ''));
    } else if (count < newNames.length) {
      newNames = newNames.sublist(0, count);
    }
    
    state = state.copyWith(
      config: state.config.copyWith(
        playerCount: count,
        impostorCount: newImpostorCount,
        playerNames: newNames,
      ),
    );
  }

  void setPlayerName(int index, String name) {
    final newNames = List<String>.from(state.config.playerNames);
    if (index >= 0 && index < newNames.length) {
      newNames[index] = name;
      state = state.copyWith(config: state.config.copyWith(playerNames: newNames));
    }
  }

  void setCategory(String? categoryName) {
    state = state.copyWith(
      config: state.config.copyWith(
        selectedCategoryName: categoryName,
        clearCategory: categoryName == null,
      ),
    );
  }

  void setImpostorCount(int count) {
    state = state.copyWith(
      config: state.config.copyWith(impostorCount: count),
    );
  }

  void setImpostorMode(ImpostorMode mode) {
    state = state.copyWith(config: state.config.copyWith(impostorMode: mode));
  }

  void setDifficulty(Difficulty difficulty) {
    state = state.copyWith(config: state.config.copyWith(difficulty: difficulty));
  }

  // Start a new game
  Future<void> startGame() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final useCase = ref.read(buildGameUseCaseProvider);
      final session = await useCase(
        BuildGameParams(
          playerCount: state.config.playerCount,
          impostorCount: state.config.impostorCount,
          impostorMode: state.config.impostorMode,
          difficulty: state.config.difficulty,
          playerNames: state.config.playerNames,
          selectedCategoryName: state.config.selectedCategoryName,
        ),
      );
      state = state.copyWith(
        session: session,
        phase: GamePhase.passing,
        currentPlayerIndex: 0,
        votes: {},
        isLoading: false,
      );
    } on Failure catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Ocurrió un error inesperado.",
      );
    }
  }

  // Advance past the "pass phone" screen to reveal
  void showWordForCurrentPlayer() {
    state = state.copyWith(phase: GamePhase.revealing);
  }

  // After revealing, either move to next player or start discussion
  void doneRevealing() {
    final nextIndex = state.currentPlayerIndex + 1;
    if (nextIndex >= (state.session?.playerCount ?? 0)) {
      state = state.copyWith(phase: GamePhase.discussion);
    } else {
      state = state.copyWith(
        currentPlayerIndex: nextIndex,
        phase: GamePhase.passing,
      );
    }
  }

  // Move from discussion to voting
  void startVoting() {
    state = state.copyWith(phase: GamePhase.voting, votes: {});
  }

  // Record a vote
  void castVote(int voterIndex, int suspectIndex) {
    final newVotes = Map<int, int>.from(state.votes);
    newVotes[voterIndex] = suspectIndex;
    state = state.copyWith(votes: newVotes);
  }

  // Tally votes and show result
  void submitVotes() {
    state = state.copyWith(phase: GamePhase.result);
  }

  /// Index of the player with the most votes (the eliminated player)
  int get eliminatedPlayerIndex {
    if (state.votes.isEmpty) return -1;
    final tally = <int, int>{};
    for (final suspect in state.votes.values) {
      tally[suspect] = (tally[suspect] ?? 0) + 1;
    }
    return tally.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // Reset to config screen
  void resetGame() {
    state = const GameState();
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(
  GameNotifier.new,
);
