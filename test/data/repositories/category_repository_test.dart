import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:impostor/core/errors/failures.dart';
import 'package:impostor/data/datasources/local/category_local_datasource.dart';
import 'package:impostor/data/models/category_model.dart';
import 'package:impostor/data/repositories/category_repository_impl.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────────

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
  late MockLocal local;
  late CategoryRepositoryImpl repo;

  setUp(() {
    local = MockLocal();
    repo = CategoryRepositoryImpl(local: local);
  });

  group('getCategories — cache success', () {
    test('returns categories from cache if available', () async {
      final json = jsonEncode(_mockResponse().toJson());
      when(() => local.getCachedJson()).thenAnswer((_) async => json);

      final result = await repo.getCategories();

      expect(result.length, 1);
      expect(result.first.name, 'Animales');
      verify(() => local.getCachedJson()).called(1);
      verifyNever(() => local.getAssetJson());
    });
  });

  group('getCategories — asset fallback', () {
    test('falls back to assets if cache fails', () async {
      final json = jsonEncode(_mockResponse().toJson());
      when(() => local.getCachedJson()).thenThrow(const CacheFailure());
      when(() => local.getAssetJson()).thenAnswer((_) async => json);
      when(() => local.cacheJson(any())).thenAnswer((_) async {});

      final result = await repo.getCategories();

      expect(result.first.name, 'Animales');
      verify(() => local.getAssetJson()).called(1);
      verify(() => local.cacheJson(json)).called(1);
    });

    test('rethrows error if both cache and assets fail', () async {
      when(() => local.getCachedJson()).thenThrow(const CacheFailure());
      when(() => local.getAssetJson()).thenThrow(const CacheFailure('asset fail'));

      expect(repo.getCategories(), throwsA(isA<CacheFailure>()));
    });
  });

  group('getCategories — filters empty categories', () {
    test('excludes categories with no words', () async {
      const responseWithEmpty = CategoriesResponse(
        categorias: [
          CategoryModel(nombre: 'Empty', palabras: []),
          CategoryModel(
            nombre: 'Valid',
            palabras: [WordModel(base: 'oso')],
          ),
        ],
      );
      final json = jsonEncode(responseWithEmpty.toJson());

      when(() => local.getCachedJson()).thenAnswer((_) async => json);

      final result = await repo.getCategories();

      expect(result.length, 1);
      expect(result.first.name, 'Valid');
    });
  });

  group('refreshCategories', () {
    test('simply calls getCategories (which now handles local loading)', () async {
      final json = jsonEncode(_mockResponse().toJson());
      when(() => local.getCachedJson()).thenAnswer((_) async => json);

      await repo.refreshCategories();

      verify(() => local.getCachedJson()).called(1);
    });
  });
}
