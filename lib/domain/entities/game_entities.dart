/// Domain entity — Category
class Category {
  final String name;
  final List<Word> words;

  const Category({required this.name, required this.words});

  bool get isEmpty => words.isEmpty;

  @override
  String toString() => 'Category($name, ${words.length} words)';
}

/// Domain entity — Word (a base word with optional synonyms for impostor mode)
class Word {
  final String base;
  final List<String> synonyms;

  const Word({required this.base, required this.synonyms});

  bool get hasSynonyms => synonyms.isNotEmpty;
}

/// Domain entity — a player's assigned card for one round
class PlayerCard {
  final int playerIndex;
  final bool isImpostor;

  /// The word shown on screen. Null when impostor gets no word.
  final String? assignedWord;

  const PlayerCard({
    required this.playerIndex,
    required this.isImpostor,
    this.assignedWord,
  });
}

/// Domain entity — one full game session
class GameSession {
  final String categoryName;
  final String correctWord;
  final List<PlayerCard> cards;

  const GameSession({
    required this.categoryName,
    required this.correctWord,
    required this.cards,
  });

  List<int> get impostorIndexes =>
      cards.where((c) => c.isImpostor).map((c) => c.playerIndex).toList();

  int get playerCount => cards.length;
}

/// Difficulty levels
enum Difficulty { easy, hard }

/// Impostor word mode
enum ImpostorMode {
  /// Impostor sees nothing — just "You are the impostor"
  none,

  /// Impostor sees a different word from the same category
  differentWord,
}
