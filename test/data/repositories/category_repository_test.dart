import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:impostor/core/errors/failures.dart';
import 'package:impostor/data/datasources/local/category_local_datasource.dart';
import 'package:impostor/data/datasources/remote/category_remote_datasource.dart';
import 'package:impostor/data/models/category_model.dart';
import 'package:impostor/data/repositories/category_repository_impl.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────────

class MockRemote extends Mock implements CategoryRemoteDataSource {}
class MockLocal extends Mock implements CategoryLocalDataSource {}

// ── Helpers ───────────────────────────────────────────────────────────────────

CategoriesResponse _mockResponse() => const CategoriesResponse(
      categorias: [
        CategoryModel(
          nombre: 'Animales',
          palabras: [
            WordModel(base: 'perro', sinonimos: ['can']),
            WordModel(base: 'gato', sinonimos: ['felino']),
          ],
        ),
      ],
    );

void main() {
  late MockRemote remote;
  late MockLocal local;
  late CategoryRepositoryImpl repo;

  setUp(() {
    remote = MockRemote();
    local = MockLocal();
    repo = CategoryRepositoryImpl(remote: remote, local: local);
  });

  group('getCategories — remote success', () {
    test('returns categories from remote and caches the result', () async {
      when(() => remote.fetchCategories())
          .thenAnswer((_) async => _mockResponse());
      when(() => local.cacheJson(any())).thenAnswer((_) async {});

      final result = await repo.getCategories();

      expect(result.length, 1);
      expect(result.first.name, 'Animales');
      expect(result.first.words.length, 2);
      verify(() => local.cacheJson(any())).called(1);
    });

    test('maps domain entity fields correctly', () async {
      when(() => remote.fetchCategories())
          .thenAnswer((_) async => _mockResponse());
      when(() => local.cacheJson(any())).thenAnswer((_) async {});

      final result = await repo.getCategories();
      final word = result.first.words.first;

      expect(word.base, 'perro');
      expect(word.synonyms, ['can']);
    });
  });

  group('getCategories — remote failure → cache fallback', () {
    test('falls back to valid cache on remote failure', () async {
      const cachedJson =
          '{"categorias":[{"nombre":"Cached","palabras":[{"base":"lobo","sinonimos":[]}]}]}';

      when(() => remote.fetchCategories()).thenThrow(const RemoteFailure());
      when(() => local.getCachedJson()).thenAnswer((_) async => cachedJson);

      final result = await repo.getCategories();

      expect(result.first.name, 'Cached');
    });

    test('falls back to expired cache if valid cache also fails', () async {
      const cachedJson =
          '{"categorias":[{"nombre":"ExpiredCache","palabras":[{"base":"pez","sinonimos":[]}]}]}';

      when(() => remote.fetchCategories()).thenThrow(const RemoteFailure());
      when(() => local.getCachedJson()).thenThrow(const CacheFailure('expired'));
      when(() => local.getCachedJsonForceFallback())
          .thenAnswer((_) async => cachedJson);

      final result = await repo.getCategories();

      expect(result.first.name, 'ExpiredCache');
    });

    test('throws CacheFailure when all sources fail', () async {
      when(() => remote.fetchCategories()).thenThrow(const RemoteFailure());
      when(() => local.getCachedJson()).thenThrow(const CacheFailure());
      when(() => local.getCachedJsonForceFallback())
          .thenThrow(const CacheFailure());

      expect(repo.getCategories(), throwsA(isA<CacheFailure>()));
    });
  });

  group('getCategories — filters empty categories', () {
    test('excludes categories with no words', () async {
      final responseWithEmpty = CategoriesResponse(
        categorias: [
          const CategoryModel(nombre: 'Empty', palabras: []),
          CategoryModel(
            nombre: 'Valid',
            palabras: const [WordModel(base: 'oso')],
          ),
        ],
      );

      when(() => remote.fetchCategories())
          .thenAnswer((_) async => responseWithEmpty);
      when(() => local.cacheJson(any())).thenAnswer((_) async {});

      final result = await repo.getCategories();

      expect(result.length, 1);
      expect(result.first.name, 'Valid');
    });
  });

  group('refreshCategories', () {
    test('always fetches fresh data and caches it', () async {
      when(() => remote.fetchCategories())
          .thenAnswer((_) async => _mockResponse());
      when(() => local.cacheJson(any())).thenAnswer((_) async {});

      await repo.refreshCategories();

      verify(() => remote.fetchCategories()).called(1);
      verify(() => local.cacheJson(any())).called(1);
    });

    test('propagates RemoteFailure on network error', () async {
      when(() => remote.fetchCategories()).thenThrow(const RemoteFailure());

      expect(repo.refreshCategories(), throwsA(isA<RemoteFailure>()));
    });
  });
}
