import '../../domain/entities/game_entities.dart';

/// Abstract contract — domain depends only on this interface
abstract class CategoryRepository {
  /// Fetch all categories (remote → cache → error)
  Future<List<Category>> getCategories();

  /// Force refresh from remote source
  Future<List<Category>> refreshCategories();
}
