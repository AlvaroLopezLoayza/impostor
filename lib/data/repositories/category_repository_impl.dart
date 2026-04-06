import 'dart:convert';
import 'package:impostor/core/errors/failures.dart';
import 'package:impostor/domain/entities/game_entities.dart';
import 'package:impostor/domain/repositories/category_repository.dart';
import 'package:impostor/data/datasources/local/category_local_datasource.dart';
import 'package:impostor/data/datasources/remote/category_remote_datasource.dart';
import 'package:impostor/data/models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _remote;
  final CategoryLocalDataSource _local;

  CategoryRepositoryImpl({
    required CategoryRemoteDataSource remote,
    required CategoryLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<List<Category>> getCategories() async {
    // 1. Try fetching fresh data from remote
    try {
      final response = await _remote.fetchCategories();
      final json = jsonEncode(response.toJson());
      await _local.cacheJson(json);
      return _mapToDomain(response);
    } on RemoteFailure {
      // fall through to cache
    } on ParseFailure {
      rethrow;
    }

    // 2. Try valid cache (respecting TTL)
    try {
      final json = await _local.getCachedJson();
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return _mapToDomain(CategoriesResponse.fromJson(decoded));
    } on CacheFailure {
      // fall through to force-fallback
    }

    // 3. Last resort — use expired cache rather than fail completely
    try {
      final json = await _local.getCachedJsonForceFallback();
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return _mapToDomain(CategoriesResponse.fromJson(decoded));
    } on CacheFailure {
      rethrow;
    }
  }

  @override
  Future<List<Category>> refreshCategories() async {
    final response = await _remote.fetchCategories();
    final json = jsonEncode(response.toJson());
    await _local.cacheJson(json);
    return _mapToDomain(response);
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
