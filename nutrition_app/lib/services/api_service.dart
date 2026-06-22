import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._privateConstructor();

  static const _tokenKey = "jwt_token";
  static const _usernameKey = "username";
  static const _emailKey = "email";

  static String? _token;
  static String? _username;
  static String? _email;

  // ── Base URL ──────────────────────────────────────────────
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:8000";
    if (Platform.isAndroid) return "http://10.135.128.228:8000";
    return "http://10.135.128.228:8000";
  }

  // ── Exposed getters ───────────────────────────────────────
  static String? get token => _token;
  static String get username => _username ?? '';
  static String get email => _email ?? '';

  // ── Init (call once in main.dart) ─────────────────────────
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _username = prefs.getString(_usernameKey);
    _email = prefs.getString(_emailKey);
  }

  // ── Internal helpers ──────────────────────────────────────
  static Future<void> _saveToken(
    String token,
    String username,
    String email,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_emailKey, email);
    _token = token;
    _username = username;
    _email = email;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_emailKey);
    _token = null;
    _username = null;
    _email = null;
  }

  static Map<String, String> _authHeaders() => {
    HttpHeaders.contentTypeHeader: "application/json",
    if (_token != null) HttpHeaders.authorizationHeader: "Bearer $_token",
  };

  // ── Auth ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/auth/login");
    try {
      final response = await http.post(
        url,
        headers: {HttpHeaders.contentTypeHeader: "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["token"] != null) {
        await _saveToken(data["token"], data["user"]["username"] ?? "", email);
        return {"success": true};
      }
      return {"success": false, "error": data["detail"] ?? "Login failed"};
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/auth/register");
    try {
      final response = await http.post(
        url,
        headers: {HttpHeaders.contentTypeHeader: "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data["token"] != null) {
        await _saveToken(data["token"], username, email);
        return {"success": true};
      }
      return {
        "success": false,
        "error": data["detail"] ?? "Registration failed",
      };
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // ── Predictions ───────────────────────────────────────────
  static Future<Map<String, dynamic>> predictImage(
    File imageFile,
    String mealType,
  ) async {
    final url = Uri.parse("$baseUrl/api/predict");
    final request = http.MultipartRequest('POST', url);
    request.headers.addAll(_authHeaders());
    request.fields["meal_type"] = mealType;
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );
    final streamed = await request.send();
    final respStr = await streamed.stream.bytesToString();
    return jsonDecode(respStr);
  }

  static Future<Map<String, dynamic>> predictManual(
    String foodName,
    String mealType,
    String servingSize,
  ) async {
    final url = Uri.parse("$baseUrl/api/predict/manual");
    try {
      final response = await http
          .post(
            url,
            headers: _authHeaders(),
            body: jsonEncode({
              "food_name": foodName,
              "meal_type": mealType,
              "serving_size": servingSize,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Request timed out or failed: ${e.toString()}"};
    }
  }

  static Future<Map<String, dynamic>?> lookupCalories(String foodName) async {
    // 1. Check 34 hardcoded classes via backend calorie mapper
    final url = Uri.parse("$baseUrl/api/calories/lookup");
    try {
      final response = await http
          .post(
            url,
            headers: _authHeaders(),
            body: jsonEncode({"food_name": foodName}),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['is_unknown'] != true) return data;
      }
    } catch (_) {}

    // 2. Fallback to USDA via existing predictManual route
    try {
      final usda = await predictManual(foodName, "lunch", "medium");
      if (usda['is_unknown'] != true && usda.containsKey('calorie_min')) {
        return usda;
      }
    } catch (_) {}

    return null; // both failed — caller keeps old values
  }

  // ── Meals ─────────────────────────────────────────────────
  static Future<bool> saveMeal(Map<String, dynamic> mealData) async {
    final url = Uri.parse("$baseUrl/api/meals");
    final response = await http.post(
      url,
      headers: _authHeaders(),
      body: jsonEncode(mealData),
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<bool> updateMeal(
    int mealId,
    Map<String, dynamic> mealData,
  ) async {
    final url = Uri.parse("$baseUrl/api/meals/$mealId");
    final response = await http.put(
      url,
      headers: _authHeaders(),
      body: jsonEncode(mealData),
    );
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> fetchMeals() async {
    final url = Uri.parse("$baseUrl/api/meals");
    final response = await http.get(url, headers: _authHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  // ── Analytics ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchAnalyticsSummary() async {
    final url = Uri.parse("$baseUrl/api/analytics/summary");
    try {
      final response = await http
          .get(url, headers: _authHeaders())
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {
        "error": "Analytics summary failed (${response.statusCode})",
        "statusCode": response.statusCode,
      };
    } catch (e) {
      return {"error": "Analytics summary failed: ${e.toString()}"};
    }
  }

  static Future<List<dynamic>> fetchAnalyticsWeekly() async {
    final url = Uri.parse("$baseUrl/api/analytics/weekly");
    try {
      final response = await http.get(url, headers: _authHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body) as List;
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> fetchAnalyticsUnhealthy() async {
    final url = Uri.parse("$baseUrl/api/analytics/unhealthy");
    try {
      final response = await http.get(url, headers: _authHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body) as List;
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> fetchMealTypeBreakdown() async {
    final url = Uri.parse("$baseUrl/api/analytics/meal-types");
    try {
      final response = await http.get(url, headers: _authHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return {};
  }

  static Future<Map<String, dynamic>> fetchAnalyticsOverview() async {
    final url = Uri.parse("$baseUrl/api/analytics/all");
    try {
      final response = await http
          .get(url, headers: _authHeaders())
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {
        "error": "Analytics overview failed (${response.statusCode})",
        "statusCode": response.statusCode,
      };
    } catch (e) {
      return {"error": "Analytics overview failed: ${e.toString()}"};
    }
  }
}
