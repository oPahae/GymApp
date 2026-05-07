import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/screens/home.dart';
import 'package:test_hh/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- État du formulaire ---
  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isLoading = false;
  int? _selectedCoachId;

  // Contrôleurs pour les champs texte
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightGoalController = TextEditingController();

  // Données du formulaire
  XFile? _profileImage; // ✅ XFile au lieu de File
  DateTime? _birthDate;
  String? _gender;
  double _weight = 70;
  double _height = 175;
  double _weightGoal = 65;
  bool _weightInKg = true;
  bool _heightInCm = true;
  String _goal = 'Lose Weight';
  int _frequency = 1;

  // Options pour les objectifs et fréquences
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

  // --- Cycle de vie ---
  @override
  void initState() {
    super.initState();
    _weightController.text = _weight.toStringAsFixed(1);
    _heightController.text = _height.toStringAsFixed(0);
    _weightGoalController.text = _weightGoal.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _weightGoalController.dispose();
    super.dispose();
  }

  // --- Logique métier ---
  String get _weightLabel => _weightInKg ? 'KG' : 'LBS';
  String get _heightLabel => _heightInCm ? 'CM' : 'FT';
  double get _displayWeight => _weightInKg ? _weight : _weight * 2.205;
  double get _displayHeight => _heightInCm ? _height : _height / 30.48;
  double get _displayGoalWeight => _weightInKg ? _weightGoal : _weightGoal * 2.205;

  void _updateWeightFromText(String text) {
    final value = double.tryParse(text);
    if (value != null && value > 0) {
      setState(() => _weight = value);
    } else {
      _weightController.text = _weight.toStringAsFixed(1);
    }
  }

  void _updateHeightFromText(String text) {
    final value = double.tryParse(text);
    if (value != null && value > 0) {
      setState(() => _height = value);
    } else {
      _heightController.text = _height.toStringAsFixed(_heightInCm ? 0 : 1);
    }
  }

  void _updateWeightGoalFromText(String text) {
    final value = double.tryParse(text);
    if (value != null && value > 0) {
      setState(() => _weightGoal = value);
    } else {
      _weightGoalController.text = _weightGoal.toStringAsFixed(1);
    }
  }

  // ✅ Sélection image — retourne XFile
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = picked);
    }
  }

  // ✅ Upload vers Cloudinary — retourne l'URL sécurisée
  Future<String?> _uploadImageToCloudinary(XFile imageFile) async {
    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/dlqcknocf/image/upload",
      );

      final request = http.MultipartRequest("POST", uri);
      request.fields['upload_preset'] = 'GymApp';

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: imageFile.name,
          ),
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

  // Sélection de la date de naissance
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kNeonGreen,
            onPrimary: kDarkBg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  // Validation des champs obligatoires
  bool _validateStep() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.isEmpty) {
          _showErrorSnackbar('Please enter your name.');
          return false;
        }
        if (_emailController.text.isEmpty) {
          _showErrorSnackbar('Please enter your email.');
          return false;
        }
        if (_passwordController.text.isEmpty) {
          _showErrorSnackbar('Please enter a password.');
          return false;
        }
        if (!_emailController.text.contains('@')) {
          _showErrorSnackbar('Please enter a valid email.');
          return false;
        }
        if (_passwordController.text.length < 6) {
          _showErrorSnackbar('Password must be at least 6 characters.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ✅ Inscription avec upload Cloudinary avant envoi backend
  Future<void> _submitRegistration() async {
    if (!_validateStep()) return;
    setState(() => _isLoading = true);

    try {
      // 1️⃣ Upload image vers Cloudinary
      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await _uploadImageToCloudinary(_profileImage!);
        if (imageUrl == null) {
          _showErrorSnackbar('Image upload failed. Please try again.');
          setState(() => _isLoading = false);
          return;
        }
      }

      // 2️⃣ Envoi des données au backend avec l'URL Cloudinary
      final response = await ApiService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        image: imageUrl, // ✅ URL Cloudinary (ex: https://res.cloudinary.com/...)
        birth: _birthDate != null ? DateFormat('yyyy-MM-dd').format(_birthDate!) : null,
        weight: _weightInKg ? _weight : _weight / 2.205,
        height: _heightInCm ? _height : _height * 30.48,
        frequency: _frequency + 1,
        goal: _goal,
        weightGoal: _weightInKg ? _weightGoal : _weightGoal / 2.205,
        gender: _gender,
        coachID: _selectedCoachId,
      );

      if (response['success'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        _showErrorSnackbar(response['message'] ?? 'Registration failed.');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Navigation entre les étapes
  void _next() {
    if (_currentStep < _totalSteps - 1) {
      if (_validateStep()) {
        setState(() => _currentStep++);
      }
    } else {
      _submitRegistration();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  // --- Titres des étapes ---
  String _stepTitle() {
    switch (_currentStep) {
      case 0: return 'YOUR\n';
      case 1: return 'BODY\n';
      case 2: return 'YOUR\n';
      case 3: return 'HOW OFTEN\n';
      default: return "YOU'RE ALL\n";
    }
  }

  String _stepAccent() {
    switch (_currentStep) {
      case 0: return 'PROFILE.';
      case 1: return 'STATS.';
      case 2: return 'GOAL.';
      case 3: return 'DO YOU TRAIN?';
      default: return 'SET!';
    }
  }

  String _stepSub() {
    switch (_currentStep) {
      case 0: return "Let's set up your identity";
      case 1: return "We'll personalize your plan";
      case 2: return "What are you training for?";
      case 3: return "We'll adapt your weekly plan";
      default: return "Your profile is ready. Time to crush your goals.";
    }
  }

  // --- Construction de l'UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kNeonGreen.withOpacity(0.09), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kNeonGreen.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepTitle(),
                        const SizedBox(height: 24),
                        _buildStepContent(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: kNeonGreen),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _back,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'STEP ${_currentStep + 1} OF $_totalSteps',
                style: TextStyle(
                  color: kGrayText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: const AlwaysStoppedAnimation<Color>(kNeonGreen),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, height: 1.05),
            children: [
              TextSpan(text: _stepTitle(), style: const TextStyle(color: Colors.white)),
              TextSpan(text: _stepAccent(), style: const TextStyle(color: kNeonGreen)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(_stepSub(), style: TextStyle(color: kGrayText, fontSize: 13)),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      case 3: return _buildStep4();
      default: return _buildStep5();
    }
  }

  // --- Étape 1: Profil ---
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kNeonGreen.withOpacity(0.06),
                        border: Border.all(color: kNeonGreen.withOpacity(0.35), width: 2),
                      ),
                      // ✅ Affichage image selon plateforme
                      child: _profileImage != null
                          ? ClipOval(
                              child: kIsWeb
                                  ? Image.network(
                                      _profileImage!.path,
                                      fit: BoxFit.cover,
                                      width: 90,
                                      height: 90,
                                    )
                                  : Image.file(
                                      File(_profileImage!.path),
                                      fit: BoxFit.cover,
                                      width: 90,
                                      height: 90,
                                    ),
                            )
                          : const Icon(Icons.fitness_center, color: kNeonGreen, size: 36),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kNeonGreen,
                          border: Border.all(color: kDarkBg, width: 2),
                        ),
                        child: const Icon(Icons.add, color: kDarkBg, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Tap to upload photo', style: TextStyle(color: kGrayText, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _inputLabel('FULL NAME'),
        _inputField(controller: _nameController, hint: 'Enter your full name', icon: Icons.person_outline_rounded),
        _inputLabel('EMAIL'),
        _inputField(controller: _emailController, hint: 'Enter your email', icon: Icons.email_outlined),
        _inputLabel('PASSWORD'),
        _inputField(controller: _passwordController, hint: 'Enter your password', icon: Icons.lock_outline, isPassword: true),
        _inputLabel('DATE OF BIRTH'),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            height: 52,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined, color: kGrayText, size: 18),
                const SizedBox(width: 10),
                Text(
                  _birthDate != null
                      ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                      : 'Select your birth date',
                  style: TextStyle(
                    color: _birthDate != null ? Colors.white : kGrayText.withOpacity(0.55),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        _inputLabel('GENDER'),
        _buildGenderSelector(),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        _genderTile('Male', Icons.male_rounded),
        const SizedBox(width: 10),
        _genderTile('Female', Icons.female_rounded),
      ],
    );
  }

  Widget _genderTile(String label, IconData icon) {
    final selected = _gender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 64,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: selected ? kNeonGreen.withOpacity(0.10) : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? kNeonGreen.withOpacity(0.6) : Colors.white.withOpacity(0.08),
            ),
            boxShadow: selected ? [BoxShadow(color: kNeonGreen.withOpacity(0.12), blurRadius: 12)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kNeonGreen, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? kNeonGreen : Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? kNeonGreen : Colors.transparent,
                  border: Border.all(
                    color: selected ? kNeonGreen : Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: selected ? [BoxShadow(color: kNeonGreen.withOpacity(0.5), blurRadius: 6)] : [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Étape 2: Stats ---
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputLabel(
          'WEIGHT',
          unitToggle: _buildUnitToggle(['KG', 'LBS'], _weightInKg, (kg) {
            setState(() {
              if (_weightInKg != kg) {
                _weight = kg ? _weight / 2.205 : _weight * 2.205;
                _weightGoal = kg ? _weightGoal / 2.205 : _weightGoal * 2.205;
                _weightInKg = kg;
                _weightController.text = _weight.toStringAsFixed(1);
                _weightGoalController.text = _weightGoal.toStringAsFixed(1);
              }
            });
          }),
        ),
        _buildNumberRowWithInput(
          controller: _weightController,
          value: _displayWeight,
          unit: _weightLabel.toLowerCase(),
          onChanged: _updateWeightFromText,
          onMinus: () => setState(() {
            _weight -= _weightInKg ? 0.5 : 1;
            _weightController.text = _weight.toStringAsFixed(1);
          }),
          onPlus: () => setState(() {
            _weight += _weightInKg ? 0.5 : 1;
            _weightController.text = _weight.toStringAsFixed(1);
          }),
        ),
        const SizedBox(height: 6),
        _inputLabel(
          'HEIGHT',
          unitToggle: _buildUnitToggle(['CM', 'FT'], _heightInCm, (cm) {
            setState(() {
              if (_heightInCm != cm) {
                _height = cm ? _height * 30.48 : _height / 30.48;
                _heightInCm = cm;
                _heightController.text = _height.toStringAsFixed(cm ? 0 : 1);
              }
            });
          }),
        ),
        _buildNumberRowWithInput(
          controller: _heightController,
          value: _displayHeight,
          unit: _heightLabel.toLowerCase(),
          decimals: _heightInCm ? 0 : 1,
          onChanged: _updateHeightFromText,
          onMinus: () => setState(() {
            _height -= _heightInCm ? 1 : 0.01;
            _heightController.text = _height.toStringAsFixed(_heightInCm ? 0 : 1);
          }),
          onPlus: () => setState(() {
            _height += _heightInCm ? 1 : 0.01;
            _heightController.text = _height.toStringAsFixed(_heightInCm ? 0 : 1);
          }),
        ),
        const SizedBox(height: 6),
        _inputLabel('WEIGHT GOAL'),
        _buildNumberRowWithInput(
          controller: _weightGoalController,
          value: _displayGoalWeight,
          unit: _weightLabel.toLowerCase(),
          onChanged: _updateWeightGoalFromText,
          onMinus: () => setState(() {
            _weightGoal -= _weightInKg ? 0.5 : 1;
            _weightGoalController.text = _weightGoal.toStringAsFixed(1);
          }),
          onPlus: () => setState(() {
            _weightGoal += _weightInKg ? 0.5 : 1;
            _weightGoalController.text = _weightGoal.toStringAsFixed(1);
          }),
        ),
      ],
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
                  color: selected ? kDarkBg : kGrayText,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNumberRowWithInput({
    required TextEditingController controller,
    required double value,
    required String unit,
    required ValueChanged<String> onChanged,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    int decimals = 1,
  }) {
    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          _numBtn(Icons.remove, onMinus),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: value.toStringAsFixed(decimals),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(unit, style: TextStyle(color: kGrayText, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          _numBtn(Icons.add, onPlus),
        ],
      ),
    );
  }

  Widget _numBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: icon == Icons.remove
              ? const BorderRadius.horizontal(left: Radius.circular(14))
              : const BorderRadius.horizontal(right: Radius.circular(14)),
        ),
        child: Icon(icon, color: kNeonGreen, size: 20),
      ),
    );
  }

  // --- Étape 3: Objectif ---
  Widget _buildStep3() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: _goals.map((goal) {
        final selected = _goal == goal['title'];
        return GestureDetector(
          onTap: () => setState(() => _goal = goal['title']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? kNeonGreen.withOpacity(0.10) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? kNeonGreen.withOpacity(0.6) : Colors.white.withOpacity(0.08),
              ),
              boxShadow: selected ? [BoxShadow(color: kNeonGreen.withOpacity(0.12), blurRadius: 12)] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(goal['icon']!, size: 24, color: kNeonGreen),
                const SizedBox(height: 6),
                Text(
                  goal['title']!,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? kNeonGreen : Colors.white),
                ),
                Text(goal['sub']!, style: TextStyle(fontSize: 10, color: kGrayText)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Étape 4: Fréquence ---
  Widget _buildStep4() {
    return Column(
      children: _frequencies.asMap().entries.map((entry) {
        final index = entry.key;
        final frequency = entry.value;
        final selected = _frequency == index;
        return GestureDetector(
          onTap: () => setState(() => _frequency = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        frequency['title']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected ? kNeonGreen : Colors.white,
                        ),
                      ),
                      Text(frequency['sub']!, style: TextStyle(fontSize: 11, color: kGrayText)),
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

  // --- Étape 5: Résumé ---
  Widget _buildStep5() {
    return Column(
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kNeonGreen.withOpacity(0.12),
                  border: Border.all(color: kNeonGreen.withOpacity(0.4), width: 2),
                  boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.2), blurRadius: 30)],
                ),
                child: const Icon(Icons.check_rounded, color: kNeonGreen, size: 38),
              ),
              const SizedBox(height: 12),
              Text(
                "Your profile is ready. Time to crush your goals.",
                textAlign: TextAlign.center,
                style: TextStyle(color: kGrayText, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kDarkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              _summaryRow('Name', _nameController.text.isEmpty ? '—' : _nameController.text, Icons.person_outline),
              _summaryRow('Email', _emailController.text.isEmpty ? '—' : _emailController.text, Icons.email_outlined),
              _summaryRow('Gender', _gender ?? '—', Icons.wc_outlined),
              _summaryRow('Weight', '${_displayWeight.toStringAsFixed(1)} ${_weightLabel.toLowerCase()}', Icons.monitor_weight_outlined),
              _summaryRow('Height', '${_displayHeight.toStringAsFixed(_heightInCm ? 0 : 1)} ${_heightLabel.toLowerCase()}', Icons.height),
              _summaryRow('Goal Weight', '${_displayGoalWeight.toStringAsFixed(1)} ${_weightLabel.toLowerCase()}', Icons.flag_outlined),
              _summaryRow('Fitness Goal', _goal, Icons.track_changes_outlined),
              _summaryRow('Frequency', _frequencies[_frequency]['title']!, Icons.calendar_today_outlined, isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, IconData icon, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
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
              Expanded(child: Text(label, style: TextStyle(color: kGrayText, fontSize: 12))),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.white.withOpacity(0.05), height: 1),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _next,
        style: ElevatedButton.styleFrom(
          backgroundColor: kNeonGreen,
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 12,
          shadowColor: kNeonGreen.withOpacity(0.45),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: kDarkBg, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep < _totalSteps - 1 ? 'CONTINUE' : 'START MY JOURNEY',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: kDarkBg,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, color: kDarkBg, size: 18),
                ],
              ),
      ),
    );
  }

  Widget _inputLabel(String label, {Widget? unitToggle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: kGrayText, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
          ),
          if (unitToggle != null) ...[const Spacer(), unitToggle],
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: kGrayText, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: kGrayText.withOpacity(0.55), fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}