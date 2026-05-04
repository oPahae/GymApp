import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/models/client.dart';
import 'package:test_hh/models/coach.dart';
import 'package:test_hh/screens/profileClient.dart';

class ProfilCoach extends StatefulWidget {
  const ProfilCoach({super.key});

  @override
  State<ProfilCoach> createState() => _ProfilCoachState();
}

class _ProfilCoachState extends State<ProfilCoach> {
  // ── Hardcoded coach data ──────────────────────────────────────────────────
  final Coach _coach = Coach(
    id: 1,
    name: 'Alex Martin',
    specialty: 'Strength & Conditioning',
    bio: 'Passionate coach helping athletes reach their peak performance through science-based training.',
    createdAt: DateTime(2021, 3, 15),
    clients: [
      Client(
        id: 1,
        name: 'Sarah Johnson',
        image: '',
        birth: DateTime(1998, 4, 12),
        weight: 65.0,
        height: 168.0,
        weightGoal: 60.0,
        goal: 'Lose Weight',
        frequency: 2,
        gender: 'Female',
        coach: null, createdAt:  DateTime(2023, 7, 20), coachId: 1,
      ),
      Client(
        id: 2,
        name: 'Mike Torres',
        image: '',
        birth: DateTime(1995, 7, 22),
        weight: 82.0,
        height: 178.0,
        weightGoal: 88.0,
        goal: 'Build Muscle',
        frequency: 4,
        gender: 'Male',
        coach: null, createdAt:  DateTime(2023, 7, 20), coachId: 1,
      ),
      Client(
        id: 3,
        name: 'Emma Davis',
        image: '',
        birth: DateTime(2000, 1, 5),
        weight: 58.0,
        height: 162.0,
        weightGoal: 55.0,
        goal: 'Stay Healthy',
        frequency: 1,
        gender: 'Female',
        coach: null, createdAt:  DateTime(2023, 7, 20), coachId: 1,
      ),
    ], image: '',
  );

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isEditing = false;
  File? _profileImage;

  late TextEditingController _nameController;
  late TextEditingController _specialtyController;
  late TextEditingController _bioController;

