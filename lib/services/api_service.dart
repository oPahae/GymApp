import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:5000/api'; // Utiliser 10.0.2.2 pour l'émulateur Android

  // Gestion du token
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

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': identifier,
        'password': password,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true && data['token'] != null) {
      await saveToken(data['token']);
    }
    return data;
  }

  // Register
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
  int? coachID, // Peut être null
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/auth/register'),
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
      if (coachID != null) 'coachID': coachID, // Envoyé uniquement si non null
    }),
  );
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  if (data['success'] == true && data['token'] != null) {
    await saveToken(data['token']);
  }
  return data;
}

  // Autres méthodes (inchangées)
  static Future<Map<String, dynamic>> getMe() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$_baseUrl/auth/me'), headers: headers);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    await clearToken();
  }
}