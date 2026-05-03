import 'package:flutter/material.dart';
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/models/exercice.dart';
import 'package:test_hh/models/notes.dart';
import 'package:test_hh/screens/tutorial.dart';

class ExerciceScreen extends StatelessWidget {
  final ExerciceModel exercice;

  const ExerciceScreen({super.key, required this.exercice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: Header(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHero(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  _buildInfoRow(context),
                  const SizedBox(height: 20),
                  _buildDescriptionCard(),
                  const SizedBox(height: 14),
                  if (exercice.notes.isNotEmpty) ...[
                    _buildSectionHeader(
                        Icons.format_list_bulleted, 'INSTRUCTIONS'),
                    const SizedBox(height: 10),
                    _buildNotesList(),
                    const SizedBox(height: 14),
                  ],
                  _buildTutorialBanner(context),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(),
    );
  }

  // ─── HERO ────────────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context) {
    return Stack(
      children: [
        // Full-width image
        SizedBox(
          height: 260,
          width: double.infinity,
          child: Image.network(
            exercice.image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1A1A1A),
              child: const Icon(Icons.fitness_center,
                  color: Colors.white12, size: 52),
            ),
          ),
        ),
        // Bottom gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  kDarkBg,
                ],
                stops: const [0.45, 1.0],
              ),
            ),
          ),
        ),
        // Top bar overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
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
                _buildTypeChip(exercice.typeLabel),
              ],
            ),
          ),
        ),
        // Title at bottom of hero
        Positioned(
          bottom: 16,
          left: 18,
          right: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercice.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                exercice.part.name.toUpperCase(),
                style: TextStyle(
                  color: kNeonGreen.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── INFO ROW ───────────────────────────────────────────────────────────────

  Widget _buildInfoRow(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(
          Icons.local_fire_department_outlined,
          exercice.typeLabel,
          'Type',
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          Icons.notes_rounded,
          '${exercice.notes.length}',
          'Steps',
        ),
        const SizedBox(width: 10),
        // Tutorial quick-access
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TutorialScreen(exercice: exercice),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              decoration: BoxDecoration(
                color: kNeonGreen,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kNeonGreen.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline,
                      color: Colors.black, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'TUTORIAL',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
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
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── DESCRIPTION ────────────────────────────────────────────────────────────

  Widget _buildDescriptionCard() {
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
          Text(
            exercice.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 13,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  // ─── INSTRUCTIONS LIST ───────────────────────────────────────────────────────

  Widget _buildNotesList() {
    return Container(
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: exercice.notes.asMap().entries.map((entry) {
          final idx = entry.key;
          final note = entry.value;
          final isLast = idx == exercice.notes.length - 1;
          return _buildNoteItem(idx + 1, note, isLast);
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
              // Step badge
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 1, right: 12),
                decoration: BoxDecoration(
                  color: kNeonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: kNeonGreen.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: kNeonGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.text,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                    if (note.imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          note.imageUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
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

  // ─── TUTORIAL BANNER ────────────────────────────────────────────────────────

  Widget _buildTutorialBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TutorialScreen(exercice: exercice),
        ),
      ),
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
              width: 46,
              height: 46,
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
                  const Text(
                    'Watch Tutorial',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Step-by-step video guide for ${exercice.name}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.38),
                      fontSize: 11,
                    ),
                  ),
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

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: kNeonGreen, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: kNeonGreen.withOpacity(0.9),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
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
      child: Text(
        label,
        style: const TextStyle(
          color: kNeonGreen,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}