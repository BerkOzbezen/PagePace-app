import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../exceptions/api_exceptions.dart';

class ApiService {
  ApiService({Dio? dio, FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Content-Type': 'application/json'},
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _attachAuthHeader,
        onError: _handleError,
      ),
    );
  }

  static const String baseUrl = 'http://localhost:8000';

  final Dio _dio;
  final FirebaseAuth _auth;

  Future<void> _attachAuthHeader(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = _auth.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        debugPrint('API auth: token attached for ${user.email}');
      } else {
        debugPrint('API auth: getIdToken returned null for ${user.email}');
      }
    } else {
      debugPrint('API auth: no current user, request sent without token');
    }
    handler.next(options);
  }

  void _handleError(DioException error, ErrorInterceptorHandler handler) {
    handler.reject(error);
  }

  Never _throwFromResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    final message = _extractDetail(response?.data) ?? 'Bir hata oluştu';

    switch (statusCode) {
      case 401:
        throw UnauthorizedException(message);
      case 404:
        throw NotFoundException(message);
      case 422:
        throw ValidationException(message, details: response?.data);
      default:
        throw ApiException(message);
    }
  }

  String? _extractDetail(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          return first['msg'].toString();
        }
        return detail.toString();
      }
    }
    return null;
  }

  Future<Response<T>> _request<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      debugPrint(
        'API error: status=${e.response?.statusCode} '
        'data=${e.response?.data} message=${e.message}',
      );
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 404 || statusCode == 422) {
        _throwFromResponse(e.response);
      }
      final message = _extractDetail(e.response?.data) ?? e.message ?? 'Bağlantı hatası';
      throw ApiException(message);
    } catch (e) {
      debugPrint('API error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBooks() async {
    debugPrint('Fetching books from: $baseUrl/api/v1/books');
    final response = await _request(() => _dio.get<Map<String, dynamic>>('/api/v1/books'));
    final data = response.data;
    if (data == null) return [];

    final books = data['books'];
    if (books is! List) return [];

    return books
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> createBook({
    required String title,
    required int totalPages,
    String? isbn,
    String? coverUrl,
  }) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/books',
        data: {
          'title': title,
          'total_pages': totalPages,
          if (isbn != null && isbn.isNotEmpty) 'isbn': isbn,
          if (coverUrl != null) 'cover_url': coverUrl,
        },
      ),
    );
    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<Map<String, dynamic>> searchBookByIsbn(String isbn) async {
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/v1/books/search',
        queryParameters: {'isbn': isbn},
      ),
    );
    return Map<String, dynamic>.from(response.data ?? {});
  }
}
