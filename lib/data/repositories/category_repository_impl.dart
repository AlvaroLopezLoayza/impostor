import 'dart:convert';
import 'package:impostor/core/errors/failures.dart';
import 'package:impostor/domain/entities/game_entities.dart';
import 'package:impostor/domain/repositories/category_repository.dart';
import 'package:impostor/data/datasources/local/category_local_datasource.dart';
import 'package:impostor/data/models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource _local;

  CategoryRepositoryImpl({
    required CategoryLocalDataSource local,
  }) : _local = local;

  @override
  Future<List<Category>> getCategories() async {
    // 1. Try valid cache (respecting TTL)
    try {
      final json = await _local.getCachedJson();
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return _mapToDomain(CategoriesResponse.fromJson(decoded));
    } on CacheFailure {
      // fall through to assets
    }

    // 2. Load from bundled assets (no remote call)
    try {
      final json = await _local.getAssetJson();
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final response = CategoriesResponse.fromJson(decoded);
      // Optional: cache the asset content to avoid asset loading next time
      await _local.cacheJson(json);
      return _mapToDomain(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Category>> refreshCategories() async {
    // We just reload from assets or return what we have
    return getCategories();
  }

  List<Category> _mapToDomain(CategoriesResponse response) {
    return response.categorias
        .where((c) => c.palabras.isNotEmpty)
        .map(
          (c) => Category(
            name: c.nombre,
            words: c.palabras
                .map((w) => Word(base: w.base, synonyms: w.sinonimos))
                .toList(),
          ),
        )
        .toList();
  }
}
