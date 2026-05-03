import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/models/exercice.dart';
import 'package:test_hh/models/notes.dart';

class TutorialScreen extends StatefulWidget {
  final ExerciceModel exercice;

  const TutorialScreen({super.key, required this.exercice});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  bool _videoPlaying = false;
  int _activeStep = 0;

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercice;
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: Header(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVideoPlayer(ex),
                    const SizedBox(height: 20),
                    _buildExerciceTitle(ex),
                    const SizedBox(height: 20),
                    if (ex.notes.isNotEmpty) ...[
                      _buildStepHeader(ex),
                      const SizedBox(height: 12),
                      _buildStepProgress(ex.notes),
                      const SizedBox(height: 16),
                      _buildActiveStepCard(ex.notes),
                      const SizedBox(height: 14),
                      _buildAllStepsList(ex.notes),
                    ] else
                      _buildNoSteps(),
                  ],
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

  Widget _buildTopBar(BuildContext context) {
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
          const Expanded(
            child: Text(
              'TUTORIAL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          // Fullscreen hint
          GestureDetector(
            onTap: () {
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: kDarkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Icon(Icons.fullscreen,
                  color: Colors.white.withOpacity(0.6), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─── VIDEO PLAYER ───────────────────────────────────────────────────────────

  Widget _buildVideoPlayer(ExerciceModel ex) {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail / placeholder
          Image.network(
            ex.image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF111111),
              child: const Icon(Icons.videocam_off,
                  color: Colors.white12, size: 40),
            ),
          ),
          // Dark overlay
          Container(color: Colors.black.withOpacity(_videoPlaying ? 0.1 : 0.55)),
          // Play / Pause button
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _videoPlaying = !_videoPlaying),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: _videoPlaying
                      ? Colors.black.withOpacity(0.45)
                      : kNeonGreen,
                  shape: BoxShape.circle,
                  boxShadow: _videoPlaying
                      ? []
                      : [
                          BoxShadow(
                            color: kNeonGreen.withOpacity(0.35),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                ),
                child: Icon(
                  _videoPlaying ? Icons.pause : Icons.play_arrow_rounded,
                  color: _videoPlaying ? Colors.white70 : Colors.black,
                  size: 32,
                ),
              ),
            ),
          ),
          // Bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _videoPlaying
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    color: Colors.white60,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _videoPlaying ? 0.3 : 0.0,
                        backgroundColor: Colors.white12,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(kNeonGreen),
                        minHeight: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _videoPlaying ? '0:32 / 1:45' : '1:45',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // "No video" notice if empty
          if (ex.video.isEmpty)
            Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    'Preview only — no video attached',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── EXERCISE TITLE ROW ─────────────────────────────────────────────────────

  Widget _buildExerciceTitle(ExerciceModel ex) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ex.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ex.part.name,
                style: TextStyle(
                  color: kNeonGreen.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        _buildTypeChip(ex.typeLabel),
      ],
    );
  }

  // ─── STEP HEADER ────────────────────────────────────────────────────────────

  Widget _buildStepHeader(ExerciceModel ex) {
    return Row(
      children: [
        const Icon(Icons.format_list_numbered, color: kNeonGreen, size: 16),
        const SizedBox(width: 7),
        Text(
          'STEP-BY-STEP',
          style: TextStyle(
            color: kNeonGreen.withOpacity(0.9),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const Spacer(),
        Text(
          '${_activeStep + 1} / ${ex.notes.length}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── STEP PROGRESS DOTS ─────────────────────────────────────────────────────

  Widget _buildStepProgress(List<NoteModel> notes) {
    return Row(
      children: notes.asMap().entries.map((e) {
        final active = e.key == _activeStep;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeStep = e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              margin: EdgeInsets.only(right: e.key < notes.length - 1 ? 5 : 0),
              decoration: BoxDecoration(
                color: active
                    ? kNeonGreen
                    : e.key < _activeStep
                        ? kNeonGreen.withOpacity(0.4)
                        : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── ACTIVE STEP CARD ───────────────────────────────────────────────────────

  Widget _buildActiveStepCard(List<NoteModel> notes) {
    final note = notes[_activeStep];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kNeonGreen.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: kNeonGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${_activeStep + 1}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Step ${_activeStep + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            note.text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13,
              height: 1.65,
            ),
          ),
          if (note.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                note.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Prev / Next navigation
          Row(
            children: [
              if (_activeStep > 0)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeStep--),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_ios_new,
                              color: Colors.white70, size: 13),
                          SizedBox(width: 5),
                          Text(
                            'PREV',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_activeStep > 0) const SizedBox(width: 10),
              if (_activeStep < notes.length - 1)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeStep++),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: kNeonGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'NEXT',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(Icons.arrow_forward_ios,
                              color: Colors.black, size: 13),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: kNeonGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kNeonGreen.withOpacity(0.35)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: kNeonGreen, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'DONE',
                          style: TextStyle(
                            color: kNeonGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── ALL STEPS LIST ─────────────────────────────────────────────────────────

  Widget _buildAllStepsList(List<NoteModel> notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt_rounded,
                color: Colors.white.withOpacity(0.35), size: 14),
            const SizedBox(width: 6),
            Text(
              'ALL STEPS',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: kDarkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: notes.asMap().entries.map((entry) {
              final idx = entry.key;
              final note = entry.value;
              final isActive = idx == _activeStep;
              final isDone = idx < _activeStep;
              final isLast = idx == notes.length - 1;
              return Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _activeStep = idx),
                    child: Container(
                      color: isActive
                          ? kNeonGreen.withOpacity(0.07)
                          : Colors.transparent,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Row(
                        children: [
                          // Step indicator
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? kNeonGreen.withOpacity(0.2)
                                  : isActive
                                      ? kNeonGreen
                                      : Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDone || isActive
                                    ? kNeonGreen.withOpacity(0.5)
                                    : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check,
                                      color: kNeonGreen, size: 12)
                                  : Text(
                                      '${idx + 1}',
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.black
                                            : Colors.white.withOpacity(0.4),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              note.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.45),
                                fontSize: 12,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (isActive)
                            const Icon(Icons.chevron_right,
                                color: kNeonGreen, size: 16),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1, color: Colors.white10, indent: 48),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── NO STEPS ───────────────────────────────────────────────────────────────

  Widget _buildNoSteps() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Icon(Icons.video_library_outlined,
              color: Colors.white.withOpacity(0.12), size: 42),
          const SizedBox(height: 12),
          Text(
            'No steps available yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.28),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  Widget _buildTypeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kNeonGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kNeonGreen.withOpacity(0.25)),
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