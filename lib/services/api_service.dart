import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/receipt.dart';
import '../models/user.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  String? _token;
  int? _userId;
  String? _username;

  static String get baseUrl {
    if (Platform.isAndroid) {
      return "https://10.0.2.2:7018/api";
    }
    return "https://localhost:7018/api";
  }

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // SSL bypass for development
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return client;
    };

    // Add interceptor for token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  // Getters
  bool get isLoggedIn => _token != null;
  String? get username => _username;
  int? get userId => _userId;

  // Load token from storage
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    _userId = prefs.getInt('user_id');
    _username = prefs.getString('username');
  }

  // Save token to storage
  Future<void> _saveToken(String token, int userId, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setInt('user_id', userId);
    await prefs.setString('username', username);
    _token = token;
    _userId = userId;
    _username = username;
  }

  // Clear token
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    await prefs.remove('username');
    _token = null;
    _userId = null;
    _username = null;
  }

  // ==================== AUTH ====================

  Future<ApiResponse<AuthResponse>> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      final apiResponse = ApiResponse<AuthResponse>.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json),
      );

      if (apiResponse.success && apiResponse.data != null) {
        await _saveToken(
          apiResponse.data!.token,
          apiResponse.data!.userId,
          apiResponse.data!.username,
        );
      }

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  Future<ApiResponse<AuthResponse>> register(String username, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
      });

      final apiResponse = ApiResponse<AuthResponse>.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json),
      );

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // ==================== RECEIPTS ====================

  Future<ApiResponse<List<Receipt>>> getReceipts() async {
    try {
      final response = await _dio.get('/receipts');

      final apiResponse = ApiResponse<List<Receipt>>.fromJson(
        response.data,
        (json) => (json as List).map((e) => Receipt.fromJson(e)).toList(),
      );

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  Future<ApiResponse<Receipt>> getReceiptById(int id) async {
    try {
      final response = await _dio.get('/receipts/$id');

      return ApiResponse<Receipt>.fromJson(
        response.data,
        (json) => Receipt.fromJson(json),
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  Future<ApiResponse<Receipt>> createReceipt(CreateReceiptRequest request) async {
    try {
      final response = await _dio.post('/receipts', data: request.toJson());

      return ApiResponse<Receipt>.fromJson(
        response.data,
        (json) => Receipt.fromJson(json),
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  Future<ApiResponse<Receipt>> updateReceipt(int id, CreateReceiptRequest request) async {
    try {
      final response = await _dio.put('/receipts/$id', data: request.toJson());

      return ApiResponse<Receipt>.fromJson(
        response.data,
        (json) => Receipt.fromJson(json),
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  Future<ApiResponse<void>> deleteReceipt(int id) async {
    try {
      final response = await _dio.delete('/receipts/$id');

      return ApiResponse(
        success: response.data['success'] ?? true,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // ==================== OCR ====================

  Future<ApiResponse<Map<String, dynamic>>> scanReceipt(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/receipts/scan',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // ==================== CATEGORIES ====================

  Future<ApiResponse<List<Category>>> getCategories() async {
    try {
      final response = await _dio.get('/categories');

      return ApiResponse<List<Category>>.fromJson(
        response.data,
        (json) => (json as List).map((e) => Category.fromJson(e)).toList(),
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  Future<ApiResponse<Category>> createCategory(String name, String? description, String? iconName) async {
    try {
      final response = await _dio.post('/categories', data: {
        'name': name,
        'description': description,
        'iconName': iconName,
      });

      return ApiResponse<Category>.fromJson(
        response.data,
        (json) => Category.fromJson(json),
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  Future<ApiResponse<void>> deleteCategory(int id) async {
    try {
      final response = await _dio.delete('/categories/$id');

      return ApiResponse(
        success: response.data['success'] ?? true,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // ==================== STORES ====================

  Future<ApiResponse<List<Store>>> getStores() async {
    try {
      final response = await _dio.get('/stores');

      return ApiResponse<List<Store>>.fromJson(
        response.data,
        (json) => (json as List).map((e) => Store.fromJson(e)).toList(),
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // ==================== DASHBOARD & STATS ====================

  Future<ApiResponse<DashboardStats>> getDashboardStats() async {
    try {
      final response = await _dio.get('/receipts/stats');

      return ApiResponse<DashboardStats>.fromJson(
        response.data,
        (json) => DashboardStats.fromJson(json),
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  Future<ApiResponse<List<StoreSpending>>> getStoreStats() async {
    try {
      final response = await _dio.get('/receipts/store-stats');

      return ApiResponse<List<StoreSpending>>.fromJson(
        response.data,
        (json) => (json as List).map((e) => StoreSpending.fromJson(e)).toList(),
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  Future<ApiResponse<List<DailySpending>>> getDailySpending(int year, int month) async {
    try {
      final response = await _dio.get('/receipts/daily-spending', queryParameters: {
        'year': year,
        'month': month,
      });

      return ApiResponse<List<DailySpending>>.fromJson(
        response.data,
        (json) => (json as List).map((e) => DailySpending.fromJson(e)).toList(),
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // ==================== SEARCH ====================

  Future<ApiResponse<List<Receipt>>> searchReceipts(String query) async {
    try {
      final response = await _dio.get('/receipts/search', queryParameters: {
        'query': query,
      });

      return ApiResponse<List<Receipt>>.fromJson(
        response.data,
        (json) => (json as List).map((e) => Receipt.fromJson(e)).toList(),
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  // ==================== HELPERS ====================

  String _getErrorMessage(DioException e) {
    if (e.response != null) {
      if (e.response!.data is Map) {
        return e.response!.data['message'] ?? 'An error occurred';
      }
      return 'Server error: ${e.response!.statusCode}';
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Could not connect to server';
    }
    return 'An error occurred';
  }
}

// ==================== RESPONSE MODELS ====================

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final List<String>? errors;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'])
          : null,
    );
  }
}

// ==================== CATEGORIES ====================

class Category {
  final int id;
  final String name;
  final String? description;
  final String? iconName;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      iconName: json['iconName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
    };
  }
}

class Store {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? taxNumber;

  Store({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.taxNumber,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      phone: json['phone'],
      taxNumber: json['taxNumber'],
    );
  }
}

class DashboardStats {
  final double totalMonthlySpending;
  final double averageReceiptValue;
  final String mostFrequentStore;
  final int mostFrequentStoreVisitCount;

  DashboardStats({
    required this.totalMonthlySpending,
    required this.averageReceiptValue,
    required this.mostFrequentStore,
    required this.mostFrequentStoreVisitCount,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalMonthlySpending: (json['totalMonthlySpending'] ?? 0).toDouble(),
      averageReceiptValue: (json['averageReceiptValue'] ?? 0).toDouble(),
      mostFrequentStore: json['mostFrequentStore'] ?? '-',
      mostFrequentStoreVisitCount: json['mostFrequentStoreVisitCount'] ?? 0,
    );
  }
}

class StoreSpending {
  final String storeName;
  final double totalSpending;
  final int receiptCount;

  StoreSpending({
    required this.storeName,
    required this.totalSpending,
    required this.receiptCount,
  });

  factory StoreSpending.fromJson(Map<String, dynamic> json) {
    return StoreSpending(
      storeName: json['storeName'] ?? '',
      totalSpending: (json['totalSpending'] ?? 0).toDouble(),
      receiptCount: json['receiptCount'] ?? 0,
    );
  }
}

class DailySpending {
  final String date;
  final double amount;

  DailySpending({
    required this.date,
    required this.amount,
  });

  factory DailySpending.fromJson(Map<String, dynamic> json) {
    return DailySpending(
      date: json['date'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}