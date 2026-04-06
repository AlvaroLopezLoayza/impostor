import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/category_local_datasource.dart';
import '../../data/datasources/remote/category_remote_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/game_entities.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/usecases/build_game_usecase.dart';

// ─── Infrastructure providers ────────────────────────────────────────────────

final categoryRemoteDataSourceProvider = Provider<CategoryRemoteDataSource>(
  (_) => CategoryRemoteDataSource(),
);

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>(
  (_) => CategoryLocalDataSource(),
);

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(
    remote: ref.watch(categoryRemoteDataSourceProvider),
    local: ref.watch(categoryLocalDataSourceProvider),
  );
});

final buildGameUseCaseProvider = Provider<BuildGameUseCase>((ref) {
  return BuildGameUseCase(ref.watch(categoryRepositoryProvider));
});

// ─── Category AsyncNotifier ───────────────────────────────────────────────────

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    return ref.watch(categoryRepositoryProvider).getCategories();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(categoryRepositoryProvider).refreshCategories(),
    );
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
  CategoriesNotifier.new,
);
