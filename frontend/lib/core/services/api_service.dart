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
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  static const String baseUrl = 'http://192.168.1.236:8000';

  final Dio _dio;
  final FirebaseAuth _auth;

  Future<Options> _authOptions() async {
    final user = _auth.currentUser;
    if (user == null) throw UnauthorizedException('Giriş gerekli');
    final token = await user.getIdToken(true);
    return Options(headers: {'Authorization': 'Bearer $token'});
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
    final response = await _request(
      () async => _dio.get<Map<String, dynamic>>(
        '/api/v1/books',
        options: await _authOptions(),
      ),
    );
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
      () async => _dio.post<Map<String, dynamic>>(
        '/api/v1/books',
        data: {
          'title': title,
          'total_pages': totalPages,
          if (isbn != null && isbn.isNotEmpty) 'isbn': isbn,
          if (coverUrl != null) 'cover_url': coverUrl,
        },
        options: await _authOptions(),
      ),
    );
    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<Map<String, dynamic>> searchBookByIsbn(String isbn) async {
    final response = await _request(
      () async => _dio.get<Map<String, dynamic>>(
        '/api/v1/books/search',
        queryParameters: {'isbn': isbn},
        options: await _authOptions(),
      ),
    );
    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<List<Map<String, dynamic>>> searchBooksByTitle(String query) async {
    final response = await _request(
      () async => _dio.get<Map<String, dynamic>>(
        '/api/v1/books/search',
        queryParameters: {'q': query},
        options: await _authOptions(),
      ),
    );
    final data = response.data;
    if (data == null) return [];
    final results = data['results'];
    if (results is! List) return [];
    return results
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> createSession(Map<String, dynamic> data) async {
    await _request(
      () async => _dio.post<Map<String, dynamic>>(
        '/api/v1/sessions',
        data: data,
        options: await _authOptions(),
      ),
    );
  }

  Future<Map<String, dynamic>> getBook(String id) async {
    final response = await _request(
      () async => _dio.get<Map<String, dynamic>>(
        '/api/v1/books/$id',
        options: await _authOptions(),
      ),
    );
    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<Map<String, dynamic>?> getBookPace(String id) async {
    try {
      final response = await _request(
        () async => _dio.get<Map<String, dynamic>>(
          '/api/v1/books/$id/pace',
          options: await _authOptions(),
        ),
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } on ValidationException {
      return null;
    } on NotFoundException {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getSessions(String bookId) async {
    try {
      final response = await _request(
        () async => _dio.get<Map<String, dynamic>>(
          '/api/v1/sessions',
          queryParameters: {'book_id': bookId},
          options: await _authOptions(),
        ),
      );
      final data = response.data;
      if (data == null) return [];
      final sessions = data['sessions'];
      if (sessions is! List) return [];
      return sessions
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on UnauthorizedException {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final response = await _request(
      () async => _dio.get<List<dynamic>>(
        '/api/v1/stats/weekly',
        options: await _authOptions(),
      ),
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> getYearlyStats() async {
    final response = await _request(
      () async => _dio.get<Map<String, dynamic>>(
        '/api/v1/stats/yearly',
        options: await _authOptions(),
      ),
    );
    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<Map<String, dynamic>> getStreakStats() async {
    final response = await _request(
      () async => _dio.get<Map<String, dynamic>>(
        '/api/v1/stats/streak',
        options: await _authOptions(),
      ),
    );
    return Map<String, dynamic>.from(response.data ?? {});
  }

  Future<Map<String, dynamic>> getHeatmap() async {
    final response = await _request(
      () async => _dio.get<Map<String, dynamic>>(
        '/api/v1/stats/heatmap',
        options: await _authOptions(),
      ),
    );
    return Map<String, dynamic>.from(response.data ?? {});
  }
}
