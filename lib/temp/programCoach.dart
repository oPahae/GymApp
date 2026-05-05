import 'package:flutter/material.dart';
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/models/food.dart';
import 'package:test_hh/models/exercice.dart';
import 'package:test_hh/models/dayProgram.dart';
import 'package:test_hh/screens/foods.dart';       // → kAllFoods
import 'package:test_hh/screens/bodyparts.dart';   // → kBodyParts

final List<FoodModel> kAllFoods = [
  const FoodModel(
    id: '1',
    name: 'Oatmeal',
    imageUrl:
        'https://images.pexels.com/photos/704971/pexels-photo-704971.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 389,
    type: FoodType.solid,
  ),
  const FoodModel(
    id: '2',
    name: 'Almond Milk',
    imageUrl:
        'https://images.pexels.com/photos/3735218/pexels-photo-3735218.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 17,
    type: FoodType.liquid,
  ),
  const FoodModel(
    id: '3',
    name: 'Chicken Breast',
    imageUrl:
        'https://images.pexels.com/photos/2338407/pexels-photo-2338407.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 165,
    type: FoodType.solid,
  ),
  const FoodModel(
    id: '4',
    name: 'Whey Protein',
    imageUrl:
        'https://images.pexels.com/photos/4162493/pexels-photo-4162493.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 400,
    type: FoodType.grains,
  ),
  const FoodModel(
    id: '5',
    name: 'Banana',
    imageUrl:
        'https://images.pexels.com/photos/1093038/pexels-photo-1093038.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 89,
    type: FoodType.unit,
  ),
  const FoodModel(
    id: '6',
    name: 'Greek Yogurt',
    imageUrl:
        'https://images.pexels.com/photos/1132047/pexels-photo-1132047.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 59,
    type: FoodType.solid,
  ),
  const FoodModel(
    id: '7',
    name: 'Orange Juice',
    imageUrl:
        'https://images.pexels.com/photos/158053/fresh-orange-juice-squeezed-158053.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 45,
    type: FoodType.liquid,
  ),
  const FoodModel(
    id: '8',
    name: 'Quinoa',
    imageUrl:
        'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 120,
    type: FoodType.solid,
  ),
  const FoodModel(
    id: '9',
    name: 'Salmon',
    imageUrl:
        'https://images.pexels.com/photos/3763847/pexels-photo-3763847.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 208,
    type: FoodType.solid,
  ),
  const FoodModel(
    id: '10',
    name: 'Vitamin D3',
    imageUrl:
        'https://images.pexels.com/photos/4162493/pexels-photo-4162493.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 0,
    type: FoodType.grains,
  ),
  const FoodModel(
    id: '11',
    name: 'Egg',
    imageUrl:
        'https://images.pexels.com/photos/824635/pexels-photo-824635.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 78,
    type: FoodType.unit,
  ),
  const FoodModel(
    id: '12',
    name: 'Green Tea',
    imageUrl:
        'https://images.pexels.com/photos/1417945/pexels-photo-1417945.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 2,
    type: FoodType.liquid,
  ),
];

// ─── Meal type enum ───────────────────────────────────────────────────────────

enum _Meal { breakfast, lunch, dinner }

// ─── Page ─────────────────────────────────────────────────────────────────────

class ProgramCoachScreen extends StatefulWidget {
  ProgramCoachScreen({ super.key });

  final String clientName = "";
  final String clientId = "";
  final String? clientAvatarUrl = "";

  @override
  State<ProgramCoachScreen> createState() => _ProgramCoachScreenState();
}

class _ProgramCoachScreenState extends State<ProgramCoachScreen> {
  // ── Constants ────────────────────────────────────────────────────────────
  static const _daysShort = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  // ── State ─────────────────────────────────────────────────────────────────
  int _selectedDay = 0;
  bool _isSaving   = false;

  // weekProgram[dayIndex] = { 'breakfast': [...], 'lunch': [...], 'dinner': [...], 'exercises': [...] }
  late final List<Map<String, List<dynamic>>> _week;

  // Single source of truth — from mock data, replaced by API later
  late final List<FoodModel>     _allFoods;
  late final List<ExerciceModel> _allExercises;

