import 'package:dio/dio.dart';
import 'package:impostor/core/constants/app_constants.dart';

/// Singleton Dio client with timeout and retry configuration.
class DioClient {
  DioClient._();
  static final DioClient _instance = DioClient._();
  static DioClient get instance => _instance;

  late final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Accept': 'application/json'},
    ),
  );

  Dio get dio => _dio;
}
