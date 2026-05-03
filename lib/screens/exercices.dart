import 'package:flutter/material.dart';
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/models/bodyPart.dart';
import 'package:test_hh/models/exercice.dart';
import 'package:test_hh/models/notes.dart';
import 'package:test_hh/screens/exercice.dart'; // ← detail page

class ExercicesScreen extends StatefulWidget {
  final BodyPartModel bodyPart;

  const ExercicesScreen({super.key, required this.bodyPart});

  @override
  State<ExercicesScreen> createState() => _ExercicesScreenState();
}

class _ExercicesScreenState extends State<ExercicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExerciceModel> get _filtered => widget.bodyPart.exercices
      .where((e) => e.name.toLowerCase().contains(_searchQuery))
      .toList();

  @override
  Widget build(BuildContext context) {
    final exercises = _filtered;
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: Header(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildSearchBar(),
            const SizedBox(height: 14),
            Expanded(
              child: exercises.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                      itemCount: exercises.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildExerciceCard(exercises[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(),
    );
  }

  // ─── TOP BAR ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
                Text(
                  widget.bodyPart.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '${widget.bodyPart.exercices.length} exercises',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (widget.bodyPart.exercices.isNotEmpty)
            _buildTypeChip(widget.bodyPart.exercices.first.typeLabel),
        ],
      ),
    );
  }

  // ─── SEARCH BAR ─────────────────────────────────────────────────────────────

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
            hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
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

  // ─── EXERCISE CARD ──────────────────────────────────────────────────────────

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
          // ── Header row: tap → detail page ──
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExerciceScreen(exercice: ex),
              ),
            ),
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
                              Text(
                                ex.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                ex.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.38),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Expand toggle (secondary action)
                        GestureDetector(
                          onTap: () => setState(
                              () => _expandedId = isExpanded ? null : ex.id),
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

          // ── Expandable quick-notes ──
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
                        child: Text(
                          ex.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 12,
                            height: 1.55,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.format_list_bulleted,
                                color: kNeonGreen, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'INSTRUCTIONS',
                              style: TextStyle(
                                color: kNeonGreen.withOpacity(0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...ex.notes.asMap().entries.map(
                            (entry) => _buildNoteItem(entry.key + 1,
                                entry.value, entry.key == ex.notes.length - 1),
                          ),
                      // "See full details" shortcut
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExerciceScreen(exercice: ex),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'SEE FULL DETAILS',
                                style: TextStyle(
                                  color: kNeonGreen.withOpacity(0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios,
                                  color: kNeonGreen.withOpacity(0.7), size: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : isExpanded
                    ? Column(
                        children: [
                          const Divider(height: 1, color: Colors.white10),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(14, 14, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ex.description,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 12,
                                    height: 1.55,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color:
                                            Colors.white.withOpacity(0.08)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Colors.white.withOpacity(0.3),
                                          size: 14),
                                      const SizedBox(width: 8),
                                      Text(
                                        'No instructions added yet.',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.3),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─── Note item ───────────────────────────────────────────────────────────────

  Widget _buildNoteItem(int index, NoteModel note, bool isLast) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1, right: 10),
                decoration: BoxDecoration(
                  color: kNeonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
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
                    const SizedBox(height: 2),
                    Text(
                      note.text,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    if (note.imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          note.imageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
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

  // ─── Shared ──────────────────────────────────────────────────────────────────

  Widget _buildTypeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: kNeonGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kNeonGreen.withOpacity(0.22), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: kNeonGreen,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
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
            Text(
              'No exercises found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.28),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}