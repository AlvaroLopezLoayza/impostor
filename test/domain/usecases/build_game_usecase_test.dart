import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:impostor/core/errors/failures.dart';
import 'package:impostor/domain/entities/game_entities.dart';
import 'package:impostor/domain/repositories/category_repository.dart';
import 'package:impostor/domain/usecases/build_game_usecase.dart';

// ── Mock ───────────────────────────────────────────────────────────────────────

class MockCategoryRepository extends Mock implements CategoryRepository {}

// ── Fixture ───────────────────────────────────────────────────────────────────

final _testCategories = [
  Category(
    name: 'Animales',
    words: [
      const Word(base: 'perro', synonyms: ['can', 'mascota']),
      const Word(base: 'gato', synonyms: ['felino', 'minino']),
      const Word(base: 'lobo', synonyms: ['cánido']),
    ],
  ),
];

void main() {
  late MockCategoryRepository mockRepo;
  late BuildGameUseCase useCase;

  setUp(() {
    mockRepo = MockCategoryRepository();
    useCase = BuildGameUseCase(mockRepo);
    when(() => mockRepo.getCategories())
        .thenAnswer((_) async => _testCategories);
  });

  group('BuildGameUseCase — word assignment', () {
    test('all normal players receive the SAME base word', () async {
      final session = await useCase(const BuildGameParams(
        playerCount: 4,
        impostorCount: 1,
      ));

      final normalCards =
          session.cards.where((c) => !c.isImpostor).toList();
      final normalWords = normalCards.map((c) => c.assignedWord).toSet();

      // All normal players should have exactly one unique word
      expect(normalWords.length, 1);
      // That word should match the session's correct word
      expect(normalWords.first, session.correctWord);
    });

    test('correct number of impostors is assigned', () async {
      final session = await useCase(const BuildGameParams(
        playerCount: 6,
        impostorCount: 2,
      ));

      expect(session.impostorIndexes.length, 2);
    });

    test('impostor gets null word in mode=none', () async {
      final session = await useCase(const BuildGameParams(
        playerCount: 4,
        impostorCount: 1,
        impostorMode: ImpostorMode.none,
      ));

      final impostorCard =
          session.cards.firstWhere((c) => c.isImpostor);
      expect(impostorCard.assignedWord, isNull);
    });

    test('impostor gets a different word in mode=differentWord', () async {
      final session = await useCase(const BuildGameParams(
        playerCount: 4,
        impostorCount: 1,
        impostorMode: ImpostorMode.differentWord,
      ));

      final impostorCard =
          session.cards.firstWhere((c) => c.isImpostor);
      // Word must not be null
      expect(impostorCard.assignedWord, isNotNull);
      // And must differ from the correct word
      expect(impostorCard.assignedWord, isNot(session.correctWord));
    });

    test('session correctWord is always a valid base word from the category',
        () async {
      final allBases =
          _testCategories.expand((c) => c.words).map((w) => w.base).toSet();

      // Run multiple rounds to increase coverage
      for (var i = 0; i < 10; i++) {
        final session = await useCase(const BuildGameParams(
          playerCount: 3,
          impostorCount: 1,
        ));
        expect(allBases, contains(session.correctWord));
      }
    });
  });

  group('BuildGameUseCase — validation', () {
    test('throws GameFailure when playerCount < 2', () async {
      expect(
        () => useCase(const BuildGameParams(playerCount: 1, impostorCount: 1)),
        throwsA(isA<GameFailure>()),
      );
    });

    test('throws GameFailure when impostorCount >= playerCount', () async {
      expect(
        () => useCase(const BuildGameParams(playerCount: 3, impostorCount: 3)),
        throwsA(isA<GameFailure>()),
      );
    });

    test('throws GameFailure when no categories available', () async {
      when(() => mockRepo.getCategories()).thenAnswer((_) async => []);

      expect(
        () => useCase(const BuildGameParams(playerCount: 4, impostorCount: 1)),
        throwsA(isA<GameFailure>()),
      );
    });
  });

  group('BuildGameUseCase — player indexes', () {
    test('all player indexes are unique and within range', () async {
      const playerCount = 5;
      final session = await useCase(const BuildGameParams(
        playerCount: playerCount,
        impostorCount: 1,
      ));

      final indexes = session.cards.map((c) => c.playerIndex).toList();
      expect(indexes.toSet().length, playerCount);
      expect(indexes.every((i) => i >= 0 && i < playerCount), isTrue);
    });
  });
}
