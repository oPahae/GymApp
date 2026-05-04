import 'package:flutter/material.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/models/food.dart';
import 'package:test_hh/models/exercice.dart';
import 'package:test_hh/models/bodyPart.dart';
import 'package:test_hh/models/notes.dart';
import 'package:test_hh/models/dayProgram.dart';

// ─── Fake exercises (sans notes pour éviter la circularité) ──────────────────

final _fakeExChest = ExerciceModel(
  id: 'e1', name: 'Bench Press', description: '4x10 reps',
  image: '', video: '', type: ExerciceType.strength, notes: [],
  part: BodyPartModel(id: 'bp1', name: 'Chest',    imageUrl: '', exercices: []),
);
final _fakeExRunning = ExerciceModel(
  id: 'e2', name: 'Running', description: '30 min',
  image: '', video: '', type: ExerciceType.cardio, notes: [],
  part: BodyPartModel(id: 'bp2', name: 'Cardio',   imageUrl: '', exercices: []),
);
final _fakeExSquat = ExerciceModel(
  id: 'e3', name: 'Squat', description: '5x8 reps',
  image: '', video: '', type: ExerciceType.strength, notes: [],
  part: BodyPartModel(id: 'bp3', name: 'Legs',     imageUrl: '', exercices: []),
);
final _fakeExLegPress = ExerciceModel(
  id: 'e4', name: 'Leg Press', description: '4x12 reps',
  image: '', video: '', type: ExerciceType.strength, notes: [],
  part: BodyPartModel(id: 'bp3', name: 'Legs',     imageUrl: '', exercices: []),
);
final _fakeExYoga = ExerciceModel(
  id: 'e5', name: 'Yoga Flow', description: '45 min',
  image: '', video: '', type: ExerciceType.flexibility, notes: [],
  part: BodyPartModel(id: 'bp2', name: 'Cardio',   imageUrl: '', exercices: []),
);
final _fakeExPullups = ExerciceModel(
  id: 'e6', name: 'Pull-ups', description: '4x8 reps',
  image: '', video: '', type: ExerciceType.strength, notes: [],
  part: BodyPartModel(id: 'bp4', name: 'Back',     imageUrl: '', exercices: []),
);
final _fakeExDeadlift = ExerciceModel(
  id: 'e7', name: 'Deadlift', description: '3x6 reps',
  image: '', video: '', type: ExerciceType.strength, notes: [],
  part: BodyPartModel(id: 'bp4', name: 'Back',     imageUrl: '', exercices: []),
);
final _fakeExShoulderPress = ExerciceModel(
  id: 'e8', name: 'Shoulder Press', description: '4x10 reps',
  image: '', video: '', type: ExerciceType.strength, notes: [],
  part: BodyPartModel(id: 'bp5', name: 'Shoulders',imageUrl: '', exercices: []),
);
final _fakeExLateralRaises = ExerciceModel(
  id: 'e9', name: 'Lateral Raises', description: '3x15 reps',
  image: '', video: '', type: ExerciceType.strength, notes: [],
  part: BodyPartModel(id: 'bp5', name: 'Shoulders',imageUrl: '', exercices: []),
);
final _fakeExHIIT = ExerciceModel(
  id: 'e10', name: 'HIIT Circuit', description: '20 min',
  image: '', video: '', type: ExerciceType.cardio, notes: [],
  part: BodyPartModel(id: 'bp2', name: 'Cardio',   imageUrl: '', exercices: []),
);
final _fakeExStretching = ExerciceModel(
  id: 'e11', name: 'Stretching', description: '30 min',
  image: '', video: '', type: ExerciceType.flexibility, notes: [],
  part: BodyPartModel(id: 'bp2', name: 'Cardio',   imageUrl: '', exercices: []),
);

// ─── Fake Data ────────────────────────────────────────────────────────────────

