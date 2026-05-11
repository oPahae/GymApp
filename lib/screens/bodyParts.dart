import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/screens/exercices.dart';
import 'package:test_hh/services/api_service.dart';
import 'package:test_hh/session/user_session.dart'; // ← ajout

const String _kBase = 'http://192.168.0.232:5000/api';

// ─── Model ────────────────────────────────────────────────────────────────────

class BodyPartModel {
  final String id;
  final String name;
  final String imageUrl;
  final int exerciceCount;

  const BodyPartModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.exerciceCount,
  });

  factory BodyPartModel.fromJson(Map<String, dynamic> j) => BodyPartModel(
        id: j['id'].toString(),
        name: j['name'] ?? '',
        imageUrl: j['imageUrl'] ?? '',
        exerciceCount: (j['exercises'] as List? ?? []).length,
      );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class BodyPartsScreen extends StatefulWidget {
  const BodyPartsScreen({super.key});

  @override
  State<BodyPartsScreen> createState() => _BodyPartsScreenState();
}

class _BodyPartsScreenState extends State<BodyPartsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ── Session — lue directement depuis UserSession ──────────────────────────
  // Plus de _userName / _userRole comme champs séparés ni de Future de session.
  String get _userName => UserSession.instance.name;
  String get _userRole => UserSession.instance.role;

  // ── State API ─────────────────────────────────────────────────────────────
  List<BodyPartModel> _bodyParts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () =>
          setState(() => _searchQuery = _searchController.text.toLowerCase()),
    );
    // La session est déjà chargée — on fetch directement les données.
    _fetchBodyParts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── API ───────────────────────────────────────────────────────────────────

  Future<void> _fetchBodyParts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await ApiService.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('$_kBase/exercice/bodyparts');
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) throw Exception(body['message']);

      final list = (body['data'] as List)
          .map((e) => BodyPartModel.fromJson(e))
          .toList();

      setState(() {
        _bodyParts = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<BodyPartModel> get _filtered => _bodyParts
      .where((b) => b.name.toLowerCase().contains(_searchQuery))
      .toList();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: Header(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildSearchBar(),
            const SizedBox(height: 14),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(selectedIndex: 2),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(color: kNeonGreen, strokeWidth: 2),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_wifi_off,
                color: Colors.white.withOpacity(0.12), size: 36),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _fetchBodyParts,
              child: Text('Réessayer',
                  style: TextStyle(
                      color: kNeonGreen.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    final parts = _filtered;
    return parts.isEmpty
        ? _buildEmpty()
        : GridView.builder(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: parts.length,
            itemBuilder: (_, i) => _buildBodyPartCard(parts[i]),
          );
  }

  // ─── TOP BAR ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    // Nom affiché selon le rôle, lu depuis UserSession
    final displayName = UserSession.instance.isLoaded
        ? (_userRole == 'coach' ? 'Coach · $_userName' : _userName)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: kDarkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BODY PARTS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
                // Nom du user connecté lu depuis UserSession
                if (displayName != null && displayName.isNotEmpty)
                  Text(
                    displayName,
                    style: TextStyle(
                        color: kNeonGreen.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kNeonGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kNeonGreen.withOpacity(0.3)),
            ),
            child: Text(
              '${_bodyParts.length} GROUPS',
              style: const TextStyle(
                  color: kNeonGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEARCH BAR ───────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search muscle group...',
            hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3), fontSize: 14),
            prefixIcon: Icon(Icons.search,
                color: Colors.white.withOpacity(0.3), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: Icon(Icons.close,
                        color: Colors.white.withOpacity(0.3), size: 18),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ─── BODY PART CARD ───────────────────────────────────────────────────────

  Widget _buildBodyPartCard(BodyPartModel part) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExercicesScreen(
            bodyPartID: part.id,
            bodyPartName: part.name,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              part.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1A1A1A),
                child: const Icon(Icons.fitness_center,
                    color: Colors.white12, size: 40),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.88)
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        '${part.exerciceCount} exercises',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    part.name.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 8)
                        ]),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('EXPLORE',
                          style: TextStyle(
                              color: kNeonGreen.withOpacity(0.85),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          color: kNeonGreen.withOpacity(0.85), size: 10),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                color: Colors.white.withOpacity(0.12), size: 52),
            const SizedBox(height: 12),
            Text('No results found',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.28),
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}