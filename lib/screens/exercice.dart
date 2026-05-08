import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/screens/tutorial.dart';
import 'package:test_hh/constants/urls.dart';

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

class PartModel {
  final String id;
  final String name;
  final String imageUrl;
  const PartModel({required this.id, required this.name, required this.imageUrl});

  factory PartModel.fromJson(Map<String, dynamic> j) => PartModel(
        id:       j['id'].toString(),
        name:     j['name']     ?? '',
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
  final PartModel part;

  const ExerciceModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.muscle,
    required this.video,
    required this.description,
    required this.bodyPartID,
    required this.notes,
    required this.part,
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
        part: j['part'] != null
            ? PartModel.fromJson(j['part'])
            : const PartModel(id: '', name: '', imageUrl: ''),
      );

  String get typeLabel => muscle;
  String get image     => imageUrl;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ExerciceScreen extends StatefulWidget {
  final String exerciceID;
  final String exerciceName; // pour afficher pendant le loading

  const ExerciceScreen({
    super.key,
    required this.exerciceID,
    required this.exerciceName,
  });

  @override
  State<ExerciceScreen> createState() => _ExerciceScreenState();
}

class _ExerciceScreenState extends State<ExerciceScreen> {
  ExerciceModel? _exercice;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchExercice();
  }

  // ── API ───────────────────────────────────────────────────────────────────

  Future<void> _fetchExercice() async {
    setState(() { _loading = true; _error = null; });
    try {
      final uri = Uri.parse('$kBaseUrl/api/exercice/${widget.exerciceID}');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) throw Exception(body['message']);

      setState(() {
        _exercice = ExerciceModel.fromJson(body['data']);
        _loading  = false;
      });
    } catch (e) {
      setState(() {
        _error   = e.toString();
        _loading = false;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: kDarkBg,
        appBar: Header(),
        body: const Center(
          child: CircularProgressIndicator(color: kNeonGreen, strokeWidth: 2),
        ),
        // bottomNavigationBar: NavBar(),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: kDarkBg,
        appBar: Header(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.signal_wifi_off,
                  color: Colors.white.withOpacity(0.12), size: 36),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _fetchExercice,
                child: Text('Réessayer',
                    style: TextStyle(
                        color: kNeonGreen.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        // bottomNavigationBar: NavBar(),
      );
    }

    final ex = _exercice!;
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: Header(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHero(context, ex)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  _buildInfoRow(context, ex),
                  const SizedBox(height: 20),
                  _buildDescriptionCard(ex),
                  const SizedBox(height: 14),
                  if (ex.notes.isNotEmpty) ...[
                    _buildSectionHeader(Icons.format_list_bulleted, 'INSTRUCTIONS'),
                    const SizedBox(height: 10),
                    _buildNotesList(ex),
                    const SizedBox(height: 14),
                  ],
                  _buildTutorialBanner(context, ex),
                ]),
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: NavBar(),
    );
  }

  // ─── HERO ─────────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context, ExerciceModel ex) {
    return Stack(
      children: [
        SizedBox(
          height: 260,
          width: double.infinity,
          child: Image.network(
            ex.image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1A1A1A),
              child: const Icon(Icons.fitness_center,
                  color: Colors.white12, size: 52),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, kDarkBg],
                stops: [0.45, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 16),
                  ),
                ),
                const Spacer(),
                _buildTypeChip(ex.typeLabel),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16, left: 18, right: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ex.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 10)])),
              const SizedBox(height: 4),
              Text(ex.part.name.toUpperCase(),
                  style: TextStyle(
                      color: kNeonGreen.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── INFO ROW ─────────────────────────────────────────────────────────────

  Widget _buildInfoRow(BuildContext context, ExerciceModel ex) {
    return Row(
      children: [
        _buildStatCard(Icons.local_fire_department_outlined, ex.typeLabel, 'Type'),
        const SizedBox(width: 10),
        _buildStatCard(Icons.notes_rounded, '${ex.notes.length}', 'Steps'),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => TutorialScreen(exercice: ex))),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              decoration: BoxDecoration(
                color: kNeonGreen,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: kNeonGreen.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline, color: Colors.black, size: 18),
                  SizedBox(width: 6),
                  Text('TUTORIAL',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: kNeonGreen, size: 16),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ─── DESCRIPTION ──────────────────────────────────────────────────────────

  Widget _buildDescriptionCard(ExerciceModel ex) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.info_outline, 'ABOUT'),
          const SizedBox(height: 10),
          Text(ex.description,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 13,
                  height: 1.65)),
        ],
      ),
    );
  }

  // ─── NOTES LIST ───────────────────────────────────────────────────────────

  Widget _buildNotesList(ExerciceModel ex) {
    return Container(
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: ex.notes.asMap().entries.map((entry) {
          return _buildNoteItem(
              entry.key + 1, entry.value, entry.key == ex.notes.length - 1);
        }).toList(),
      ),
    );
  }

  Widget _buildNoteItem(int index, NoteModel note, bool isLast) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24, height: 24,
                margin: const EdgeInsets.only(top: 1, right: 12),
                decoration: BoxDecoration(
                  color: kNeonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(7),
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
                    Text(note.text,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                            height: 1.55)),
                    if (note.imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(note.imageUrl,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: Colors.white10, indent: 50),
      ],
    );
  }

  // ─── TUTORIAL BANNER ──────────────────────────────────────────────────────

  Widget _buildTutorialBanner(BuildContext context, ExerciceModel ex) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TutorialScreen(exercice: ex))),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kNeonGreen.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: kNeonGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kNeonGreen.withOpacity(0.25)),
              ),
              child: const Icon(Icons.play_circle_filled_rounded,
                  color: kNeonGreen, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Watch Tutorial',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('Step-by-step video guide for ${ex.name}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.38), fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: kNeonGreen.withOpacity(0.7), size: 14),
          ],
        ),
      ),
    );
  }

  // ─── Shared ───────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: kNeonGreen, size: 14),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: kNeonGreen.withOpacity(0.9),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      ],
    );
  }

  Widget _buildTypeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kNeonGreen.withOpacity(0.35)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: kNeonGreen,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8)),
    );
  }
}