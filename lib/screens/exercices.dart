import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/screens/exercice.dart';

const String _kBase = 'http://192.168.0.232:5000/api';

// ─── Models ───────────────────────────────────────────────────────────────────

class NoteModel {
  final String id;
  final String text;
  final String imageUrl;
  const NoteModel({required this.id, required this.text, required this.imageUrl});

  factory NoteModel.fromJson(Map<String, dynamic> j) => NoteModel(
        id:       j['id'].toString(),
        text:     j['text']     ?? '',
        imageUrl: j['imageUrl'] ?? '',
      );
}

class ExerciceModel {
  final String id;
  final String name;
  final String imageUrl;
  final String muscle;
  final String video;
  final String description;
  final String bodyPartID;
  final List<NoteModel> notes;
  const ExerciceModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.muscle,
    required this.video,
    required this.description,
    required this.bodyPartID,
    required this.notes,
  });

  factory ExerciceModel.fromJson(Map<String, dynamic> j) => ExerciceModel(
        id:          j['id'].toString(),
        name:        j['name']        ?? '',
        imageUrl:    j['imageUrl']    ?? '',
        muscle:      j['muscle']      ?? '',
        video:       j['video']       ?? '',
        description: j['description'] ?? '',
        bodyPartID:  j['bodyPartID'].toString(),
        notes: (j['notes'] as List? ?? [])
            .map((n) => NoteModel.fromJson(n))
            .toList(),
      );

  String get typeLabel => muscle;
  String get image     => imageUrl;
}

class BodyPartModel {
  final String id;
  final String name;
  final String imageUrl;
  final List<ExerciceModel> exercices;
  const BodyPartModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.exercices,
  });

  factory BodyPartModel.fromJson(Map<String, dynamic> j) => BodyPartModel(
        id:       j['id'].toString(),
        name:     j['name']     ?? '',
        imageUrl: j['imageUrl'] ?? '',
        exercices: (j['exercises'] as List? ?? [])
            .map((e) => ExerciceModel.fromJson(e))
            .toList(),
      );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ExercicesScreen extends StatefulWidget {
  final String bodyPartID; // on passe juste l'ID, on fetch le reste
  final String bodyPartName; // pour afficher pendant le loading

  const ExercicesScreen({
    super.key,
    required this.bodyPartID,
    required this.bodyPartName,
  });

  @override
  State<ExercicesScreen> createState() => _ExercicesScreenState();
}

class _ExercicesScreenState extends State<ExercicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _expandedId;

  // ── State API ─────────────────────────────────────────────────────────────
  BodyPartModel? _bodyPart;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text.toLowerCase()),
    );
    _fetchBodyPart();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── API ───────────────────────────────────────────────────────────────────

  Future<void> _fetchBodyPart() async {
    setState(() { _loading = true; _error = null; });
    try {
      final uri = Uri.parse('$_kBase/exercice/bodyparts/${widget.bodyPartID}');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) throw Exception(body['message']);

      setState(() {
        _bodyPart = BodyPartModel.fromJson(body['data']);
        _loading  = false;
      });
    } catch (e) {
      setState(() {
        _error   = e.toString();
        _loading = false;
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<ExerciceModel> get _filtered {
    if (_bodyPart == null) return [];
    return _bodyPart!.exercices
        .where((e) => e.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

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
      bottomNavigationBar: NavBar(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: kNeonGreen, strokeWidth: 2),
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
              onTap: _fetchBodyPart,
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

    final exercises = _filtered;
    return exercises.isEmpty
        ? _buildEmpty()
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
            itemCount: exercises.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildExerciceCard(exercises[i]),
            ),
          );
  }

  // ─── TOP BAR ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
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
                Text(
                  widget.bodyPartName.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2),
                ),
                Text(
                  _bodyPart != null
                      ? '${_bodyPart!.exercices.length} exercises'
                      : '...',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.38),
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (_bodyPart != null && _bodyPart!.exercices.isNotEmpty)
            _buildTypeChip(_bodyPart!.exercices.first.typeLabel),
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
            hintText: 'Search exercises...',
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

  // ─── EXERCISE CARD ────────────────────────────────────────────────────────

  Widget _buildExerciceCard(ExerciceModel ex) {
    final isExpanded = _expandedId == ex.id;
    return Container(
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? kNeonGreen.withOpacity(0.25)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // ── Header row ──
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExerciceScreen(exerciceID: ex.id, exerciceName: ex.name,)
                ),
              );
            },
            child: SizedBox(
              height: 90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    ex.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.fitness_center,
                          color: Colors.white12, size: 28),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          kDarkCard.withOpacity(0.96),
                        ],
                        stops: const [0.25, 0.7],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        const SizedBox(width: 70),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTypeChip(ex.typeLabel),
                              const SizedBox(height: 5),
                              Text(ex.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 3),
                              Text(
                                ex.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.38),
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() =>
                              _expandedId = isExpanded ? null : ex.id),
                          child: AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(Icons.keyboard_arrow_down,
                                color: isExpanded
                                    ? kNeonGreen
                                    : Colors.white.withOpacity(0.4),
                                size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable notes ──
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: isExpanded && ex.notes.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1, color: Colors.white10),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: Text(ex.description,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 12,
                                height: 1.55)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                        child: Row(children: [
                          const Icon(Icons.format_list_bulleted,
                              color: kNeonGreen, size: 14),
                          const SizedBox(width: 6),
                          Text('INSTRUCTIONS',
                              style: TextStyle(
                                  color: kNeonGreen.withOpacity(0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1)),
                        ]),
                      ),
                      ...ex.notes.asMap().entries.map((entry) =>
                          _buildNoteItem(entry.key + 1, entry.value,
                              entry.key == ex.notes.length - 1)),
                    ],
                  )
                : isExpanded
                    ? Column(children: [
                        const Divider(height: 1, color: Colors.white10),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Icon(Icons.info_outline,
                                color: Colors.white.withOpacity(0.3),
                                size: 14),
                            const SizedBox(width: 8),
                            Text('No instructions added yet.',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 12)),
                          ]),
                        ),
                      ])
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─── Note item ────────────────────────────────────────────────────────────

  Widget _buildNoteItem(int index, NoteModel note, bool isLast) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22, height: 22,
                margin: const EdgeInsets.only(top: 1, right: 10),
                decoration: BoxDecoration(
                  color: kNeonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kNeonGreen.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text('$index',
                      style: const TextStyle(
                          color: kNeonGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(note.text,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                            height: 1.5)),
                    if (note.imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(note.imageUrl,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink()),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: Colors.white10, indent: 46),
      ],
    );
  }

  // ─── Shared ───────────────────────────────────────────────────────────────

  Widget _buildTypeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: kNeonGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kNeonGreen.withOpacity(0.22), width: 1),
      ),
      child: Text(label,
          style: const TextStyle(
              color: kNeonGreen,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6)),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center,
                color: Colors.white.withOpacity(0.1), size: 52),
            const SizedBox(height: 12),
            Text('No exercises found',
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