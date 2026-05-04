import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/models/client.dart';
import 'package:test_hh/models/coach.dart';

enum UserRole { client, coach }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.client,
    this.coach,
    this.coachClients,
  }) : assert(
          (client != null) ^ (coach != null),
          'Provide either a client OR a coach, not both.',
        );

  final Client? client;
  final Coach? coach;
  final List<Client>? coachClients;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserRole _role;
  bool _isEditing = false;
  File? _profileImage;
  late TextEditingController _nameController;

  // Client-only
  DateTime _birthDate = DateTime(1998, 4, 12);
  double _weight = 78.5;
  double _height = 181;
  double _weightGoal = 72.0;
  bool _weightInKg = true;
  bool _heightInCm = true;
  String _goal = 'Lose Weight';
  int _frequency = 2;
  String _gender = 'Male';

  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _weightGoalController;

  // Coach-only
  late TextEditingController _coachSpecialtyController;
  late TextEditingController _coachBioController;

  // Static data
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

  // Computed
  String get _weightLabel => _weightInKg ? 'KG' : 'LBS';
  String get _heightLabel => _heightInCm ? 'CM' : 'FT';
  double get _displayWeight => _weightInKg ? _weight : _weight * 2.205;
  double get _displayHeight => _heightInCm ? _height : _height / 30.48;
  double get _displayGoal => _weightInKg ? _weightGoal : _weightGoal * 2.205;

  String _formattedDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';

  int _age(DateTime d) {
    final now = DateTime.now();
    int age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
    return age;
  }

  String _memberSince(DateTime d) => _formattedDate(d);

  void _syncControllers() {
    _weightController.text = _displayWeight.toStringAsFixed(1);
    _heightController.text = _displayHeight.toStringAsFixed(_heightInCm ? 0 : 2);
    _weightGoalController.text = _displayGoal.toStringAsFixed(1);
  }

  void _commitMetrics() {
    final w = double.tryParse(_weightController.text);
    final h = double.tryParse(_heightController.text);
    final g = double.tryParse(_weightGoalController.text);
    if (w != null) _weight = (_weightInKg ? w : w / 2.205).clamp(30, 300);
    if (h != null) _height = (_heightInCm ? h : h * 30.48).clamp(100, 250);
    if (g != null) _weightGoal = (_weightInKg ? g : g / 2.205).clamp(30, 300);
  }

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _weightGoalController = TextEditingController();

    if (widget.client != null) {
      _role = UserRole.client;
      final c = widget.client!;
      _nameController = TextEditingController(text: c.name);
      _birthDate = c.birth;
      _weight = c.weight;
      _height = c.height;
      _weightGoal = c.weightGoal;
      _frequency = c.frequency.clamp(0, _frequencies.length - 1);
      _goal = c.goal;
      _gender = c.gender;
    } else {
      _role = UserRole.coach;
      final ch = widget.coach!;
      _nameController = TextEditingController(text: ch.name);
      _coachSpecialtyController = TextEditingController(text: ch.specialty ?? 'Strength & Conditioning');
      _coachBioController = TextEditingController(text: ch.bio ?? 'Passionate coach helping athletes reach their peak.');
    }
    _syncControllers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _weightGoalController.dispose();
    if (_role == UserRole.coach) {
      _coachSpecialtyController.dispose();
      _coachBioController.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _profileImage = File(picked.path));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: kNeonGreen, onPrimary: kDarkBg),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _toggleEdit() {
    if (_isEditing) _commitMetrics();
    setState(() => _isEditing = !_isEditing);
    if (!_isEditing) {
      _syncControllers();
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
    } else {
      _syncControllers();
    }
  }

  void _openClientProfile(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(client: client),
      ),
    );
  }

  // ==================== BUILD ====================
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

                        if (_role == UserRole.client) ...[
                          _buildStatsRow(),
                          const SizedBox(height: 16),
                          _buildSection('PERSONAL INFO', _buildPersonalInfo()),
                          const SizedBox(height: 14),
                          _buildSection('FITNESS GOAL', _buildGoalGrid()),
                          const SizedBox(height: 14),
                          _buildSection('TRAINING FREQUENCY', _buildFrequencyList()),
                          const SizedBox(height: 14),
                          _buildSection('BODY METRICS', _buildBodyMetrics()),
                          const SizedBox(height: 14),
                          _buildSection('MY COACH', _buildCoachInfoForClient()),
                        ],

                        if (_role == UserRole.coach) ...[
                          _buildSection('COACH INFO', _buildCoachInfo()),
                          const SizedBox(height: 14),
                          _buildSection('SPECIALTY', _buildCoachSpecialty()),
                          const SizedBox(height: 14),
                          _buildSection('BIO', _buildCoachBio()),
                          const SizedBox(height: 14),
                          _buildSection(
                            'MY CLIENTS (${_getClients().length})',
                            _buildClientList(),
                          ),
                        ],

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

  // ==================== APP BAR ====================
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          Text(
            _role == UserRole.coach ? 'COACH PROFILE' : 'PROFILE',
            style: const TextStyle(
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

  // ==================== HERO CARD ====================
  Widget _buildHeroCard() {
    Widget badge;
    if (_role == UserRole.client) {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: kNeonGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kNeonGreen.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _goals.firstWhere((g) => g['title'] == _goal)['icon'] as IconData,
              color: kNeonGreen,
              size: 12,
            ),
            const SizedBox(width: 5),
            Text(
              _goal,
              style: const TextStyle(
                color: kNeonGreen,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else {
      badge = Container(
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
              'COACH · ${_getClients().length} clients',
              style: const TextStyle(
                color: Color(0xFF1A6BFF),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final subtitle = _role == UserRole.client
        ? '${_age(_birthDate)} years old'
        : 'Member since ${_memberSince(widget.coach!.createdAt)}';

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
        boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.07), blurRadius: 30, spreadRadius: 2)],
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
                    boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.15), blurRadius: 20)],
                  ),
                  child: _profileImage != null
                      ? ClipOval(child: Image.file(_profileImage!, fit: BoxFit.cover))
                      : Icon(
                          _role == UserRole.coach
                              ? Icons.sports_gymnastics_rounded
                              : Icons.person_outline_rounded,
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
                        _nameController.text.isEmpty ? 'Your Name' : _nameController.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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

  // ==================== SECTION BUILDER ====================
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

  // ==================== COACH INFO FOR CLIENT ====================
  Widget _buildCoachInfoForClient() {
    final client = widget.client!;
    final coach = client.coach;

    if (coach == null) {
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
            Icon(
              Icons.person_search_outlined,
              color: Colors.white.withOpacity(0.2),
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              'No coach assigned',
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
            label: 'Coach Name',
            child: _infoValue(coach.name.isEmpty ? '—' : coach.name),
          ),
          _divider(),
          _infoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            child: _infoValue(_memberSince(coach.createdAt)),
          ),
          _divider(),
          _infoRow(
            icon: Icons.info_outline,
            label: 'Coach ID',
            child: _infoValue('#${coach.id}'),
          ),
          _divider(),
          _infoRow(
            icon: Icons.description_outlined,
            label: 'Specialty',
            child: _infoValue(coach.specialty ?? '—'),
            isLast: true,
          ),
        ],
      ),
    );
  }

 
 List<Client> _getClients() {
  if (widget.coachClients != null && widget.coachClients!.isNotEmpty) {
    return widget.coachClients!;
  }
  return widget.coach?.clients ?? [];
}

  Widget _buildClientList() {
    final clients = _getClients();

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
            Icon(
              Icons.group_outlined,
              color: Colors.white.withOpacity(0.2),
              size: 36,
            ),
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
                      // Avatar
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kNeonGreen.withOpacity(0.08),
                          border: Border.all(color: kNeonGreen.withOpacity(0.3), width: 1.5),
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

                      // Name + Goal
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

                      // Stats Chips
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _miniChip(
                            '${client.weight.toStringAsFixed(1)} kg',
                            Icons.monitor_weight_outlined,
                          ),
                          const SizedBox(height: 4),
                          _miniChip(
                            _frequencies[client.frequency.clamp(0, _frequencies.length - 1)]['title']!,
                            Icons.fitness_center,
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      // Chevron
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
                Divider(
                  color: Colors.white.withOpacity(0.05),
                  height: 1,
                ),
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

  // ==================== COACH INFO / SPECIALTY / BIO ====================
  Widget _buildCoachInfo() {
    final ch = widget.coach!;
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
            child: _infoValue('#${ch.id}'),
          ),
          _divider(),
          _infoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            child: _infoValue(_memberSince(ch.createdAt)),
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
            ? _inlineTextField(_coachSpecialtyController, width: 180)
            : _infoValue(_coachSpecialtyController.text.isEmpty ? '—' : _coachSpecialtyController.text),
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
              controller: _coachBioController,
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
              _coachBioController.text.isEmpty ? 'No bio yet.' : _coachBioController.text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                height: 1.6,
              ),
            ),
    );
  }

  // ==================== CLIENT WIDGETS ====================
  Widget _buildStatsRow() {
    return Row(
      children: [
        _statTile(
          label: 'WEIGHT',
          value: _displayWeight.toStringAsFixed(1),
          unit: _weightLabel,
          icon: Icons.monitor_weight_outlined,
        ),
        const SizedBox(width: 10),
        _statTile(
          label: 'HEIGHT',
          value: _displayHeight.toStringAsFixed(_heightInCm ? 0 : 1),
          unit: _heightLabel,
          icon: Icons.height,
        ),
        const SizedBox(width: 10),
        _statTile(
          label: 'GOAL WT',
          value: _displayGoal.toStringAsFixed(1),
          unit: _weightLabel,
          icon: Icons.flag_outlined,
          highlight: true,
        ),
      ],
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: highlight ? kNeonGreen.withOpacity(0.10) : kDarkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight ? kNeonGreen.withOpacity(0.45) : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: kNeonGreen, size: 16),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
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
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            child: _isEditing
                ? GestureDetector(
                    onTap: _pickDate,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _infoValue(_formattedDate(_birthDate)),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.edit,
                          color: kNeonGreen.withOpacity(0.7),
                          size: 12,
                        ),
                      ],
                    ),
                  )
                : _infoValue(_formattedDate(_birthDate)),
          ),
          _divider(),
          _infoRow(
            icon: Icons.cake_outlined,
            label: 'Age',
            child: _infoValue('${_age(_birthDate)} years'),
          ),
          _divider(),
          _infoRow(
            icon: Icons.wc_outlined,
            label: 'Gender',
            child: _isEditing ? _buildGenderToggle() : _infoValue(_gender),
          ),
          _divider(),
          _infoRow(
            icon: Icons.fitness_center,
            label: 'Frequency',
            child: _infoValue(_frequencies[_frequency]['title']!),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['Male', 'Female'].map((g) {
        final selected = _gender == g;
        final icon = g == 'Male' ? Icons.male_rounded : Icons.female_rounded;
        return GestureDetector(
          onTap: () => setState(() => _gender = g),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? kNeonGreen.withOpacity(0.12) : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? kNeonGreen.withOpacity(0.6) : Colors.white.withOpacity(0.12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: kNeonGreen, size: 14),
                const SizedBox(width: 4),
                Text(
                  g,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? kNeonGreen : Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: _goals.map((g) {
        final selected = _goal == g['title'];
        return GestureDetector(
          onTap: _isEditing ? () => setState(() => _goal = g['title']!) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? kNeonGreen.withOpacity(0.10) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? kNeonGreen.withOpacity(0.6) : Colors.white.withOpacity(0.08),
              ),
              boxShadow: selected
                  ? [BoxShadow(color: kNeonGreen.withOpacity(0.12), blurRadius: 12)]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(g['icon']! as IconData, size: 22, color: kNeonGreen),
                const SizedBox(height: 6),
                Text(
                  g['title']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? kNeonGreen : Colors.white,
                  ),
                ),
                Text(
                  g['sub']!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrequencyList() {
    return Column(
      children: _frequencies.asMap().entries.map((entry) {
        final index = entry.key;
        final freq = entry.value;
        final selected = _frequency == index;
        return GestureDetector(
          onTap: _isEditing ? () => setState(() => _frequency = index) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? kNeonGreen.withOpacity(0.09) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? kNeonGreen.withOpacity(0.6) : Colors.white.withOpacity(0.08),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        freq['title']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected ? kNeonGreen : Colors.white,
                        ),
                      ),
                      Text(
                        freq['sub']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? kNeonGreen : Colors.transparent,
                    border: Border.all(
                      color: selected ? kNeonGreen : Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: kNeonGreen.withOpacity(0.5), blurRadius: 8)]
                        : [],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBodyMetrics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          _metricRow(
            label: 'WEIGHT',
            displayValue: _displayWeight.toStringAsFixed(1),
            unit: _weightLabel,
            controller: _weightController,
            onMinus: () => setState(() {
              _weight = (_weight - 0.5).clamp(30, 300);
              _syncControllers();
            }),
            onPlus: () => setState(() {
              _weight = (_weight + 0.5).clamp(30, 300);
              _syncControllers();
            }),
            unitToggle: _buildUnitToggle(['KG', 'LBS'], _weightInKg, (kg) {
              setState(() {
                if (_weightInKg != kg) {
                  _weight = kg ? _weight / 2.205 : _weight * 2.205;
                  _weightGoal = kg ? _weightGoal / 2.205 : _weightGoal * 2.205;
                  _weightInKg = kg;
                  _syncControllers();
                }
              });
            }),
          ),
          _divider(),
          _metricRow(
            label: 'HEIGHT',
            displayValue: _displayHeight.toStringAsFixed(_heightInCm ? 0 : 2),
            unit: _heightLabel,
            controller: _heightController,
            onMinus: () => setState(() {
              _height = (_height - (_heightInCm ? 1 : 0.01)).clamp(100, 250);
              _syncControllers();
            }),
            onPlus: () => setState(() {
              _height = (_height + (_heightInCm ? 1 : 0.01)).clamp(100, 250);
              _syncControllers();
            }),
            unitToggle: _buildUnitToggle(['CM', 'FT'], _heightInCm, (cm) {
              setState(() {
                if (_heightInCm != cm) {
                  _height = cm ? _height * 30.48 : _height / 30.48;
                  _heightInCm = cm;
                  _syncControllers();
                }
              });
            }),
          ),
          _divider(),
          _metricRow(
            label: 'GOAL WEIGHT',
            displayValue: _displayGoal.toStringAsFixed(1),
            unit: _weightLabel,
            controller: _weightGoalController,
            isLast: true,
            onMinus: () => setState(() {
              _weightGoal = (_weightGoal - 0.5).clamp(30, 300);
              _syncControllers();
            }),
            onPlus: () => setState(() {
              _weightGoal = (_weightGoal + 0.5).clamp(30, 300);
              _syncControllers();
            }),
          ),
        ],
      ),
    );
  }

  Widget _metricRow({
    required String label,
    required String displayValue,
    required String unit,
    required TextEditingController controller,
    bool isLast = false,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    Widget? unitToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              if (unitToggle != null) ...[const Spacer(), unitToggle],
            ],
          ),
          const SizedBox(height: 8),
          if (_isEditing)
            Row(
              children: [
                _iconBtn(Icons.remove, onMinus),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      filled: true,
                      fillColor: kNeonGreen.withOpacity(0.06),
                      suffix: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          unit,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kNeonGreen.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kNeonGreen, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _iconBtn(Icons.add, onPlus),
              ],
            )
          else
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: displayValue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==================== SHARED HELPERS ====================
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
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 12,
              ),
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

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: kNeonGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kNeonGreen.withOpacity(0.3)),
        ),
        child: Icon(icon, color: kNeonGreen, size: 16),
      ),
    );
  }

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

  Widget _buildUnitToggle(List<String> units, bool firstSelected, void Function(bool) onSelect) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: units.asMap().entries.map((e) {
          final isFirst = e.key == 0;
          final selected = firstSelected ? isFirst : !isFirst;
          return GestureDetector(
            onTap: () => onSelect(isFirst),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? kNeonGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? kDarkBg : Colors.white.withOpacity(0.45),
                ),
              ),
            ),
          );
        }).toList(),
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