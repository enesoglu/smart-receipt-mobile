import 'package:dio/dio.dart';
import '../models/receipt.dart';
import 'package:dio/io.dart';
import 'dart:io';

class ApiService {
  final Dio _dio = Dio();

  final String baseUrl = "http://10.0.2.2:5069/api/receipts";

  ApiService() {
    // ssl bypass
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  // get all receipts
  Future<List<Receipt>> getReceipts() async {
    try {
      final response = await _dio.get(baseUrl);
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Receipt.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching receipts: $e");
      return [];
    }
  }

  // add new receipt
  Future<bool> addReceipt(Receipt receipt) async {
    try {
      final response = await _dio.post(baseUrl, data: receipt.toJson());
      return response.statusCode == 201;
    } catch (e) {
      print("Error adding receipt: $e");
      return false;
    }
  }

  // dashboard data
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _dio.get("$baseUrl/dashboard-stats");
      return response.data;
    } catch (e) {
      return {};
    }
  }
}