  // ── Static data ───────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _goals = [
    {'icon': Icons.local_fire_department, 'title': 'Lose Weight', 'sub': 'Burn fat, get lean'},
    {'icon': Icons.fitness_center, 'title': 'Build Muscle', 'sub': 'Gain mass & strength'},
    {'icon': Icons.monitor_heart, 'title': 'Stay Healthy', 'sub': 'Maintain balance'},
    {'icon': Icons.directions_run, 'title': 'Boost Endurance', 'sub': 'Cardio & stamina'},
    {'icon': Icons.self_improvement, 'title': 'Flexibility', 'sub': 'Mobility & wellness'},
    {'icon': Icons.electric_bolt, 'title': 'Recomposition', 'sub': 'Lose fat, gain muscle'},
  ];

  final List<Map<String, String>> _frequencies = [
    {'title': 'Beginner', 'sub': '1 – 2 days / week'},
    {'title': 'Light', 'sub': '3 days / week'},
    {'title': 'Moderate', 'sub': '4 days / week'},
    {'title': 'Active', 'sub': '5 days / week'},
    {'title': 'Athlete', 'sub': '6 – 7 days / week'},
  ];

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formattedDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _coach.name);
    _specialtyController = TextEditingController(text: _coach.specialty ?? 'Strength & Conditioning');
    _bioController = TextEditingController(
        text: _coach.bio ?? 'Passionate coach helping athletes reach their peak.');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _profileImage = File(picked.path));
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
    if (!_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kNeonGreen.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text(
            'Profile saved!',
            style: TextStyle(color: kDarkBg, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
  }

  void _openClientProfile(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilClient()),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(top: -60, right: -60, child: _glowBlob(220, 0.07)),
          Positioned(bottom: 100, left: -50, child: _glowBlob(160, 0.05)),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildHeroCard(),
                        const SizedBox(height: 16),
                        _buildSection('COACH INFO', _buildCoachInfo()),
                        const SizedBox(height: 14),
                        _buildSection('SPECIALTY', _buildCoachSpecialty()),
                        const SizedBox(height: 14),
                        _buildSection('BIO', _buildCoachBio()),
                        const SizedBox(height: 14),
                        _buildSection(
                          'MY CLIENTS (${_coach.clients.length})',
                          _buildClientList(),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── APP BAR ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          const Text(
            'COACH PROFILE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _toggleEdit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: _isEditing ? kNeonGreen : kNeonGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kNeonGreen.withOpacity(_isEditing ? 1 : 0.45)),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                    color: _isEditing ? kDarkBg : kNeonGreen,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isEditing ? 'SAVE' : 'EDIT',
                    style: TextStyle(
                      color: _isEditing ? kDarkBg : kNeonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HERO CARD ─────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A6BFF).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A6BFF).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFF1A6BFF), size: 12),
          const SizedBox(width: 5),
          Text(
            'COACH · ${_coach.clients.length} clients',
            style: const TextStyle(
              color: Color(0xFF1A6BFF),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF111111),
            kNeonGreen.withOpacity(0.04),
          ],
        ),
        boxShadow: [
          BoxShadow(color: kNeonGreen.withOpacity(0.07), blurRadius: 30, spreadRadius: 2)
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isEditing ? _pickImage : null,
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kNeonGreen.withOpacity(0.08),
                    border: Border.all(color: kNeonGreen.withOpacity(0.45), width: 2),
                    boxShadow: [
                      BoxShadow(color: kNeonGreen.withOpacity(0.15), blurRadius: 20)
                    ],
                  ),
                  child: _profileImage != null
                      ? ClipOval(child: Image.file(_profileImage!, fit: BoxFit.cover))
                      : const Icon(
                          Icons.sports_gymnastics_rounded,
                          color: kNeonGreen,
                          size: 34,
                        ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kNeonGreen,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: kDarkBg, size: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isEditing
                    ? _inlineTextField(_nameController)
                    : Text(
                        _nameController.text.isEmpty ? 'Coach Name' : _nameController.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                const SizedBox(height: 4),
                Text(
                  'Member since ${_formattedDate(_coach.createdAt)}',
                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
                ),
                const SizedBox(height: 10),
                badge,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SECTION BUILDER ───────────────────────────────────────────────────────
  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        content,
      ],
    );
  }

  // ── COACH INFO ────────────────────────────────────────────────────────────
  Widget _buildCoachInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.person_outline,
            label: 'Full Name',
            child: _isEditing
                ? _inlineTextField(_nameController)
                : _infoValue(_nameController.text.isEmpty ? '—' : _nameController.text),
          ),
          _divider(),
          _infoRow(
            icon: Icons.badge_outlined,
            label: 'Coach ID',
            child: _infoValue('#${_coach.id}'),
          ),
          _divider(),
          _infoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            child: _infoValue(_formattedDate(_coach.createdAt)),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCoachSpecialty() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: _infoRow(
        icon: Icons.sports_gymnastics_rounded,
        label: 'Specialty',
        child: _isEditing
            ? _inlineTextField(_specialtyController, width: 180)
            : _infoValue(
                _specialtyController.text.isEmpty ? '—' : _specialtyController.text),
        isLast: true,
      ),
    );
  }

  Widget _buildCoachBio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: _isEditing
          ? TextField(
              controller: _bioController,
              maxLines: 4,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: kNeonGreen.withOpacity(0.06),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: kNeonGreen.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kNeonGreen),
                ),
                hintText: 'Write something about yourself…',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 13,
                ),
              ),
            )
          : Text(
              _bioController.text.isEmpty ? 'No bio yet.' : _bioController.text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                height: 1.6,
              ),
            ),
    );
  }

  // ── CLIENT LIST ───────────────────────────────────────────────────────────
  Widget _buildClientList() {
    final clients = _coach.clients;

    if (clients.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          children: [
            Icon(Icons.group_outlined, color: Colors.white.withOpacity(0.2), size: 36),
            const SizedBox(height: 10),
            Text(
              'No clients yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: clients.asMap().entries.map((entry) {
          final i = entry.key;
          final client = entry.value;
          final isLast = i == clients.length - 1;

          final goalEntry = _goals.firstWhere(
            (g) => g['title'] == client.goal,
            orElse: () => _goals.first,
          );

          return Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(18) : Radius.zero,
                  bottom: isLast ? const Radius.circular(18) : Radius.zero,
                ),
                onTap: () => _openClientProfile(client),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kNeonGreen.withOpacity(0.08),
                          border:
                              Border.all(color: kNeonGreen.withOpacity(0.3), width: 1.5),
                        ),
                        child: client.image.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  client.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person_outline_rounded,
                                    color: kNeonGreen,
                                    size: 22,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.person_outline_rounded,
                                color: kNeonGreen,
                                size: 22,
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  goalEntry['icon'] as IconData,
                                  color: kNeonGreen,
                                  size: 11,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  client.goal,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _miniChip(
                            '${client.weight.toStringAsFixed(1)} kg',
                            Icons.monitor_weight_outlined,
                          ),
                          const SizedBox(height: 4),
                          _miniChip(
                            _frequencies[
                                client.frequency.clamp(0, _frequencies.length - 1)]['title']!,
                            Icons.fitness_center,
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withOpacity(0.25),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(color: Colors.white.withOpacity(0.05), height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _miniChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: kNeonGreen.withOpacity(0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kNeonGreen.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kNeonGreen, size: 10),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── SHARED HELPERS ────────────────────────────────────────────────────────
  Widget _infoRow({
    required IconData icon,
    required String label,
    required Widget child,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kNeonGreen.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: kNeonGreen, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _infoValue(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _divider() => Divider(color: Colors.white.withOpacity(0.05), height: 1);

  Widget _inlineTextField(TextEditingController controller, {double width = 160}) {
    return SizedBox(
      width: width,
      height: 32,
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          filled: true,
          fillColor: kNeonGreen.withOpacity(0.08),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: kNeonGreen.withOpacity(0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kNeonGreen),
          ),
        ),
      ),
    );
  }

  Widget _glowBlob(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [kNeonGreen.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }
}