import 'dart:math';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../entities/game_entities.dart';
import '../repositories/category_repository.dart';

/// Parameters for starting a new game
class BuildGameParams {
  final int playerCount;
  final int impostorCount;
  final ImpostorMode impostorMode;
  final Difficulty difficulty;

  const BuildGameParams({
    required this.playerCount,
    required this.impostorCount,
    this.impostorMode = ImpostorMode.none,
    this.difficulty = Difficulty.easy,
  });
}

/// Builds a [GameSession] with correct word assignment.
///
/// Word rules (per user spec):
/// - All NORMAL players receive the SAME base word.
/// - IMPOSTORS receive either nothing (mode=none) or a different word from
///   the same category (mode=differentWord), chosen from synonyms in
///   easy mode or a completely different base word in hard mode.
class BuildGameUseCase {
  final CategoryRepository _repository;
  final _random = Random();

  /// Recently used base words — avoids repetition across rounds
  final List<String> _recentWords = [];

  BuildGameUseCase(this._repository);

  Future<GameSession> call(BuildGameParams params) async {
    if (params.playerCount < 2) {
      throw const GameFailure('Se necesitan al menos 2 jugadores.');
    }
    if (params.impostorCount >= params.playerCount) {
      throw const GameFailure(
          'Los impostores deben ser menos que el total de jugadores.');
    }

    final categories = await _repository.getCategories();
    if (categories.isEmpty) {
      throw const GameFailure('No hay categorías disponibles.');
    }

    // 1. Pick a random category (avoid empty ones)
    final validCategories =
        categories.where((c) => c.words.length >= 2).toList();
    if (validCategories.isEmpty) {
      throw const GameFailure('Las categorías no tienen suficientes palabras.');
    }
    final category = validCategories[_random.nextInt(validCategories.length)];

    // 2. Pick a base word, avoiding recently used ones
    final candidates = category.words
        .where((w) => !_recentWords.contains(w.base))
        .toList();
    final wordPool = candidates.isNotEmpty ? candidates : category.words;
    final selectedWord = wordPool[_random.nextInt(wordPool.length)];

    // Track history
    _recentWords.add(selectedWord.base);
    if (_recentWords.length > AppConstants.recentWordsHistorySize) {
      _recentWords.removeAt(0);
    }

    // 3. Choose impostor's decoy word
    String? impostorWord;
    if (params.impostorMode == ImpostorMode.differentWord) {
      impostorWord = _pickImpostorWord(
        selectedWord,
        category,
        params.difficulty,
      );
    }

    // 4. Assign player indexes to impostor roles
    final allIndexes = List.generate(params.playerCount, (i) => i)..shuffle(_random);
    final impostorIndexes = allIndexes.take(params.impostorCount).toSet();

    // 5. Build PlayerCards
    final cards = List.generate(params.playerCount, (i) {
      final isImpostor = impostorIndexes.contains(i);
      return PlayerCard(
        playerIndex: i,
        isImpostor: isImpostor,
        assignedWord: isImpostor ? impostorWord : selectedWord.base,
      );
    });

    return GameSession(
      categoryName: category.name,
      correctWord: selectedWord.base,
      cards: cards,
    );
  }

  /// Picks the impostor's decoy word.
  ///
  /// - Easy: picks a synonym from the selected word (if available), else
  ///   a different base word from the same category.
  /// - Hard: always picks a different base word from the category.
  String? _pickImpostorWord(
    Word selectedWord,
    Category category,
    Difficulty difficulty,
  ) {
    if (difficulty == Difficulty.easy && selectedWord.hasSynonyms) {
      final synonyms = List<String>.from(selectedWord.synonyms)..shuffle(_random);
      return synonyms.first;
    }

    // Different base word from the same category
    final others =
        category.words.where((w) => w.base != selectedWord.base).toList();
    if (others.isEmpty) return null;
    return others[_random.nextInt(others.length)].base;
  }
}
