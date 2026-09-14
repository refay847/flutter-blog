import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../error/app_exception.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final TokenStorage storage;
  late final Dio dio;

  ApiClient(this.storage) {
    // dio.get('blogs')  instead of dio.get('https://blog-2.wasmer.app/api/blogs')
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      dio.get(path, queryParameters: query);
  Future<Response<dynamic>> post(String path, {Object? data}) =>
      dio.post(path, data: data);
  Future<Response<dynamic>> put(String path, {Object? data}) =>
      dio.put(path, data: data);
  Future<Response<dynamic>> delete(String path) => dio.delete(path);

  AppException exceptionFrom(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final first = errors.values.first;
        if (first is List && first.isNotEmpty){
          return AppException(first.first.toString());
        }
      }
      if (data is Map && data['message'] != null){
        return AppException(data['message'].toString());
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return const AppException('The server took too long to respond.');
      }
      if (error.type == DioExceptionType.connectionError){
        return const AppException('No internet connection.');
      }
      if (error.response?.statusCode == 401){
        return const AppException('Your session has expired.');
      }
      return AppException(
        'Request failed (${error.response?.statusCode ?? 'network error'}).',
      );
    }
    return AppException('Something went wrong.');
  }
}