  // ── Init ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _week = List.generate(7, (_) => {
      'breakfast': <FoodModel>[],
      'lunch':     <FoodModel>[],
      'dinner':    <FoodModel>[],
      'exercises': <ExerciceModel>[],
    });
    _allFoods     = kAllFoods;
    _allExercises = [].expand<ExerciceModel>((bp) => bp.exercices).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<FoodModel>     _foods(int day, _Meal m) => _week[day][m.name]! as List<FoodModel>;
  List<ExerciceModel> _exes(int day)           => _week[day]['exercises']! as List<ExerciceModel>;

  bool _dayHasContent(int day) =>
      _foods(day, _Meal.breakfast).isNotEmpty ||
      _foods(day, _Meal.lunch).isNotEmpty     ||
      _foods(day, _Meal.dinner).isNotEmpty    ||
      _exes(day).isNotEmpty;

  int get _filledDays => List.generate(7, (i) => i).where(_dayHasContent).length;

  Color _mealColor(_Meal m) => m == _Meal.breakfast
      ? const Color(0xFFF59E0B)
      : m == _Meal.lunch
          ? const Color(0xFF3B82F6)
          : const Color(0xFF8B5CF6);

  IconData _mealIcon(_Meal m) => m == _Meal.breakfast
      ? Icons.wb_sunny_rounded
      : m == _Meal.lunch
          ? Icons.wb_cloudy_rounded
          : Icons.nights_stay_rounded;

  String _mealLabel(_Meal m) =>
      m == _Meal.breakfast ? 'BREAKFAST' : m == _Meal.lunch ? 'LUNCH' : 'DINNER';

  Color _exTypeColor(ExerciceType t) {
    switch (t) {
      case ExerciceType.cardio:      return const Color(0xFF3B82F6);
      case ExerciceType.flexibility: return const Color(0xFF8B5CF6);
      default:                       return const Color(0xFFEF4444);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    setState(() => _isSaving = true);
    // TODO: POST /programs  { clientId: widget.clientId, week: _week }
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kNeonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
          const SizedBox(width: 8),
          Text('Program saved for ${widget.clientName}!',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  // ─── Bottom sheet: food picker ────────────────────────────────────────────
  void _openFoodPicker(_Meal meal) {
    final added = _foods(_selectedDay, meal).map((f) => f.id).toSet();
    String q = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        final list = _allFoods
            .where((f) =>
                !added.contains(f.id) &&
                f.name.toLowerCase().contains(q.toLowerCase()))
            .toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF16161E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: _mealColor(meal).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_mealIcon(meal), color: _mealColor(meal), size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'Add to ${_mealLabel(meal)[0]}${_mealLabel(meal).substring(1).toLowerCase()}',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ]),
            ),
            // Search bar — same style as foods.dart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: kDarkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (v) => setS(() => q = v),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.3), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // List
            Expanded(
              child: list.isEmpty
                  ? _buildSheetEmpty('No food found')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _FoodPickerTile(
                        food: list[i],
                        accentColor: _mealColor(meal),
                        onAdd: () {
                          setState(() => _foods(_selectedDay, meal).add(list[i]));
                          added.add(list[i].id);
                          setS(() {});
                        },
                      ),
                    ),
            ),
          ]),
        );
      }),
    );
  }

  // ─── Bottom sheet: exercise picker ────────────────────────────────────────
  void _openExercisePicker() {
    final added = _exes(_selectedDay).map((e) => e.id).toSet();
    String q = '';
    ExerciceType? filterType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        final list = _allExercises.where((e) {
          final matchQ    = e.name.toLowerCase().contains(q.toLowerCase());
          final matchType = filterType == null || e.type == filterType;
          return !added.contains(e.id) && matchQ && matchType;
        }).toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.80,
          decoration: const BoxDecoration(
            color: Color(0xFF16161E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: kNeonGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.fitness_center, color: kNeonGreen, size: 18),
                ),
                const SizedBox(width: 12),
                const Text('Add Exercise',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kNeonGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kNeonGreen.withOpacity(0.3)),
                  ),
                  child: Text('${list.length}',
                      style: const TextStyle(color: kNeonGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: kDarkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (v) => setS(() => q = v),
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.3), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Filter chips — same style as other filter rows
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                _SheetFilterChip(label: 'ALL',         isSelected: filterType == null,                       color: Colors.white54,          onTap: () => setS(() => filterType = null)),
                const SizedBox(width: 8),
                _SheetFilterChip(label: 'STRENGTH',    isSelected: filterType == ExerciceType.strength,      color: const Color(0xFFEF4444), onTap: () => setS(() => filterType = filterType == ExerciceType.strength    ? null : ExerciceType.strength)),
                const SizedBox(width: 8),
                _SheetFilterChip(label: 'CARDIO',      isSelected: filterType == ExerciceType.cardio,        color: const Color(0xFF3B82F6), onTap: () => setS(() => filterType = filterType == ExerciceType.cardio      ? null : ExerciceType.cardio)),
                const SizedBox(width: 8),
                _SheetFilterChip(label: 'FLEXIBILITY', isSelected: filterType == ExerciceType.flexibility,   color: const Color(0xFF8B5CF6), onTap: () => setS(() => filterType = filterType == ExerciceType.flexibility ? null : ExerciceType.flexibility)),
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: list.isEmpty
                  ? _buildSheetEmpty('No exercise found')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _ExercisePickerTile(
                        exercise: list[i],
                        typeColor: _exTypeColor(list[i].type),
                        onAdd: () {
                          setState(() => _exes(_selectedDay).add(list[i]));
                          added.add(list[i].id);
                          setS(() {});
                        },
                      ),
                    ),
            ),
          ]),
        );
      }),
    );
  }

  Widget _buildSheetEmpty(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 60),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off, color: Colors.white.withOpacity(0.12), size: 48),
        const SizedBox(height: 10),
        Text(msg, style: TextStyle(color: Colors.white.withOpacity(0.28), fontSize: 13,
            fontWeight: FontWeight.w500)),
      ]),
    ),
  );

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: const Header(),
      bottomNavigationBar: const NavBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _save,
        backgroundColor: kNeonGreen,
        foregroundColor: Colors.black,
        icon: _isSaving
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : const Icon(Icons.save_rounded),
        label: Text(
          _isSaving ? 'Saving...' : 'Save Program',
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.4),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            const SizedBox(height: 14),
            _buildDaySelector(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalorieSummary(),
                    const SizedBox(height: 20),
                    _buildMealSection(_Meal.breakfast),
                    const SizedBox(height: 14),
                    _buildMealSection(_Meal.lunch),
                    const SizedBox(height: 14),
                    _buildMealSection(_Meal.dinner),
                    const SizedBox(height: 20),
                    _buildExercisesSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top bar — same structure as bodyparts.dart / exercices.dart ──────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () { if (Navigator.canPop(context)) Navigator.pop(context); },
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: kDarkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('BUILD PROGRAM',
                style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w800, letterSpacing: 2)),
            Row(children: [
              const Icon(Icons.person_rounded, color: kNeonGreen, size: 13),
              const SizedBox(width: 4),
              Text(widget.clientName,
                  style: TextStyle(color: Colors.white.withOpacity(0.45),
                      fontSize: 11, fontWeight: FontWeight.w500)),
            ]),
          ]),
        ),
        // Days filled badge — same style as kBodyParts badge in bodyparts.dart
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kNeonGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kNeonGreen.withOpacity(0.3)),
          ),
          child: Text(
            '$_filledDays/7 DAYS',
            style: const TextStyle(color: kNeonGreen, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 0.6),
          ),
        ),
      ]),
    );
  }

  // ─── Day selector ─────────────────────────────────────────────────────────
  Widget _buildDaySelector() {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSel      = _selectedDay == i;
          final hasContent = _dayHasContent(i);
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              decoration: BoxDecoration(
                color: isSel ? kNeonGreen.withOpacity(0.15) : kDarkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSel ? kNeonGreen : Colors.white10,
                  width: isSel ? 1.5 : 1,
                ),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_daysShort[i],
                    style: TextStyle(
                      color: isSel ? kNeonGreen : Colors.white38,
                      fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                    )),
                const SizedBox(height: 4),
                Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    color: hasContent
                        ? (isSel ? kNeonGreen : kNeonGreen.withOpacity(0.45))
                        : Colors.white12,
                    shape: BoxShape.circle,
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ─── Calorie summary ──────────────────────────────────────────────────────
  Widget _buildCalorieSummary() {
    final bf      = _foods(_selectedDay, _Meal.breakfast).fold(0.0, (s, f) => s + f.calories);
    final lu      = _foods(_selectedDay, _Meal.lunch).fold(0.0, (s, f) => s + f.calories);
    final di      = _foods(_selectedDay, _Meal.dinner).fold(0.0, (s, f) => s + f.calories);
    final total   = bf + lu + di;
    final exCount = _exes(_selectedDay).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kNeonGreen.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.05), blurRadius: 16)],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: kNeonGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.local_fire_department, color: kNeonGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Total Calories',
                style: TextStyle(color: Colors.white38, fontSize: 11,
                    fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            Text('${total.toInt()} kcal',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          ]),
          const Spacer(),
          Text('$exCount exercise${exCount != 1 ? 's' : ''}',
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _calChip('🌅', bf, const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          _calChip('☁️', lu, const Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          _calChip('🌙', di, const Color(0xFF8B5CF6)),
        ]),
      ]),
    );
  }

  Widget _calChip(String emoji, double cal, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        Text('${cal.toInt()} kcal',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    ),
  );

  // ─── Meal section ─────────────────────────────────────────────────────────
  Widget _buildMealSection(_Meal meal) {
    final foods = _foods(_selectedDay, meal);
    final color = _mealColor(meal);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Section header
      Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(_mealIcon(meal), color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(_mealLabel(meal),
            style: const TextStyle(color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text('${foods.length}',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _openFoodPicker(meal),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, color: color, size: 14),
              const SizedBox(width: 4),
              Text('Add', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      if (foods.isEmpty)
        _buildEmptySlot(color)
      else
        ...foods.asMap().entries.map((e) => _buildFoodCard(e.value, color, meal, e.key)),
    ]);
  }

  Widget _buildEmptySlot(Color color) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.04),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.12)),
    ),
    child: Center(
      child: Text('No food added yet',
          style: TextStyle(color: color.withOpacity(0.35), fontSize: 12)),
    ),
  );

  // ─── Food card — same card style as foods.dart ────────────────────────────
  Widget _buildFoodCard(FoodModel food, Color accent, _Meal meal, int idx) {
    return Dismissible(
      key: Key('food_${meal.name}_${food.id}_$idx'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => setState(() => _foods(_selectedDay, meal).removeAt(idx)),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: kDarkCard, borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: Row(children: [
          // Thumbnail + right gradient — exactly like foods.dart _buildFoodCard
          SizedBox(
            width: 80, height: 80,
            child: Stack(fit: StackFit.expand, children: [
              food.imageUrl.isNotEmpty
                  ? Image.network(food.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1A1A1A),
                        child: const Icon(Icons.fastfood, color: Colors.white24, size: 24),
                      ))
                  : Container(
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.fastfood, color: Colors.white24, size: 24),
                    ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, kDarkCard.withOpacity(0.65)],
                  ),
                ),
              ),
            ]),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _typeChip(food.typeLabel, accent),
                const SizedBox(height: 5),
                Text(food.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(food.calLabel,
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
          // Remove
          GestureDetector(
            onTap: () => setState(() => _foods(_selectedDay, meal).removeAt(idx)),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(Icons.close_rounded, color: Colors.white24, size: 18),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Exercises section ────────────────────────────────────────────────────
  Widget _buildExercisesSection() {
    final exes = _exes(_selectedDay);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: kNeonGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.fitness_center, color: kNeonGreen, size: 16),
        ),
        const SizedBox(width: 10),
        const Text('EXERCISES',
            style: TextStyle(color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: kNeonGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kNeonGreen.withOpacity(0.3)),
          ),
          child: Text('${exes.length}',
              style: const TextStyle(color: kNeonGreen, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _openExercisePicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kNeonGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kNeonGreen.withOpacity(0.3)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, color: kNeonGreen, size: 14),
              SizedBox(width: 4),
              Text('Add', style: TextStyle(color: kNeonGreen, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      if (exes.isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: kNeonGreen.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kNeonGreen.withOpacity(0.12)),
          ),
          child: Center(
            child: Text('No exercise added yet',
                style: TextStyle(color: kNeonGreen.withOpacity(0.35), fontSize: 12)),
          ),
        )
      else
        ...exes.asMap().entries.map((e) => _buildExerciseCard(e.value, e.key)),
    ]);
  }

  // ─── Exercise card — same card style as exercices.dart ───────────────────
  Widget _buildExerciseCard(ExerciceModel ex, int idx) {
    final typeColor = _exTypeColor(ex.type);
    return Dismissible(
      key: Key('ex_${ex.id}_$idx'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => setState(() => _exes(_selectedDay).removeAt(idx)),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          height: 90,
          child: Stack(fit: StackFit.expand, children: [
            // Background image — same as exercices.dart
            ex.image.isNotEmpty
                ? Image.network(ex.image, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.fitness_center, color: Colors.white12, size: 28),
                    ))
                : Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Icon(Icons.fitness_center, color: Colors.white12, size: 28),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.transparent, kDarkCard.withOpacity(0.96)],
                  stops: const [0.25, 0.7],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                const SizedBox(width: 70),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _typeChip(ex.typeLabel, typeColor),
                      const SizedBox(height: 5),
                      Text(ex.name,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                        '${ex.description}  ·  ${ex.part.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _exes(_selectedDay).removeAt(idx)),
                  child: const Icon(Icons.close_rounded, color: Colors.white24, size: 20),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Shared type chip — same as _buildTypeChip in all pages ──────────────
  Widget _typeChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.22), width: 1),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
  );
}

