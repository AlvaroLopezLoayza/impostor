import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../models/category_model.dart';

/// Fetches categories from the GitHub raw URL.
class CategoryRemoteDataSource {
  final Dio _dio;

  CategoryRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  Future<CategoriesResponse> fetchCategories() async {
    int attempt = 0;
    while (true) {
      try {
        final response = await _dio.get<String>(AppConstants.categoriesUrl);
        if (response.statusCode != 200) {
          throw RemoteFailure('HTTP ${response.statusCode}');
        }
        final json = jsonDecode(response.data!) as Map<String, dynamic>;
        return CategoriesResponse.fromJson(json);
      } on DioException catch (e) {
        attempt++;
        if (attempt > AppConstants.maxRetries) {
          throw RemoteFailure(e.message ?? 'Network error');
        }
        // Small backoff before retry
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      } on FormatException {
        throw const ParseFailure();
      }
    }
  }
}
