import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/components/header.dart';
import 'package:test_hh/models/client.dart';
import 'package:test_hh/models/coach.dart';
import 'package:test_hh/services/api_service.dart';
import 'package:test_hh/session/user_session.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODÈLES (utilisation des modèles externes)
// ─────────────────────────────────────────────────────────────────────────────

enum FoodType { solid, liquid, grains, unit }

class FoodModel {
  final String id;
  final String name;
  final String imageUrl;
  final double calories;
  final FoodType type;

  const FoodModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.calories,
    required this.type,
  });

  String get calLabel {
    switch (type) {
      case FoodType.liquid:
        return '${calories.toInt()} kcal/100ml';
      case FoodType.grains:
        return '${calories.toInt()} kcal/100g';
      case FoodType.unit:
        return '${calories.toInt()} kcal/unit';
      default:
        return '${calories.toInt()} kcal/100g';
    }
  }

  String get typeLabel {
    switch (type) {
      case FoodType.liquid:
        return 'LIQUID';
      case FoodType.grains:
        return 'SUPPL.';
      case FoodType.unit:
        return 'UNIT';
      default:
        return 'FOOD';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ClientScreen extends StatefulWidget {
  final Client? client;

  const ClientScreen({super.key, this.client});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  Client? _client;
  bool _loading = true;
  String? _error;

  List<FoodModel> _chosenFoods = [];
  bool _loadingFoods = false;
  List<_WeightEntry> _weightHistory = [];
  final TextEditingController _programController = TextEditingController();
  bool _programEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.client != null) {
      _client = widget.client;
      _loading = false;
      _loadClientData();
    } else {
      _loadFromSession();
    }
  }

  @override
  void dispose() {
    _programController.dispose();
    super.dispose();
  }

  void _loadFromSession() {
    final session = UserSession.instance;

    if (!session.isLoaded) {
      setState(() {
        _error = 'Session introuvable. Reconnectez-vous.';
        _loading = false;
      });
      return;
    }

    if (!session.isClient) {
      setState(() {
        _error = 'Cet écran est réservé aux clients.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _client = Client(
        id: session.id,
        name: session.name,
        email: session.email,
        image: session.image,
        birth: DateTime.tryParse(session.birth) ?? DateTime(2000),
        weight: session.weight,
        height: session.height,
        frequency: session.frequency,
        goal: session.goal,
        weightGoal: session.weightGoal,
        createdAt: DateTime.now(),
        coachID: session.coachID,
        gender: session.gender.isNotEmpty ? session.gender : 'Male',
        coach: session['coach'] != null
            ? Coach.fromJson(session['coach'] as Map<String, dynamic>)
            : null,
      );
      _loading = false;
    });

    _loadClientData();
  }

  Future<void> _loadClientData() async {
    if (_client == null) return;
    await Future.wait([
      _fetchChosenFoods(),
      _fetchWeightHistory(),
    ]);
  }

  Future<void> _fetchChosenFoods() async {
    if (_client == null) return;
    setState(() => _loadingFoods = true);
    try {
      final token = await ApiService.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final uri = Uri.parse(
          'http://192.168.0.232:5000/api/pahae/addFood/recent/${_client!.id}');
      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        final List raw = body['data'] as List? ?? [];
        setState(() {
          _chosenFoods = raw
              .map((j) => _foodFromJson(j as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {
      // Silencieux
    } finally {
      if (mounted) setState(() => _loadingFoods = false);
    }
  }

  Future<void> _fetchWeightHistory() async {
    if (_client == null) return;
    try {
      final token = await ApiService.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final uri = Uri.parse(
          'http://192.168.0.232:5000/api/jihane/clients/${_client!.id}/weight-history');
      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        final List raw = body['data'] as List? ?? [];
        setState(() {
          _weightHistory = raw
              .map((j) => _WeightEntry(
                    month: j['month'] as String? ?? '',
                    weight: (j['weight'] as num?)?.toDouble() ?? 0.0,
                  ))
              .toList();
        });
        return;
      }
    } catch (_) {}

    if (_weightHistory.isEmpty && _client != null) {
      setState(() {
        _weightHistory = [
          _WeightEntry(month: 'Nov', weight: _client!.weight + 10),
          _WeightEntry(month: 'Dec', weight: _client!.weight + 8),
          _WeightEntry(month: 'Jan', weight: _client!.weight + 6),
          _WeightEntry(month: 'Feb', weight: _client!.weight + 4),
          _WeightEntry(month: 'Mar', weight: _client!.weight + 2),
          _WeightEntry(month: 'Apr', weight: _client!.weight + 1),
          _WeightEntry(month: 'May', weight: _client!.weight),
        ];
      });
    }
  }

  FoodModel _foodFromJson(Map<String, dynamic> j) {
    FoodType type;
    switch ((j['type'] as String? ?? '').toLowerCase()) {
      case 'liquid':
        type = FoodType.liquid;
        break;
      case 'grains':
        type = FoodType.grains;
        break;
      case 'unit':
        type = FoodType.unit;
        break;
      default:
        type = FoodType.solid;
    }
    return FoodModel(
      id: j['id']?.toString() ?? '',
      name: j['name'] as String? ?? '',
      imageUrl: j['imageUrl'] as String? ?? '',
      calories: (j['calories'] as num?)?.toDouble() ?? 0.0,
      type: type,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: const Header(),
        body: const Center(
          child: CircularProgressIndicator(color: kNeonGreen, strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: const Header(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline,
                    color: Colors.white.withOpacity(0.2), size: 52),
                const SizedBox(height: 16),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 14)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _loadFromSession();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: kNeonGreen.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('RÉESSAYER',
                        style: TextStyle(
                            color: kNeonGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final client = _client!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const Header(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildProfileHeader(client),
                const SizedBox(height: 14),
                _buildQuickStats(client),
                const SizedBox(height: 14),
                if (_weightHistory.isNotEmpty) ...[
                  _buildProgressCard(client),
                  const SizedBox(height: 14),
                  _buildWeightChart(),
                  const SizedBox(height: 14),
                ],
                _buildFoodList(),
                const SizedBox(height: 14),
                _buildCoachProgram(client),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Client client) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF111111),
              kNeonGreen.withOpacity(0.03),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: kNeonGreen.withOpacity(0.08),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kNeonGreen, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: kNeonGreen.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: client.image.isNotEmpty
                      ? Image.network(client.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarFallback())
                      : _avatarFallback(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    if (client.goal.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kNeonGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: kNeonGreen.withOpacity(0.4)),
                        ),
                        child: Text(client.goal.toUpperCase(),
                            style: const TextStyle(
                                color: kNeonGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '${client.age} yrs'
                      '${client.gender.isNotEmpty ? '  ·  ${client.gender}' : ''}'
                      '  ·  ${client.frequency}x / week',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    if (client.coach != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              color: kNeonGreen, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'Coach: ${client.coach!.name}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _bmiPill(client.bmi),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback() => Container(
        color: const Color(0xFF1E1E1E),
        child: const Icon(Icons.person, color: kNeonGreen, size: 36),
      );

  Widget _bmiPill(double bmi) {
    String label;
    Color color;
    if (bmi < 18.5) {
      label = 'UNDER';
      color = Colors.blueAccent;
    } else if (bmi < 25) {
      label = 'NORMAL';
      color = kNeonGreen;
    } else if (bmi < 30) {
      label = 'OVER';
      color = Colors.orangeAccent;
    } else {
      label = 'OBESE';
      color = Colors.redAccent;
    }
    return Column(
      children: [
        Text(bmi.toStringAsFixed(1),
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        Text('BMI',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ),
      ],
    );
  }

  Widget _buildQuickStats(Client client) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
              child: _statTile(Icons.monitor_weight_outlined, 'WEIGHT',
                  '${client.weight} kg')),
          const SizedBox(width: 10),
          Expanded(
              child: _statTile(Icons.height, 'HEIGHT',
                  '${client.height.toInt()} cm')),
          const SizedBox(width: 10),
          Expanded(
              child: _statTile(Icons.flag_outlined, 'GOAL WT',
                  '${client.weightGoal} kg')),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kNeonGreen, size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildProgressCard(Client client) {
    final startWeight = _weightHistory.first.weight;
    final currentWeight = client.weight;
    final goalWeight = client.weightGoal;
    final totalToLose = startWeight - goalWeight;
    final lost = startWeight - currentWeight;
    final progress =
        totalToLose > 0 ? (lost / totalToLose).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kNeonGreen.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: kNeonGreen.withOpacity(0.06), blurRadius: 16)
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(110, 110),
                      painter: _CircularProgressPainter(progress: progress),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${(progress * 100).toInt()}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        Text('DONE',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WEIGHT PROGRESS',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    _progressRow('Start', '${startWeight.toStringAsFixed(1)} kg', 1.0),
                    const SizedBox(height: 8),
                    _progressRow('Current', '${currentWeight.toStringAsFixed(1)} kg', progress),
                    const SizedBox(height: 8),
                    _progressRow('Goal', '${goalWeight.toStringAsFixed(1)} kg', 0.15),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kNeonGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kNeonGreen.withOpacity(0.35)),
                      ),
                      child: Text(
                        '${lost.toStringAsFixed(1)} kg lost  ·  ${(totalToLose - lost).toStringAsFixed(1)} kg to go',
                        style: const TextStyle(
                            color: kNeonGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressRow(String label, String value, double progress) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(kNeonGreen),
              minHeight: 3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildWeightChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('WEIGHT / MONTH',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kNeonGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_weightHistory.length} months',
                      style: TextStyle(
                          color: kNeonGreen.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 140,
                child: CustomPaint(
                  painter: _WeightChartPainter(entries: _weightHistory),
                  size: const Size(double.infinity, 140),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _weightHistory
                    .map((e) => Text(e.month,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w600)))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CLIENT'S FOOD LIST",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5)),
          const SizedBox(height: 14),
          _loadingFoods
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(
                        color: kNeonGreen, strokeWidth: 2),
                  ),
                )
              : _chosenFoods.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kDarkCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Center(
                        child: Text('Aucun aliment enregistré',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 13)),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: kDarkCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(
                        children: [
                          ..._chosenFoods.asMap().entries.map((entry) {
                            final i = entry.key;
                            final food = entry.value;
                            return Column(
                              children: [
                                _buildFoodRow(food),
                                if (i < _chosenFoods.length - 1)
                                  Divider(
                                      height: 1,
                                      color: Colors.white.withOpacity(0.06)),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildFoodRow(FoodModel food) {
    Color typeColor;
    switch (food.type) {
      case FoodType.liquid:
        typeColor = Colors.blueAccent;
        break;
      case FoodType.grains:
        typeColor = Colors.orangeAccent;
        break;
      case FoodType.unit:
        typeColor = Colors.purpleAccent;
        break;
      default:
        typeColor = kNeonGreen;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: food.imageUrl.isNotEmpty
                ? Image.network(food.imageUrl,
                    width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _foodFallback())
                : _foodFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(food.calLabel,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45), fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: typeColor.withOpacity(0.4)),
            ),
            child: Text(food.typeLabel,
                style: TextStyle(
                    color: typeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _foodFallback() => Container(
        width: 50,
        height: 50,
        color: const Color(0xFF1E1E1E),
        child: const Icon(Icons.fastfood, color: Colors.white38, size: 20),
      );

  Widget _buildCoachProgram(Client client) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('COACH PROGRAM',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
              GestureDetector(
                onTap: () => setState(() => _programEditing = !_programEditing),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kNeonGreen, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          _programEditing ? Icons.check : Icons.edit_outlined,
                          color: kNeonGreen,
                          size: 13),
                      const SizedBox(width: 5),
                      Text(_programEditing ? 'SAVE' : 'EDIT',
                          style: const TextStyle(
                              color: kNeonGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (client.coach != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kDarkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kNeonGreen.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: client.coach!.image != null &&
                            client.coach!.image!.isNotEmpty
                        ? Image.network(client.coach!.image!,
                            width: 40, height: 40, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _coachAvatarFallback())
                        : _coachAvatarFallback(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(client.coach!.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        if (client.coach!.specialty != null &&
                            client.coach!.specialty!.isNotEmpty)
                          Text(client.coach!.specialty!,
                              style: TextStyle(
                                  color: kNeonGreen.withOpacity(0.7),
                                  fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: kDarkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _programEditing
                    ? kNeonGreen.withOpacity(0.5)
                    : Colors.white.withOpacity(0.06),
                width: _programEditing ? 1.5 : 1,
              ),
              boxShadow: _programEditing
                  ? [BoxShadow(color: kNeonGreen.withOpacity(0.08), blurRadius: 20)]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: kNeonGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fitness_center, color: kNeonGreen, size: 15),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Training & Nutrition Plan',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          Text('Written by coach',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11)),
                        ],
                      ),
                      const Spacer(),
                      if (_programEditing)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: kNeonGreen, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _programController,
                    enabled: _programEditing,
                    maxLines: null,
                    minLines: 8,
                    style: TextStyle(
                      color: _programEditing
                          ? Colors.white
                          : Colors.white.withOpacity(0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.7,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: _programEditing
                          ? 'Write the training & nutrition program here…'
                          : 'No program written yet. Tap EDIT to add one.',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.25), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    cursorColor: kNeonGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coachAvatarFallback() => Container(
        width: 40,
        height: 40,
        color: const Color(0xFF1E1E1E),
        child: const Icon(Icons.person, color: kNeonGreen, size: 22),
      );
}

// ─── Painters (inchangés) ───────────────────────────────────────────────────

class _WeightEntry {
  final String month;
  final double weight;
  const _WeightEntry({required this.month, required this.weight});
}

class _WeightChartPainter extends CustomPainter {
  final List<_WeightEntry> entries;
  const _WeightChartPainter({required this.entries});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;

    final minW = entries.map((e) => e.weight).reduce(math.min) - 2;
    final maxW = entries.map((e) => e.weight).reduce(math.max) + 2;

    double xPos(int i) => i * size.width / (entries.length - 1);
    double yPos(double w) => size.height - ((w - minW) / (maxW - minW)) * size.height;

    final points = List.generate(entries.length, (i) => Offset(xPos(i), yPos(entries[i].weight)));

    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath..lineTo(points.last.dx, size.height)..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kNeonGreen.withOpacity(0.25), kNeonGreen.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i - 1].dy);
      final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = kNeonGreen
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = kNeonGreen.withOpacity(0.18)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 5, Paint()..color = kNeonGreen.withOpacity(0.25));
      canvas.drawCircle(points[i], 3, Paint()..color = kNeonGreen);

      final tp = TextPainter(
        text: TextSpan(
          text: entries[i].weight.toStringAsFixed(1),
          style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 9,
              fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, points[i].dy - 18));
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter old) => old.entries != entries;
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  const _CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2;
    const strokeWidth = 11.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [
            const Color(0xFFA3FF12).withOpacity(0.6),
            const Color(0xFFA3FF12),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = const Color(0xFFA3FF12).withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter old) => old.progress != progress;
}