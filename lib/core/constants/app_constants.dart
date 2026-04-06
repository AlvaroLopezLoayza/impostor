// Core constants used throughout the app
class AppConstants {
  AppConstants._();

  // Remote JSON data source
  static const String categoriesUrl =
      'https://raw.githubusercontent.com/AlvaroLopezLoayza/impostor/main/assets/categories.json';

  // Cache
  static const String cacheKey = 'cached_categories_json';
  static const String cacheTsKey = 'cached_categories_timestamp';
  static const Duration cacheTtl = Duration(hours: 24);

  // Network
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const int maxRetries = 2;

  // Game defaults
  static const int defaultPlayerCount = 4;
  static const int defaultImpostorCount = 1;
  static const int recentWordsHistorySize = 10;
}