final List<DayProgram> fakeProgramWeek = [
  DayProgram(
    day: 'Monday',
    breakfastFoods: [
      FoodModel(id: 'f1', name: 'Oatmeal',      imageUrl: 'https://images.pexels.com/photos/704971/pexels-photo-704971.jpeg?auto=compress&cs=tinysrgb&w=200', calories: 350, type: FoodType.grains),
      FoodModel(id: 'f2', name: 'Protein Shake', imageUrl: 'https://images.pexels.com/photos/4753650/pexels-photo-4753650.jpeg', calories: 180, type: FoodType.liquid),
    ],
    lunchFoods: [
      FoodModel(id: 'f3', name: 'Chicken Breast',imageUrl: 'https://images.pexels.com/photos/9219085/pexels-photo-9219085.jpeg', calories: 165, type: FoodType.solid),
      FoodModel(id: 'f4', name: 'Brown Rice',    imageUrl: 'https://images.pexels.com/photos/8108117/pexels-photo-8108117.jpeg', calories: 215, type: FoodType.grains),
    ],
    dinnerFoods: [
      FoodModel(id: 'f5', name: 'Salmon',        imageUrl: 'https://images.pexels.com/photos/36676405/pexels-photo-36676405.jpeg', calories: 208, type: FoodType.solid),
      FoodModel(id: 'f6', name: 'Green Tea',     imageUrl: 'https://images.pexels.com/photos/31251487/pexels-photo-31251487.png', calories: 2,   type: FoodType.liquid),
    ],
    exercises: [_fakeExChest, _fakeExRunning],
  ),
  DayProgram(
    day: 'Tuesday',
    breakfastFoods: [
      FoodModel(id: 'f7', name: 'Boiled Egg',  imageUrl: 'https://images.pexels.com/photos/4397266/pexels-photo-4397266.jpeg', calories: 78,  type: FoodType.unit),
      FoodModel(id: 'f8', name: 'Orange Juice',imageUrl: 'https://images.pexels.com/photos/6412588/pexels-photo-6412588.jpeg', calories: 112, type: FoodType.liquid),
    ],
    lunchFoods: [
      FoodModel(id: 'f9', name: 'Tuna Salad',  imageUrl: 'https://images.pexels.com/photos/5021720/pexels-photo-5021720.jpeg', calories: 190, type: FoodType.solid),
    ],
    dinnerFoods: [
      FoodModel(id: 'f10', name: 'Greek Yogurt',imageUrl: 'https://images.pexels.com/photos/3212808/pexels-photo-3212808.jpeg', calories: 100, type: FoodType.solid),
      FoodModel(id: 'f11', name: 'Almonds',     imageUrl: 'https://images.pexels.com/photos/5254826/pexels-photo-5254826.jpeg', calories: 164, type: FoodType.unit),
    ],
    exercises: [_fakeExSquat, _fakeExLegPress],
  ),
  DayProgram(
    day: 'Wednesday',
    breakfastFoods: [
      FoodModel(id: 'f12', name: 'Banana',      imageUrl: 'https://images.pexels.com/photos/33203199/pexels-photo-33203199.jpeg', calories: 89,  type: FoodType.unit),
      FoodModel(id: 'f13', name: 'Protein Bar', imageUrl: 'https://images.pexels.com/photos/14416430/pexels-photo-14416430.jpeg', calories: 220, type: FoodType.unit),
    ],
    lunchFoods: [
      FoodModel(id: 'f14', name: 'Avocado Toast',imageUrl: 'https://images.pexels.com/photos/10743562/pexels-photo-10743562.jpeg', calories: 290, type: FoodType.solid),
    ],
    dinnerFoods: [
      FoodModel(id: 'f15', name: 'Smoothie',    imageUrl: 'https://images.pexels.com/photos/11020888/pexels-photo-11020888.jpeg', calories: 160, type: FoodType.liquid),
    ],
    exercises: [_fakeExYoga],
  ),
  DayProgram(
    day: 'Thursday',
    breakfastFoods: [
      FoodModel(id: 'f16', name: 'Oatmeal',     imageUrl: 'https://images.pexels.com/photos/704971/pexels-photo-704971.jpeg?auto=compress&cs=tinysrgb&w=200', calories: 350, type: FoodType.grains),
    ],
    lunchFoods: [
      FoodModel(id: 'f17', name: 'Chicken Wrap',imageUrl: '', calories: 380, type: FoodType.solid),
      FoodModel(id: 'f18', name: 'Green Tea',   imageUrl: '', calories: 2,   type: FoodType.liquid),
    ],
    dinnerFoods: [
      FoodModel(id: 'f19', name: 'Salmon',      imageUrl: '', calories: 208, type: FoodType.solid),
    ],
    exercises: [_fakeExPullups, _fakeExDeadlift],
  ),
  DayProgram(
    day: 'Friday',
    breakfastFoods: [
      FoodModel(id: 'f20', name: 'Boiled Egg',   imageUrl: '', calories: 78,  type: FoodType.unit),
      FoodModel(id: 'f21', name: 'Protein Shake',imageUrl: '', calories: 180, type: FoodType.liquid),
    ],
    lunchFoods: [
      FoodModel(id: 'f22', name: 'Brown Rice',   imageUrl: '', calories: 215, type: FoodType.grains),
      FoodModel(id: 'f23', name: 'Tuna',         imageUrl: '', calories: 132, type: FoodType.solid),
    ],
    dinnerFoods: [
      FoodModel(id: 'f24', name: 'Greek Yogurt', imageUrl: '', calories: 100, type: FoodType.solid),
    ],
    exercises: [_fakeExShoulderPress, _fakeExLateralRaises],
  ),
  DayProgram(
    day: 'Saturday',
    breakfastFoods: [
      FoodModel(id: 'f25', name: 'Avocado Toast',imageUrl: '', calories: 290, type: FoodType.solid),
      FoodModel(id: 'f26', name: 'Orange Juice', imageUrl: '', calories: 112, type: FoodType.liquid),
    ],
    lunchFoods: [
      FoodModel(id: 'f27', name: 'Protein Bar',  imageUrl: '', calories: 220, type: FoodType.unit),
    ],
    dinnerFoods: [
      FoodModel(id: 'f28', name: 'Smoothie',     imageUrl: '', calories: 160, type: FoodType.liquid),
      FoodModel(id: 'f29', name: 'Almonds',      imageUrl: '', calories: 164, type: FoodType.unit),
    ],
    exercises: [_fakeExHIIT],
  ),
  DayProgram(
    day: 'Sunday',
    breakfastFoods: [
      FoodModel(id: 'f30', name: 'Banana',       imageUrl: '', calories: 89, type: FoodType.unit),
    ],
    lunchFoods: [
      FoodModel(id: 'f31', name: 'Chicken Breast',imageUrl: '', calories: 165, type: FoodType.solid),
      FoodModel(id: 'f32', name: 'Brown Rice',    imageUrl: '', calories: 215, type: FoodType.grains),
    ],
    dinnerFoods: [
      FoodModel(id: 'f33', name: 'Greek Yogurt',  imageUrl: '', calories: 100, type: FoodType.solid),
    ],
    exercises: [_fakeExStretching],
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class ProgramPage extends StatefulWidget {
  const ProgramPage({super.key});

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {

  // TODO: remplacer par les vraies données depuis l'API
  final List<DayProgram> _week = fakeProgramWeek;

  late int _selectedDayIndex;

  final List<String> _daysShort = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = (DateTime.now().weekday - 1).clamp(0, 6);
  }

  DayProgram get _today => _week[_selectedDayIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: const Header(),
      bottomNavigationBar: const NavBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Text('MY PROGRAM',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 14),
          _buildDaySelector(),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCalorieSummary(),
                  const SizedBox(height: 20),
                  _buildMealSection(icon: Icons.wb_sunny_rounded,   title: 'BREAKFAST', foods: _today.breakfastFoods, color: const Color(0xFFF59E0B)),
                  const SizedBox(height: 14),
                  _buildMealSection(icon: Icons.wb_cloudy_rounded,  title: 'LUNCH',     foods: _today.lunchFoods,     color: const Color(0xFF3B82F6)),
                  const SizedBox(height: 14),
                  _buildMealSection(icon: Icons.nights_stay_rounded, title: 'DINNER',   foods: _today.dinnerFoods,    color: const Color(0xFF8B5CF6)),
                  const SizedBox(height: 20),
                  _buildSectionHeader(icon: Icons.fitness_center, title: 'EXERCISES', count: _today.exercises.length, color: kNeonGreen),
                  const SizedBox(height: 10),
                  ..._today.exercises.map((e) => _buildExerciseItem(e)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedDayIndex == index;
          final isToday = DateTime.now().weekday - 1 == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? kNeonGreen.withOpacity(0.15) : kDarkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? kNeonGreen : Colors.white10, width: isSelected ? 1.5 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_daysShort[index],
                    style: TextStyle(color: isSelected ? kNeonGreen : Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  if (isToday) ...[
                    const SizedBox(height: 4),
                    Container(width: 5, height: 5, decoration: const BoxDecoration(color: kNeonGreen, shape: BoxShape.circle)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalorieSummary() {
    final breakfast = _today.breakfastFoods.fold(0.0, (s, f) => s + f.calories);
    final lunch     = _today.lunchFoods.fold(0.0, (s, f) => s + f.calories);
    final dinner    = _today.dinnerFoods.fold(0.0, (s, f) => s + f.calories);
    final total     = breakfast + lunch + dinner;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kNeonGreen.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.05), blurRadius: 16)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: kNeonGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.local_fire_department, color: kNeonGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Calories', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  Text('${total.toInt()} kcal', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
              const Spacer(),
              Text('${_today.exercises.length} exercises', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _mealCalChip('🌅', 'Breakfast', breakfast, const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _mealCalChip('☁️', 'Lunch',     lunch,     const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _mealCalChip('🌙', 'Dinner',    dinner,    const Color(0xFF8B5CF6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mealCalChip(String emoji, String label, double cal, Color color) {
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
            Text('${cal.toInt()} kcal', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection({required IconData icon, required String title, required List<FoodModel> foods, required Color color}) {
    if (foods.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(icon: icon, title: title, count: foods.length, color: color),
        const SizedBox(height: 10),
        ...foods.map((f) => _buildFoodItem(f, color)),
      ],
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required int count, required Color color}) {
    return Row(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
          child: Text('$count', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildFoodItem(FoodModel food, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: kDarkCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: accentColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: food.imageUrl.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(food.imageUrl, fit: BoxFit.cover))
                : Icon(Icons.restaurant, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(food.calLabel, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: accentColor.withOpacity(0.2))),
            child: Text(food.typeLabel, style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(ExerciceModel exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: kDarkCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: kNeonGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: exercise.image.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(exercise.image, fit: BoxFit.cover))
                : const Icon(Icons.fitness_center, color: kNeonGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(exercise.description, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: kNeonGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: kNeonGreen.withOpacity(0.2))),
            child: Text(exercise.typeLabel, style: const TextStyle(color: kNeonGreen, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}