// ─── Food Picker Tile ─────────────────────────────────────────────────────────

class _FoodPickerTile extends StatefulWidget {
  final FoodModel    food;
  final Color        accentColor;
  final VoidCallback onAdd;
  const _FoodPickerTile({required this.food, required this.accentColor, required this.onAdd});

  @override
  State<_FoodPickerTile> createState() => _FoodPickerTileState();
}

class _FoodPickerTileState extends State<_FoodPickerTile> {
  bool _added = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _added ? widget.accentColor.withOpacity(0.07) : kDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _added ? widget.accentColor.withOpacity(0.3) : Colors.white10),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(children: [
        // Thumbnail — same as foods.dart
        SizedBox(
          width: 64, height: 64,
          child: Stack(fit: StackFit.expand, children: [
            widget.food.imageUrl.isNotEmpty
                ? Image.network(widget.food.imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.fastfood, color: Colors.white24, size: 22),
                    ))
                : Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Icon(Icons.fastfood, color: Colors.white24, size: 22),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.transparent, kDarkCard.withOpacity(0.65)],
                ),
              ),
            ),
          ]),
        ),
        // Info
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.food.name,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(widget.food.calLabel,
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
        // Add button
        GestureDetector(
          onTap: _added ? null : () { setState(() => _added = true); widget.onAdd(); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 14),
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _added
                  ? widget.accentColor.withOpacity(0.2)
                  : widget.accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _added ? Icons.check_rounded : Icons.add_rounded,
              color: widget.accentColor, size: 18,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Exercise Picker Tile ─────────────────────────────────────────────────────

class _ExercisePickerTile extends StatefulWidget {
  final ExerciceModel exercise;
  final Color         typeColor;
  final VoidCallback  onAdd;
  const _ExercisePickerTile({required this.exercise, required this.typeColor, required this.onAdd});

  @override
  State<_ExercisePickerTile> createState() => _ExercisePickerTileState();
}

class _ExercisePickerTileState extends State<_ExercisePickerTile> {
  bool _added = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _added ? kNeonGreen.withOpacity(0.06) : kDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _added ? kNeonGreen.withOpacity(0.3) : Colors.white.withOpacity(0.05),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      // Same card structure as exercices.dart _buildExerciceCard
      child: SizedBox(
        height: 80,
        child: Stack(fit: StackFit.expand, children: [
          widget.exercise.image.isNotEmpty
              ? Image.network(widget.exercise.image, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Icon(Icons.fitness_center, color: Colors.white12, size: 26),
                  ))
              : Container(
                  color: const Color(0xFF1A1A1A),
                  child: const Icon(Icons.fitness_center, color: Colors.white12, size: 26),
                ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, kDarkCard.withOpacity(0.97)],
                stops: const [0.2, 0.65],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              const SizedBox(width: 55),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: widget.typeColor.withOpacity(0.22), width: 1),
                      ),
                      child: Text(widget.exercise.typeLabel,
                          style: TextStyle(color: widget.typeColor, fontSize: 9,
                              fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                    ),
                    const SizedBox(height: 5),
                    Text(widget.exercise.name,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(widget.exercise.part.name,
                        style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 11)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _added ? null : () { setState(() => _added = true); widget.onAdd(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _added ? kNeonGreen.withOpacity(0.2) : kNeonGreen.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _added ? Icons.check_rounded : Icons.add_rounded,
                    color: kNeonGreen, size: 18,
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Sheet Filter Chip ────────────────────────────────────────────────────────

class _SheetFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _SheetFilterChip({required this.label, required this.isSelected,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : kDarkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : Colors.white10,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? color : Colors.white38,
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6,
            )),
      ),
    );
  }
}