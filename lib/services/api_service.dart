import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_hh/constants/urls.dart';

class ApiService {
  // ════════════════════════════════════════════════════════
  //  AUTH
  // ════════════════════════════════════════════════════════

  /// Login client (email ou username + password).
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
        await _saveToken(data['token']);
        await _saveRole(data['role'] ?? 'client');
      }
      return data;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  /// Login coach (email ou username + password).
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
        await _saveToken(data['token']);
        await _saveRole('coach');
      }
      return data;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  /// Inscription client.
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
        await _saveToken(data['token']);
        await _saveRole('client');
      }
      return data;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  /// GET /auth/me — profil de l'utilisateur connecté.
  static Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/jihane/auth/me'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  /// Mot de passe oublié — client.
  static Future<Map<String, dynamic>> forgotPassword({required String email}) async {
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

  /// Mot de passe oublié — coach.
  static Future<Map<String, dynamic>> forgotPasswordCoach({required String email}) async {
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

  // ════════════════════════════════════════════════════════
  //  CLIENTS
  // ════════════════════════════════════════════════════════

  /// GET /clients — liste tous les clients (coach uniquement).
  static Future<Map<String, dynamic>> getClients() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/jihane/clients'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  /// GET /clients/:id — profil d'un client avec son coach imbriqué.
  static Future<Map<String, dynamic>> getClient(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/jihane/clients/$id'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  /// PUT /clients/:id — mise à jour du profil client.
  static Future<Map<String, dynamic>> updateClient(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$kBaseUrl/api/jihane/clients/$id'),
        headers: await _authHeaders(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  /// DELETE /clients/:id — suppression du compte client.
  static Future<Map<String, dynamic>> deleteClient(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$kBaseUrl/api/jihane/clients/$id'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  // ════════════════════════════════════════════════════════
  //  COACHES
  // ════════════════════════════════════════════════════════

  /// GET /coaches — liste tous les coaches (public).
  static Future<Map<String, dynamic>> getCoaches() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/jihane/coaches'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  /// GET /coaches/me/profile — profil du coach connecté + ses clients.
  static Future<Map<String, dynamic>> getMyCoachProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/jihane/coaches/me/profile'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  /// GET /coaches/:id — profil d'un coach par ID + ses clients.
  static Future<Map<String, dynamic>> getCoach(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/jihane/coaches/$id'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  /// PUT /coaches/:id — mise à jour du profil coach.
  static Future<Map<String, dynamic>> updateCoach(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$kBaseUrl/api/jihane/coaches/$id'),
        headers: await _authHeaders(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {'success': false, 'message': 'Serveur inaccessible (timeout).'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  // ════════════════════════════════════════════════════════
  //  TOKEN & SESSION
  // ════════════════════════════════════════════════════════

  /// Récupère le token JWT ('auth_token').
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Sauvegarde le token JWT sous la clé 'auth_token'.
  static Future<void> saveToken(String token) => _saveToken(token);

  /// Supprime le token JWT.
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Récupère le rôle de l'utilisateur connecté ('user_role').
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  /// Déconnexion : supprime token + rôle.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
  }

  // ════════════════════════════════════════════════════════
  //  HELPERS PRIVÉS
  // ════════════════════════════════════════════════════════

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> _saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}