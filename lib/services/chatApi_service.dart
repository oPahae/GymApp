import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_hh/constants/urls.dart';

class ChatApiService {
  static String get _baseUrl => '$kBaseUrl/api/jihane/chat';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = jsonDecode(response.body);
      throw ApiException(
        statusCode: response.statusCode,
        message: body['message'] ?? 'Erreur inconnue',
      );
    }
  }

  // Récupère les conversations du coach
  static Future<List<Map<String, dynamic>>> getConversations() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/conversations'),
      headers: await _headers(),
    );
    _checkStatus(response);
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['conversations']);
  }

  // Récupère les messages entre un coach et un client
  static Future<List<Map<String, dynamic>>> getMessages({
    required int coachId,
    required int clientId,
    int limit = 50,
    int? before,
  }) async {
    final uri = Uri.parse('$_baseUrl/messages/$coachId/$clientId').replace(
      queryParameters: {
        'limit': limit.toString(),
        if (before != null) 'before': before.toString(),
      },
    );
    final response = await http.get(uri, headers: await _headers());
    _checkStatus(response);
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['messages']);
  }

  // Envoyer un message (texte ou audio)
  static Future<Map<String, dynamic>> sendMessage({
    required int coachId,
    required int clientId,
    String? text,
    String type = 'text',
    String? mediaUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/messages'),
      headers: await _headers(),
      body: jsonEncode({
        'coachId': coachId,
        'clientId': clientId,
        if (text != null) 'text': text,
        'type': type,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
      }),
    );
    _checkStatus(response);
    final data = jsonDecode(response.body);
    return Map<String, dynamic>.from(data['message']);
  }

  // Upload un fichier audio
  static Future<String> uploadAudio(File audioFile) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload-audio'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: data['message'] ?? 'Erreur lors de l\'upload du fichier audio.',
      );
    }

    return data['audioUrl'];
  }

  // Mettre à jour le statut d'un message
  static Future<void> updateMessageStatus({
    required int messageId,
    required String status,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/messages/$messageId/status'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );
    _checkStatus(response);
  }

  // Supprimer un message
  static Future<void> deleteMessage(int messageId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/messages/$messageId'),
      headers: await _headers(),
    );
    _checkStatus(response);
  }

  // Initier un appel
  static Future<Map<String, dynamic>> startCall({
    required int coachId,
    required int clientId,
    required String callType,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/calls'),
      headers: await _headers(),
      body: jsonEncode({
        'coachId': coachId,
        'clientId': clientId,
        'callType': callType,
      }),
    );
    _checkStatus(response);
    final data = jsonDecode(response.body);
    return Map<String, dynamic>.from(data['call']);
  }

  // Mettre à jour le statut d'un appel
  static Future<Map<String, dynamic>> updateCallStatus({
    required int callId,
    required String status,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/calls/$callId'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );
    _checkStatus(response);
    final data = jsonDecode(response.body);
    return Map<String, dynamic>.from(data['call']);
  }

  // Historique des appels
  static Future<List<Map<String, dynamic>>> getCallHistory({
    required int coachId,
    required int clientId,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/calls/$coachId/$clientId'),
      headers: await _headers(),
    );
    _checkStatus(response);
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['calls']);
  }

  // Vérifier s'il y a un appel actif
  static Future<Map<String, dynamic>?> getActiveCall({
    required int coachId,
    required int clientId,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/calls/active/$coachId/$clientId'),
      headers: await _headers(),
    );
    _checkStatus(response);
    final data = jsonDecode(response.body);
    return data['activeCall'] != null
        ? Map<String, dynamic>.from(data['activeCall'])
        : null;
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}