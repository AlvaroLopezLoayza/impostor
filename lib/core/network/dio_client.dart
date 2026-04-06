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
  )..interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final contentType = response.headers.value('content-type') ?? '';
          if (contentType.contains('text/html')) {
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                error: 'Seguridad: Se recibió HTML en lugar de JSON.',
                type: DioExceptionType.badResponse,
              ),
            );
          } else {
            handler.next(response);
          }
        },
      ),
    );

  Dio get dio => _dio;
}
