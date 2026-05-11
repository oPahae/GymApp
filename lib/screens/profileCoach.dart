import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/models/client.dart';
import 'package:test_hh/models/coach.dart';
import 'package:test_hh/screens/login.dart';
import 'package:test_hh/screens/profileClient.dart';
import 'package:test_hh/services/api_service.dart';
import 'package:test_hh/session/user_session.dart';

class ProfileCoach extends StatefulWidget {
  const ProfileCoach({super.key});

  @override
  State<ProfileCoach> createState() => _ProfileCoachState();
}

class _ProfileCoachState extends State<ProfileCoach> {
  Coach? _coach;
  bool _isLoading = true;
  String? _error;
  bool _isEditing = false;
  XFile? _profileImage;
  String? _imageUrl;

  late TextEditingController _nameController;
  late TextEditingController _specialtyController;
  late TextEditingController _bioController;

  final List<Map<String, dynamic>> _goals = [
    {'icon': Icons.local_fire_department, 'title': 'Lose Weight'},
    {'icon': Icons.fitness_center, 'title': 'Build Muscle'},
    {'icon': Icons.monitor_heart, 'title': 'Stay Healthy'},
    {'icon': Icons.directions_run, 'title': 'Boost Endurance'},
    {'icon': Icons.self_improvement, 'title': 'Flexibility'},
    {'icon': Icons.electric_bolt, 'title': 'Recomposition'},
  ];

  final List<Map<String, String>> _frequencies = [
    {'title': 'Beginner', 'sub': '1 – 2 days / week'},
    {'title': 'Light', 'sub': '3 days / week'},
    {'title': 'Moderate', 'sub': '4 days / week'},
    {'title': 'Active', 'sub': '5 days / week'},
    {'title': 'Athlete', 'sub': '6 – 7 days / week'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _specialtyController = TextEditingController();
    _bioController = TextEditingController();
    _loadCoach();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // --- Cloudinary Upload ---
  Future<String?> _uploadImageToCloudinary(XFile imageFile) async {
    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/dlqcknocf/image/upload");
      final request = http.MultipartRequest("POST", uri);
      request.fields['upload_preset'] = 'GymApp'; // Remplacez par votre preset Cloudinary

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

  // --- Load Coach Profile ---
  Future<void> _loadCoach() async {
    setState(() { _isLoading = true; _error = null; });

    if (!UserSession.instance.isLoaded) {
      final success = await UserSession.instance.load();
      if (!success) {
        setState(() {
          _error = "Session expirée. Veuillez vous reconnecter.";
          _isLoading = false;
        });
        return;
      }
    }

    final res = await ApiService.getMyCoachProfile();
    if (!mounted) return;

    if (res['success'] == true && res['coach'] != null) {
      try {
        final coachJson = res['coach'] as Map<String, dynamic>;
        if (coachJson['clients'] == null) {
          coachJson['clients'] = [];
        }
        final coach = Coach.fromJson(coachJson);
        setState(() {
          _coach = coach;
          _imageUrl = coach.image.isNotEmpty ? coach.image : null;
          _nameController.text = coach.name;
          _specialtyController.text = coach.specialty ?? '';
          _bioController.text = coach.bio ?? '';
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = "Erreur lors du chargement du profil: ${e.toString()}";
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _error = res['message'] ?? 'Erreur de chargement.';
        _isLoading = false;
      });
    }
  }

  // --- Save Coach Profile ---
  Future<void> _saveCoach() async {
    if (_coach == null) return;

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
            content: const Text('Échec du téléchargement de l\'image. Veuillez réessayer.'),
          ),
        );
        return;
      }
    }

    final res = await ApiService.updateCoach(_coach!.id, {
      'name': _nameController.text.trim(),
      'specialty': _specialtyController.text.trim(),
      'bio': _bioController.text.trim(),
      'image': imageUrl,
    });

    if (!mounted) return;

    if (res['success'] == true && res['coach'] != null) {
      final updated = Coach.fromJson(res['coach'] as Map<String, dynamic>);
      setState(() {
        _coach = updated.copyWith(clients: _coach!.clients);
        _imageUrl = updated.image;
        _profileImage = null; // Réinitialiser après sauvegarde
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: res['success'] == true ? kNeonGreen.withOpacity(0.9) : Colors.redAccent.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          res['success'] == true ? 'Profil sauvegardé !' : res['message'] ?? 'Erreur.',
          style: const TextStyle(color: kDarkBg, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // --- Helper Methods ---
  String _formattedDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = picked);
    }
  }

  void _toggleEdit() async {
    if (_isEditing) {
      await _saveCoach();
    }
    setState(() => _isEditing = !_isEditing);
  }

  void _openClientProfile(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileClient(clientId: client.id)),
    );
  }

  Future<void> _logout() async {
    await ApiService.logout();
    UserSession.instance.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // --- UI Builders ---
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kNeonGreen),
      );
    }
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
              onTap: _loadCoach,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: kNeonGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kNeonGreen.withOpacity(0.4)),
                ),
                child: const Text('Réessayer', style: TextStyle(color: kNeonGreen, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    }
    if (_coach == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
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
            'MY CLIENTS (${_coach!.clients.length})',
            _buildClientList(),
          ),
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
          const Text(
            'COACH PROFILE',
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
    final coach = _coach!;
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
            'COACH · ${coach.clients.length} clients',
            style: const TextStyle(color: Color(0xFF1A6BFF), fontSize: 11, fontWeight: FontWeight.w700),
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
                                  Icons.sports_gymnastics_rounded,
                                  color: kNeonGreen,
                                  size: 34,
                                ),
                              ),
                            )
                          : const Icon(Icons.sports_gymnastics_rounded, color: kNeonGreen, size: 34)),
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
                  'Membre depuis ${_formattedDate(coach.createdAt)}',
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
            label: 'Nom complet',
            child: _isEditing ? _inlineTextField(_nameController) : _infoValue(_nameController.text.isEmpty ? '—' : _nameController.text),
          ),
          _divider(),
          _infoRow(
            icon: Icons.badge_outlined,
            label: 'Coach ID',
            child: _infoValue('#${_coach!.id}'),
          ),
          _divider(),
          _infoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Membre depuis',
            child: _infoValue(_formattedDate(_coach!.createdAt)),
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
        label: 'Spécialité',
        child: _isEditing
            ? _inlineTextField(_specialtyController, width: 180)
            : _infoValue(_specialtyController.text.isEmpty ? '—' : _specialtyController.text),
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
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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
                hintText: 'Écrivez quelque chose sur vous…',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
              ),
            )
          : Text(
              _bioController.text.isEmpty ? 'Pas de bio.' : _bioController.text,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.6),
            ),
    );
  }

  Widget _buildClientList() {
    final clients = _coach!.clients;

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
              'Pas encore de clients',
              style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13, fontWeight: FontWeight.w600),
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
          final goalEntry = _goals.firstWhere((g) => g['title'] == client.goal, orElse: () => _goals.first);

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
                            : const Icon(Icons.person_outline_rounded, color: kNeonGreen, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.name,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(goalEntry['icon'] as IconData, color: kNeonGreen, size: 11),
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
                          _miniChip('${client.weight.toStringAsFixed(1)} kg', Icons.monitor_weight_outlined),
                          const SizedBox(height: 4),
                          _miniChip(
                            _frequencies[client.frequency.clamp(0, _frequencies.length - 1)]['title']!,
                            Icons.fitness_center,
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
                    ],
                  ),
                ),
              ),
              if (!isLast) Divider(color: Colors.white.withOpacity(0.05), height: 1),
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
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w600),
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