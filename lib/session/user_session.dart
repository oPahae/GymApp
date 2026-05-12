import 'package:test_hh/services/api_service.dart';
import 'package:flutter/foundation.dart';

/// Singleton léger qui cache le profil du user connecté.
/// À appeler une seule fois après login, puis accessible partout.
class UserSession {
  UserSession._();
  static final UserSession instance = UserSession._();

  // ── Données brutes retournées par /auth/me ──────────────────────────────
  Map<String, dynamic>? _raw;

  // ── Getters typés ───────────────────────────────────────────────────────
  int    get id        => _raw?['id']        ?? 0;
  String get name      => _raw?['name']      ?? '';
  String get email     => _raw?['email']     ?? '';
  String get role      => _raw?['role']      ?? 'client';
  String get gender    => _raw?['gender']    ?? '';
  String get image     => _raw?['image']     ?? '';
  String get birth     => _raw?['birth']     ?? '';
  double get weight    => (_raw?['weight']   as num?)?.toDouble() ?? 0;
  double get height    => (_raw?['height']   as num?)?.toDouble() ?? 0;
  int    get frequency => (_raw?['frequency'] as num?)?.toInt() ?? 0;
  String get goal      => _raw?['goal']      ?? '';
  double get weightGoal => (_raw?['weightGoal'] as num?)?.toDouble() ?? 0;
  int?   get coachID   => _raw?['coachID'];

  bool get isLoaded => _raw != null;
  bool get isCoach  => role == 'coach';
  bool get isClient => role == 'client';

  // ── Chargement ──────────────────────────────────────────────────────────

  /// Charge (ou recharge) le profil depuis l'API.
  /// Retourne true si succès.
  Future<bool> load() async {
  final result = await ApiService.getMe();

  if (result['success'] == true) {
    final raw = result['coach'] ?? result['client'] ?? result['user'] ?? result;
    _raw = Map<String, dynamic>.from(raw as Map);
    _raw!['role'] = result['role'] ?? 'coach';

    // 👇 Ajoutez ce print
    print('=== RAW BEFORE PARSE: ${_raw}');
    print('=== id field: ${_raw!['id']} (type: ${_raw!['id'].runtimeType})');

    final rawId = _raw!['id'];
    if (rawId is String) _raw!['id'] = int.tryParse(rawId) ?? 0;

    print('id: $id, role: $role, name: $name');
    return id > 0;
  }
  return false;
}

  /// Efface la session (logout).
  void clear() => _raw = null;

  /// Accès brut si besoin d'un champ non exposé.
  dynamic operator [](String key) => _raw?[key];
}