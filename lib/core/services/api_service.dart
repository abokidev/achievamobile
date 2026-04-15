import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/strings.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? AppStrings.baseUrl,
        _client = client ?? http.Client();

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyNin(
      String nin, String dob, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/nin/verify'),
      headers: _headers(token: token),
      body: jsonEncode({'nin': nin, 'dob': dob}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyFace(
      String imageBase64, String nin, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/face/verify'),
      headers: _headers(token: token),
      body: jsonEncode({'image_base64': imageBase64, 'nin': nin}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getExamInfo(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/exam/info'),
      headers: _headers(token: token),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getExamQuestions(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/exam/questions'),
      headers: _headers(token: token),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return body is List ? body : body['questions'] ?? [];
    }
    throw ApiException(body['message'] ?? 'Failed to load questions');
  }

  Future<Map<String, dynamic>> submitExam(
      List<Map<String, dynamic>> answers, int durationSeconds, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/exam/submit'),
      headers: _headers(token: token),
      body: jsonEncode({
        'answers': answers,
        'duration_taken_seconds': durationSeconds,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> sendProctorSnapshot(
      String imageBase64, String eventType, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/proctor/snapshot'),
      headers: _headers(token: token),
      body: jsonEncode({
        'image_base64': imageBase64,
        'event_type': eventType,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> sendProctorEvent(
      String type, String timestamp, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/proctor/event'),
      headers: _headers(token: token),
      body: jsonEncode({
        'type': type,
        'timestamp': timestamp,
      }),
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      body['message'] ?? 'Request failed with status ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
