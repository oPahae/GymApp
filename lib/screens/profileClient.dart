import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/models/client.dart';
import 'package:test_hh/models/coach.dart';
import 'package:test_hh/screens/login.dart';
import 'package:test_hh/services/api_service.dart';
import 'package:test_hh/session/user_session.dart';

class ProfileClient extends StatefulWidget {
  final int? clientId;
  const ProfileClient({super.key, this.clientId});

  @override
  State<ProfileClient> createState() => _ProfileClientState();
}

class _ProfileClientState extends State<ProfileClient> {
  Client? _client;
  bool _isLoading = true;
  String? _error;
  bool _isEditing = false;
  XFile? _profileImage;
  String? _imageUrl;

  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _weightGoalController;

  late DateTime _birthDate;
  late double _weight;
  late double _height;
  late double _weightGoal;
  bool _weightInKg = true;
  bool _heightInCm = true;
  late String _goal;
  late int _frequency;
  late String _gender;

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

  String get _weightLabel => _weightInKg ? 'KG' : 'LBS';
  String get _heightLabel => _heightInCm ? 'CM' : 'FT';
  double get _displayWeight => _weightInKg ? _weight : _weight * 2.205;
  double get _displayHeight => _heightInCm ? _height : _height / 30.48;
  double get _displayGoal => _weightInKg ? _weightGoal : _weightGoal * 2.205;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _weightGoalController = TextEditingController();
    _birthDate = DateTime.now();
    _weight = 70.0;
    _height = 170.0;
    _weightGoal = 65.0;
    _goal = 'Lose Weight';
    _frequency = 0;
    _gender = 'Male';
    _loadClient();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _weightGoalController.dispose();
    super.dispose();
  }

  // --- Chargement du client ---
  Future<void> _loadClient() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      bool sessionLoaded = await UserSession.instance.load();
      if (!sessionLoaded && widget.clientId == null) {
        setState(() { _error = 'Failed to load user session.'; _isLoading = false; });
        return;
      }

      if (widget.clientId != null) {
        final res = await ApiService.getClient(widget.clientId!);
        if (!mounted) return;
        if (res['success'] == true && res['client'] != null) {
          _applyClient(Client.fromJson(res['client'] as Map<String, dynamic>));
        } else {
          setState(() { _error = res['message'] ?? 'Failed to load client.'; _isLoading = false; });
        }
      } else {
        _applyClientFromSession();
      }
    } catch (e) {
      setState(() { _error = 'An error occurred: $e'; _isLoading = false; });
    }
  }

  void _applyClientFromSession() {
    final session = UserSession.instance;
    final client = Client(
      id: session.id,
      name: session.name,
      email: session.email,
      birth: DateTime.tryParse(session.birth) ?? DateTime.now(),
      gender: session.gender,
      weight: session.weight,
      height: session.height,
      weightGoal: session.weightGoal,
      frequency: session.frequency,
      goal: session.goal,
      image: session.image,
      coach: null,
    );
    _applyClient(client);
  }

  void _applyClient(Client client) {
    setState(() {
      _client = client;
      _imageUrl = client.image.isNotEmpty ? client.image : null;
      _birthDate = client.birth;
      _weight = client.weight;
      _height = client.height;
      _weightGoal = client.weightGoal;
      _frequency = client.frequency.clamp(0, _frequencies.length - 1);
      _goal = client.goal.isNotEmpty ? client.goal : 'Lose Weight';
      _gender = client.gender.isNotEmpty ? client.gender : 'Male';
      _nameController.text = client.name;
      _syncControllers();
      _isLoading = false;
    });
  }

  // --- Upload vers Cloudinary ---
  Future<String?> _uploadImageToCloudinary(XFile imageFile) async {
    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/dlqcknocf/image/upload");
      final request = http.MultipartRequest("POST", uri);
      request.fields['upload_preset'] = 'GymApp';

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: imageFile.name),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );
      }

      final response = await request.send();
      final res = await response.stream.bytesToString();
      final data = jsonDecode(res);

      if (response.statusCode == 200) {
        return data['secure_url'] as String?;
      } else {
        debugPrint("Cloudinary error: $res");
        return null;
      }
    } catch (e) {
      debugPrint("Cloudinary exception: $e");
      return null;
    }
  }

  // --- Sélection d'image ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() { _profileImage = picked; });
    }
  }

  // --- Sauvegarde du profil ---
  Future<void> _saveClient() async {
    if (_client == null) return;
    _commitMetrics();

    String? imageUrl = _imageUrl;
    if (_profileImage != null) {
      imageUrl = await _uploadImageToCloudinary(_profileImage!);
      if (imageUrl == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text('Failed to upload image. Please try again.'),
          ),
        );
        return;
      }
    }

    final res = await ApiService.updateClient(_client!.id, {
      'name': _nameController.text.trim(),
      'birth': _birthDate.toIso8601String().split('T')[0],
      'gender': _gender,
      'weight': _weight,
      'height': _height,
      'weightGoal': _weightGoal,
      'frequency': _frequency,
      'goal': _goal,
      'image': imageUrl,
    });

    if (!mounted) return;

    if (res['success'] == true && res['client'] != null) {
      _applyClient(Client.fromJson(res['client'] as Map<String, dynamic>));
      await UserSession.instance.load();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: res['success'] == true ? kNeonGreen.withOpacity(0.9) : Colors.redAccent.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            res['success'] == true ? 'Profile saved!' : res['message'] ?? 'Error.',
            style: const TextStyle(color: kDarkBg, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
  }

  // --- Autres méthodes utilitaires ---
  String _formattedDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';
  }

  int _age(DateTime d) {
    final now = DateTime.now();
    int age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
    return age;
  }

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

  void _toggleEdit() async {
    if (_isEditing) {
      await _saveClient();
    } else {
      _syncControllers();
    }
    if (mounted) {
      setState(() => _isEditing = !_isEditing);
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    UserSession.instance.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // --- UI ---
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
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: kNeonGreen));

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.white.withOpacity(0.6))),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loadClient,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: kNeonGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kNeonGreen.withOpacity(0.4)),
                ),
                child: const Text('Retry', style: TextStyle(color: kNeonGreen, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeroCard(),
          const SizedBox(height: 16),
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
          _buildSection('MY COACH', _buildCoachInfo()),
          const SizedBox(height: 20),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          if (widget.clientId != null) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
              ),
            ),
            const SizedBox(width: 12),
          ],
          const Text(
            'PROFILE',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const Spacer(),
          if (!_isLoading && _error == null)
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

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent, width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.redAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'LOGOUT',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final goalEntry = _goals.firstWhere((g) => g['title'] == _goal, orElse: () => _goals.first);
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kNeonGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kNeonGreen.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(goalEntry['icon'] as IconData, color: kNeonGreen, size: 12),
          const SizedBox(width: 5),
          Text(_goal, style: const TextStyle(color: kNeonGreen, fontSize: 11, fontWeight: FontWeight.w700)),
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
          colors: [const Color(0xFF1A1A1A), const Color(0xFF111111), kNeonGreen.withOpacity(0.04)],
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
                      ? ClipOval(
                          child: kIsWeb
                              ? Image.network(_profileImage!.path, fit: BoxFit.cover)
                              : Image.file(File(_profileImage!.path), fit: BoxFit.cover),
                        )
                      : (_imageUrl != null && _imageUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                _imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_outline_rounded,
                                  color: kNeonGreen,
                                  size: 34,
                                ),
                              ),
                            )
                          : const Icon(Icons.person_outline_rounded, color: kNeonGreen, size: 34)),
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
                  '${_age(_birthDate)} years old',
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
          border: Border.all(color: highlight ? kNeonGreen.withOpacity(0.45) : Colors.white.withOpacity(0.07)),
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
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
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
            child: _isEditing ? _inlineTextField(_nameController) : _infoValue(_nameController.text.isEmpty ? '—' : _nameController.text),
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
                        Icon(Icons.edit, color: kNeonGreen.withOpacity(0.7), size: 12),
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
              border: Border.all(color: selected ? kNeonGreen.withOpacity(0.6) : Colors.white.withOpacity(0.12)),
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
              border: Border.all(color: selected ? kNeonGreen.withOpacity(0.6) : Colors.white.withOpacity(0.08)),
              boxShadow: selected ? [BoxShadow(color: kNeonGreen.withOpacity(0.12), blurRadius: 12)] : [],
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
                  style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.35)),
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
              border: Border.all(color: selected ? kNeonGreen.withOpacity(0.6) : Colors.white.withOpacity(0.08)),
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
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35)),
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
                    boxShadow: selected ? [BoxShadow(color: kNeonGreen.withOpacity(0.5), blurRadius: 8)] : [],
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
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
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
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
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

  Widget _buildCoachInfo() {
    final coach = _client?.coach;
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
            Icon(Icons.person_search_outlined, color: Colors.white.withOpacity(0.2), size: 36),
            const SizedBox(height: 10),
            Text(
              'No coach yet',
              style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13, fontWeight: FontWeight.w600),
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
            child: _infoValue(_formattedDate(coach.createdAt)),
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

  Widget _infoRow({required IconData icon, required String label, required Widget child, bool isLast = false}) {
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

  Widget _infoValue(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
    );
  }

  Widget _divider() {
    return Divider(color: Colors.white.withOpacity(0.05), height: 1);
  }

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
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
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