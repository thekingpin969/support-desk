import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage storage;

  ApiClient({required this.storage})
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          responseType: ResponseType.json,
          headers: {'X-Tunnel-Skip-AntiPhishing-Page': 'true'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Attempt token refresh logic here
            final refreshToken = await storage.read(key: 'refresh_token');
            final userId = await storage.read(key: 'user_id');
            if (refreshToken != null && userId != null) {
              try {
                final refreshOptions = Options(headers: {});
                final res = await Dio().post(
                  '${ApiConstants.baseUrl}${ApiConstants.refresh}',
                  data: {'refresh_token': refreshToken, 'user_id': userId},
                  options: refreshOptions,
                );

                final newAccess = res.data['access_token'];
                final newRefresh = res.data['refresh_token'];

                await storage.write(key: 'access_token', value: newAccess);
                await storage.write(key: 'refresh_token', value: newRefresh);

                e.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
                final cloneReq = await dio.request(
                  e.requestOptions.path,
                  options: Options(
                    method: e.requestOptions.method,
                    headers: e.requestOptions.headers,
                  ),
                  data: e.requestOptions.data,
                  queryParameters: e.requestOptions.queryParameters,
                );
                return handler.resolve(cloneReq);
              } catch (refreshErr) {
                // Logout if refresh fails
                await storage.deleteAll();
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }
}
