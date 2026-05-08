import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/components/header.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

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

class Client {
  final int id;
  final String name;
  final String image;
  final DateTime birth;
  final double weight;
  final double height;
  final int frequency;
  final String goal;
  final double weightGoal;
  final DateTime createdAt;
  final int coachId;

  const Client({
    required this.id,
    required this.name,
    required this.image,
    required this.birth,
    required this.weight,
    required this.height,
    required this.frequency,
    required this.goal,
    required this.weightGoal,
    required this.createdAt,
    required this.coachId,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      birth: DateTime.parse(json['birth']),
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      frequency: json['frequency'],
      goal: json['goal'],
      weightGoal: (json['weightGoal'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      coachId: json['coachID'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'birth': birth.toIso8601String(),
      'weight': weight,
      'height': height,
      'frequency': frequency,
      'goal': goal,
      'weightGoal': weightGoal,
      'createdAt': createdAt.toIso8601String(),
      'coachID': coachId,
    };
  }

  int get age {
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  double get bmi => weight / ((height / 100) * (height / 100));
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ClientScreen extends StatefulWidget {
  final Client client;

  const ClientScreen({super.key, required this.client});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  final TextEditingController _programController = TextEditingController();
  bool _programEditing = false;

  // Mock weight-per-month data (replace with real data)
  final List<_WeightEntry> _weightHistory = [
    _WeightEntry(month: 'Nov', weight: 92.0),
    _WeightEntry(month: 'Dec', weight: 90.5),
    _WeightEntry(month: 'Jan', weight: 88.2),
    _WeightEntry(month: 'Feb', weight: 86.8),
    _WeightEntry(month: 'Mar', weight: 85.1),
    _WeightEntry(month: 'Apr', weight: 83.6),
    _WeightEntry(month: 'May', weight: 82.0),
  ];

  // Mock food list chosen by the client
  final List<FoodModel> _chosenFoods = const [
    FoodModel(
      id: '1',
      name: 'Grilled Chicken Breast',
      imageUrl: 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=100',
      calories: 165,
      type: FoodType.solid,
    ),
    FoodModel(
      id: '2',
      name: 'Oatmeal',
      imageUrl: 'https://images.pexels.com/photos/704971/pexels-photo-704971.jpeg?auto=compress&cs=tinysrgb&w=100',
      calories: 68,
      type: FoodType.grains,
    ),
    FoodModel(
      id: '3',
      name: 'Whey Protein Shake',
      imageUrl: 'https://images.pexels.com/photos/3622608/pexels-photo-3622608.jpeg?auto=compress&cs=tinysrgb&w=100',
      calories: 120,
      type: FoodType.liquid,
    ),
    FoodModel(
      id: '4',
      name: 'Boiled Eggs',
      imageUrl: 'https://images.pexels.com/photos/1123170/pexels-photo-1123170.jpeg?auto=compress&cs=tinysrgb&w=100',
      calories: 78,
      type: FoodType.unit,
    ),
    FoodModel(
      id: '5',
      name: 'Salmon Fillet',
      imageUrl: 'https://images.pexels.com/photos/3763847/pexels-photo-3763847.jpeg?auto=compress&cs=tinysrgb&w=100',
      calories: 208,
      type: FoodType.solid,
    ),
  ];

  @override
  void dispose() {
    _programController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                _buildProfileHeader(),
                const SizedBox(height: 14),
                _buildQuickStats(),
                const SizedBox(height: 14),
                _buildProgressCard(),
                const SizedBox(height: 14),
                _buildWeightChart(),
                const SizedBox(height: 14),
                _buildFoodList(),
                const SizedBox(height: 14),
                _buildCoachProgram(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
      // bottomNavigationBar: NavBar(),
    );
  }

  // ── Profile Header ──────────────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    final client = widget.client;
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
              // Avatar
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
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    client.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1E1E1E),
                      child: const Icon(Icons.person, color: kNeonGreen, size: 36),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name + goal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kNeonGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kNeonGreen.withOpacity(0.4)),
                      ),
                      child: Text(
                        client.goal.toUpperCase(),
                        style: const TextStyle(
                          color: kNeonGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${client.age} yrs  •  ${client.frequency}x / week',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // BMI badge
              _bmiPill(client.bmi),
            ],
          ),
        ),
      ),
    );
  }

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
        Text(
          bmi.toStringAsFixed(1),
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'BMI',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  // ── Quick Stats Row ─────────────────────────────────────────────────────────

  Widget _buildQuickStats() {
    final client = widget.client;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(child: _statTile(Icons.monitor_weight_outlined, 'WEIGHT', '${client.weight} kg')),
          const SizedBox(width: 10),
          Expanded(child: _statTile(Icons.height, 'HEIGHT', '${client.height.toInt()} cm')),
          const SizedBox(width: 10),
          Expanded(child: _statTile(Icons.flag_outlined, 'GOAL WT', '${client.weightGoal} kg')),
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress Card ───────────────────────────────────────────────────────────

  Widget _buildProgressCard() {
    final client = widget.client;
    final startWeight = _weightHistory.first.weight;
    final currentWeight = client.weight;
    final goalWeight = client.weightGoal;
    final totalToLose = startWeight - goalWeight;
    final lost = startWeight - currentWeight;
    final progress = totalToLose > 0 ? (lost / totalToLose).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kNeonGreen.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: kNeonGreen.withOpacity(0.06),
              blurRadius: 16,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular arc
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
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'DONE',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
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
                    const Text(
                      'WEIGHT PROGRESS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
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
                        '${lost.toStringAsFixed(1)} kg lost  •  ${(totalToLose - lost).toStringAsFixed(1)} kg to go',
                        style: const TextStyle(
                          color: kNeonGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
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
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Weight Chart ────────────────────────────────────────────────────────────

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
                  const Text(
                    'WEIGHT / MONTH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kNeonGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '6 months',
                      style: TextStyle(
                        color: kNeonGreen.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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
              // Month labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _weightHistory
                    .map(
                      (e) => Text(
                        e.month,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Food List ───────────────────────────────────────────────────────────────

  Widget _buildFoodList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CLIENT'S FOOD LIST",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Container(
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
                        Divider(height: 1, color: Colors.white.withOpacity(0.06)),
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
            child: Image.network(
              food.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 50,
                color: const Color(0xFF1E1E1E),
                child: const Icon(Icons.fastfood, color: Colors.white38, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  food.calLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                  ),
                ),
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
            child: Text(
              food.typeLabel,
              style: TextStyle(
                color: typeColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Coach Program ───────────────────────────────────────────────────────────

  Widget _buildCoachProgram() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'COACH PROGRAM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _programEditing = !_programEditing);
                },
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
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _programEditing ? 'SAVE' : 'EDIT',
                        style: const TextStyle(
                          color: kNeonGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                  ? [
                      BoxShadow(
                        color: kNeonGreen.withOpacity(0.08),
                        blurRadius: 20,
                        spreadRadius: 0,
                      )
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header bar
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
                          const Text(
                            'Training & Nutrition Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Written by coach',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (_programEditing)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: kNeonGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
                // Text area
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _programController,
                    enabled: _programEditing,
                    maxLines: null,
                    minLines: 8,
                    style: TextStyle(
                      color: _programEditing ? Colors.white : Colors.white.withOpacity(0.75),
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
                        color: Colors.white.withOpacity(0.25),
                        fontSize: 13,
                      ),
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
}

// ─── Weight Chart Painter ─────────────────────────────────────────────────────

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
    if (entries.isEmpty) return;

    final minW = entries.map((e) => e.weight).reduce(math.min) - 2;
    final maxW = entries.map((e) => e.weight).reduce(math.max) + 2;

    double xPos(int i) => i * size.width / (entries.length - 1);
    double yPos(double w) =>
        size.height - ((w - minW) / (maxW - minW)) * size.height;

    final points = List.generate(
        entries.length, (i) => Offset(xPos(i), yPos(entries[i].weight)));

    // Gradient fill under the line
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          kNeonGreen.withOpacity(0.25),
          kNeonGreen.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Horizontal grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Line
    final linePaint = Paint()
      ..color = kNeonGreen
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i - 1].dy);
      final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Glow
    final glowPaint = Paint()
      ..color = kNeonGreen.withOpacity(0.18)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(linePath, glowPaint);

    // Dots + weight labels
    for (int i = 0; i < points.length; i++) {
      // Outer ring
      canvas.drawCircle(
        points[i],
        5,
        Paint()..color = kNeonGreen.withOpacity(0.25),
      );
      // Inner dot
      canvas.drawCircle(
        points[i],
        3,
        Paint()..color = kNeonGreen,
      );

      // Weight value above dot
      final tp = TextPainter(
        text: TextSpan(
          text: entries[i].weight.toStringAsFixed(1),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, points[i].dy - 18));
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter old) => old.entries != entries;
}

// ─── Circular Progress Painter (reused from home.dart) ────────────────────────

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
  bool shouldRepaint(covariant _CircularProgressPainter old) =>
      old.progress != progress;
}