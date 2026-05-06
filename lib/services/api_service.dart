import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_hh/constants/urls.dart';

class ApiService {
  // ── AUTH ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/jihane/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['token'] != null) {
        await saveToken(data['token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', data['role'] ?? 'client');
      }
      return data;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? image,
    String? birth,
    double? weight,
    double? height,
    int? frequency,
    String? goal,
    double? weightGoal,
    String? gender,
    int? coachID,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/jihane/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          if (image != null) 'image': image,
          if (birth != null) 'birth': birth,
          if (weight != null) 'weight': weight,
          if (height != null) 'height': height,
          if (frequency != null) 'frequency': frequency,
          if (goal != null) 'goal': goal,
          if (weightGoal != null) 'weightGoal': weightGoal,
          if (gender != null) 'gender': gender,
          if (coachID != null) 'coachID': coachID,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['token'] != null) {
        await saveToken(data['token']);
      }
      return data;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getMe() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/jihane/auth/me'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/jihane/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  // ── CLIENT ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getClient(int id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/jihane/clients/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateClient(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$kBaseUrl/api/jihane/clients/$id'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  // ── COACH ─────────────────────────────────────────────────────────────────

  /// Retourne le profil du coach connecté + ses clients
  static Future<Map<String, dynamic>> getMyCoachProfile() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/jihane/coaches/me/profile'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getCoach(int id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/jihane/coaches/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateCoach(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$kBaseUrl/api/jihane/coaches/$id'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getCoaches() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/jihane/coaches'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> loginCoach({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/jihane/coaches/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['token'] != null) {
        await saveToken(data['token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', 'coach');
      }
      return data;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> forgotPasswordCoach({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/jihane/coaches/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  // ── TOKEN ─────────────────────────────────────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<void> logout() async => clearToken();

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}