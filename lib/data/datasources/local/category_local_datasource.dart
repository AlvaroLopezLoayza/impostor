import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';

/// Manages local JSON cache using SharedPreferences with TTL.
class CategoryLocalDataSource {
  Future<String> getCachedJson() async {
    final prefs = await SharedPreferences.getInstance();
    final tsStr = prefs.getString(AppConstants.cacheTsKey);
    if (tsStr == null) throw const CacheFailure('No hay caché guardada.');

    final savedAt = DateTime.tryParse(tsStr);
    if (savedAt == null) throw const CacheFailure('Timestamp de caché inválido.');

    final age = DateTime.now().difference(savedAt);
    if (age > AppConstants.cacheTtl) {
      throw const CacheFailure('El caché ha expirado.');
    }

    final json = prefs.getString(AppConstants.cacheKey);
    if (json == null || json.isEmpty) {
      throw const CacheFailure('No hay datos en caché.');
    }
    return json;
  }

  Future<void> cacheJson(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.cacheKey, json);
    await prefs.setString(
      AppConstants.cacheTsKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Returns cached JSON regardless of TTL (used as last-resort fallback)
  Future<String> getCachedJsonForceFallback() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(AppConstants.cacheKey);
    if (json == null || json.isEmpty) throw const CacheFailure();
    return json;
  }
}
