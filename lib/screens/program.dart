import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/models/food.dart';
import 'package:test_hh/models/exercice.dart';
import 'package:test_hh/models/bodyPart.dart';
import 'package:test_hh/models/notes.dart';
import 'package:test_hh/models/dayProgram.dart';
import 'package:test_hh/constants/urls.dart';
import 'package:test_hh/session/user_session.dart'; // ← UserSession

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  // ── Session ──────────────────────────────────────────────────────────────
  final _session = UserSession.instance;

  late Future<List<DayProgram>> _programFuture;
  late int _selectedDayIndex;
  static const _daysShort = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _daysFull  = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  /// ID du client connecté, lu depuis la session
  int get _clientId => _session.id;

  @override
 @override
void initState() {
  super.initState();
  _selectedDayIndex = (DateTime.now().weekday - 1).clamp(0, 6);
  _ensureSessionThenLoad();
}

Future<void> _ensureSessionThenLoad() async {
  if (!_session.isLoaded || _session.id == 0) {
    await _session.load();
  }
  print('=== ProgramScreen clientId: $_clientId ===');
  _loadProgram();
}

  Future<void> _loadProgram() {
    setState(() {
      _programFuture = _fetchProgram();
    });
    return _programFuture;
  }

  Future<List<DayProgram>> _fetchProgram() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/program/week?clientId=$_clientId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final weekData = data['data']['week'] as List;
          return weekData.map((dayData) {
            return DayProgram(
              day: dayData['day'],
              breakfastFoods: _parseFoods(dayData['breakfastFoods']),
              lunchFoods: _parseFoods(dayData['lunchFoods']),
              dinnerFoods: _parseFoods(dayData['dinnerFoods']),
              exercises: _parseExercises(dayData['exercises']),
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération du programme: $e');
      return [];
    }
  }

  List<FoodModel> _parseFoods(List<dynamic> foodsData) {
    return foodsData.map((food) {
      return FoodModel(
        id: food['id'].toString(),
        name: food['name'] ?? 'Unknown',
        imageUrl: food['imageUrl'] ?? '',
        calories: food['calories'] ?? 0,
        type: _parseFoodType(food['type']),
      );
    }).toList();
  }

  FoodType _parseFoodType(String? type) {
    switch (type?.toLowerCase()) {
      case 'liquid':
        return FoodType.liquid;
      case 'solid':
        return FoodType.solid;
      case 'grains':
        return FoodType.grains;
      case 'unit':
        return FoodType.unit;
      default:
        return FoodType.solid;
    }
  }

  List<ExerciceModel> _parseExercises(List<dynamic> exercisesData) {
    return exercisesData.map((exercise) {
      return ExerciceModel(
        id: exercise['id'].toString(),
        name: exercise['name'] ?? 'Unknown',
        description: exercise['description'] ?? '',
        image: exercise['image'] ?? '',
        video: exercise['video'] ?? '',
        type: _parseExerciseType(exercise['type'], exercise['muscle']),
        notes: [],
        part: BodyPartModel(
          id: 'bp-${exercise['bodyPart'] ?? 'unknown'}',
          name: exercise['bodyPart'] ?? 'Unknown',
          imageUrl: '',
          exercices: [],
        ),
      );
    }).toList();
  }

  ExerciceType _parseExerciseType(String? type, String? muscle) {
    if (type == 'cardio') return ExerciceType.cardio;
    if (type == 'flexibility') return ExerciceType.flexibility;
    return ExerciceType.strength;
  }

  @override
  Widget build(BuildContext context) {
    // Garde-fou session
    if (!_session.isLoaded) {
      return Scaffold(
        backgroundColor: kDarkBg,
        appBar: const Header(),
        body: const Center(
          child: CircularProgressIndicator(color: kNeonGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: const Header(),
      body: FutureBuilder<List<DayProgram>>(
        future: _programFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kNeonGreen));
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return _buildErrorState();
          }

          final week  = snapshot.data!;
          final today = week[_selectedDayIndex];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    const Text(
                      'MY PROGRAM',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5),
                    ),
                    const Spacer(),
                    // Fréquence d'entraînement du client connecté
                    if (_session.frequency > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kNeonGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: kNeonGreen.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${_session.frequency}x / week',
                          style: const TextStyle(
                              color: kNeonGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildDaySelector(week),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCalorieSummary(today),
                      const SizedBox(height: 20),
                      _buildMealSection(
                        icon: Icons.wb_sunny_rounded,
                        title: 'BREAKFAST',
                        foods: today.breakfastFoods,
                        color: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 14),
                      _buildMealSection(
                        icon: Icons.wb_cloudy_rounded,
                        title: 'LUNCH',
                        foods: today.lunchFoods,
                        color: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(height: 14),
                      _buildMealSection(
                        icon: Icons.nights_stay_rounded,
                        title: 'DINNER',
                        foods: today.dinnerFoods,
                        color: const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        icon: Icons.fitness_center,
                        title: 'EXERCISES',
                        count: today.exercises.length,
                        color: kNeonGreen,
                      ),
                      const SizedBox(height: 10),
                      ...today.exercises.map((e) => _buildExerciseItem(e)),
                      if (today.exercises.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            "Aucun exercice prévu pour aujourd'hui.",
                            style: TextStyle(
                                color: Colors.white38, fontSize: 14),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        const Text(
          "Impossible de charger le programme.",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _loadProgram,
          style: ElevatedButton.styleFrom(backgroundColor: kNeonGreen),
          child:
              const Text("Réessayer", style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  Widget _buildDaySelector(List<DayProgram> week) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedDayIndex == index;
          final isToday    = DateTime.now().weekday - 1 == index;
          final dayData    = week.length > index
              ? week[index]
              : DayProgram(
                  day: _daysFull[index],
                  breakfastFoods: [],
                  lunchFoods: [],
                  dinnerFoods: [],
                  exercises: [],
                );
          final hasData = dayData.breakfastFoods.isNotEmpty ||
              dayData.lunchFoods.isNotEmpty ||
              dayData.dinnerFoods.isNotEmpty ||
              dayData.exercises.isNotEmpty;

          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? kNeonGreen.withOpacity(0.15)
                    : kDarkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? kNeonGreen
                      : hasData
                          ? Colors.white24
                          : Colors.white10,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _daysShort[index],
                    style: TextStyle(
                      color: isSelected
                          ? kNeonGreen
                          : hasData
                              ? Colors.white
                              : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: kNeonGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalorieSummary(DayProgram day) {
    final breakfast = day.breakfastFoods.fold(0.0, (s, f) => s + f.calories);
    final lunch     = day.lunchFoods.fold(0.0, (s, f) => s + f.calories);
    final dinner    = day.dinnerFoods.fold(0.0, (s, f) => s + f.calories);
    final total     = breakfast + lunch + dinner;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kNeonGreen.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: kNeonGreen.withOpacity(0.05), blurRadius: 16)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kNeonGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_fire_department,
                    color: kNeonGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Calories',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '${total.toInt()} kcal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${day.exercises.length} exercises',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _mealCalChip('🌅', 'Breakfast', breakfast, const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _mealCalChip('☁️', 'Lunch', lunch, const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _mealCalChip('🌙', 'Dinner', dinner, const Color(0xFF8B5CF6)),
            ],
          ),
          // Objectif calorique personnel (basé sur le poids objectif du client)
          if (_session.weightGoal > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.flag_outlined,
                    color: Colors.white.withOpacity(0.35), size: 12),
                const SizedBox(width: 6),
                Text(
                  'Goal: ${_session.goal}  •  Target: ${_session.weightGoal.toStringAsFixed(1)} kg',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _mealCalChip(
      String emoji, String label, double cal, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              '${cal.toInt()} kcal',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection({
    required IconData icon,
    required String title,
    required List<FoodModel> foods,
    required Color color,
  }) {
    if (foods.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            icon: icon, title: title, count: foods.length, color: color),
        const SizedBox(height: 10),
        ...foods.map((f) => _buildFoodItem(f, color)),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodItem(FoodModel food, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: food.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      food.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.restaurant, color: accentColor, size: 20),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: accentColor,
                          ),
                        );
                      },
                    ),
                  )
                : Icon(Icons.restaurant, color: accentColor, size: 20),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  food.calLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withOpacity(0.2)),
            ),
            child: Text(
              food.typeLabel,
              style: TextStyle(
                color: accentColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(ExerciceModel exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kNeonGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: exercise.image.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      exercise.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.fitness_center,
                              color: kNeonGreen, size: 20),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: kNeonGreen,
                          ),
                        );
                      },
                    ),
                  )
                : const Icon(Icons.fitness_center,
                    color: kNeonGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  exercise.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kNeonGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kNeonGreen.withOpacity(0.2)),
            ),
            child: Text(
              exercise.typeLabel,
              style: const TextStyle(
                color: kNeonGreen,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}