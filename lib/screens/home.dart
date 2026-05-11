import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/screens/addFood.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/constants/urls.dart';
import 'package:test_hh/session/user_session.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _ActivityItem {
  final int id;
  final String name;
  final int calories;

  _ActivityItem({required this.id, required this.name, required this.calories});

  factory _ActivityItem.fromJson(Map<String, dynamic> json) => _ActivityItem(
        id: json['id'],
        name: json['name'],
        calories: json['calories'],
      );
}

class _MealItem {
  final String imageUrl;
  final String name;
  final String portion;
  final int calories;

  const _MealItem({
    required this.imageUrl,
    required this.name,
    required this.portion,
    required this.calories,
  });
}

class _MealGroup {
  final String mealtime;
  final int totalKcal;
  final List<_MealItem> items;

  _MealGroup(
      {required this.mealtime,
      required this.totalKcal,
      required this.items});
}



class _Summary {
  final int calorieGoal;
  final int baseBurned;
  final int activityCalories;
  final int totalBurned;
  final int totalConsumed;
  final int remaining;

  const _Summary({
    required this.calorieGoal,
    required this.baseBurned,
    required this.activityCalories,
    required this.totalBurned,
    required this.totalConsumed,
    required this.remaining,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Session ──────────────────────────────────────────────────────────────
  bool _sessionLoading = true;
  int  _clientID       = 0;       // rempli depuis UserSession

  // ── State ────────────────────────────────────────────────────────────────
  bool _loadingSummary    = true;
  bool _loadingMeals      = true;
  bool _loadingActivities = true;
  String? _summaryError;
  String? _mealsError;
  String? _activitiesError;

  _Summary?                _summary;
  Map<String, _MealGroup>  _meals      = {};
  List<_ActivityItem>      _activities = [];

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initSession();
  }

  /// Charge d'abord la session user, puis les données de la page.
  Future<void> _initSession() async {
    // Si le user est déjà chargé (ex: session existante), on saute le fetch
    if (!UserSession.instance.isLoaded) {
      await UserSession.instance.load();
    }

    if (!mounted) return;
    setState(() {
      _clientID      = UserSession.instance.id;
      _sessionLoading = false;
    });

    _loadAll();
  }

  Future<void> _loadAll() async {
    if (_clientID == 0) return; // pas encore de session valide
    await Future.wait([
      _fetchSummary(),
      _fetchMeals(),
      _fetchActivities(),
    ]);
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _fetchSummary() async {
    setState(() {
      _loadingSummary = true;
      _summaryError   = null;
    });
    try {
      final uri  = Uri.parse('$kBaseUrl/api/pahae/home/summary/$_clientID');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 200 && body['success'] == true) {
        final d = body['data'];
        setState(() {
          _summary = _Summary(
            calorieGoal:      d['calorieGoal'],
            baseBurned:       d['baseBurned'],
            activityCalories: d['activityCalories'],
            totalBurned:      d['totalBurned'],
            totalConsumed:    d['totalConsumed'],
            remaining:        d['remaining'],
          );
        });
      } else {
        setState(() {
          _summaryError = body['message'] ?? 'Unknown error';
        });
      }
    } catch (e) {
      setState(() {
        _summaryError = 'Connection failed';
      });
    } finally {
      setState(() {
        _loadingSummary = false;
      });
    }
  }

  Future<void> _fetchMeals() async {
    setState(() {
      _loadingMeals = true;
      _mealsError   = null;
    });
    try {
      final uri  = Uri.parse('$kBaseUrl/api/pahae/home/meals/$_clientID');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 200 && body['success'] == true) {
        final Map<String, dynamic> raw = body['data'];
        final Map<String, _MealGroup> parsed = {};
        raw.forEach((mealtime, group) {
          final items = (group['items'] as List).map((item) {
            return _MealItem(
              imageUrl: item['image'] ?? '',
              name:     item['name']  ?? '',
              portion:  item['quantity'] != null
                  ? '${item['quantity']} serving(s)'
                  : '',
              calories: item['totalCalories'] ?? 0,
            );
          }).toList();
          parsed[mealtime] = _MealGroup(
            mealtime:  mealtime,
            totalKcal: group['totalKcal'] ?? 0,
            items:     items,
          );
        });
        setState(() {
          _meals = parsed;
        });
      } else {
        setState(() {
          _mealsError = body['message'] ?? 'Unknown error';
        });
      }
    } catch (e) {
      setState(() {
        _mealsError = 'Connection failed';
      });
    } finally {
      setState(() {
        _loadingMeals = false;
      });
    }
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _loadingActivities = true;
      _activitiesError   = null;
    });
    try {
      final uri  = Uri.parse('$kBaseUrl/api/pahae/home/activities/$_clientID');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 200 && body['success'] == true) {
        final List data = body['data'];
        setState(() {
          _activities =
              data.map((a) => _ActivityItem.fromJson(a)).toList();
        });
      } else {
        setState(() {
          _activitiesError = body['message'] ?? 'Unknown error';
        });
      }
    } catch (e) {
      setState(() {
        _activitiesError = 'Connection failed';
      });
    } finally {
      setState(() {
        _loadingActivities = false;
      });
    }
  }

  Future<void> _addActivity(String name, int calories) async {
    try {
      final uri  = Uri.parse('$kBaseUrl/api/pahae/home/activities/$_clientID');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body:    jsonEncode({'name': name, 'calories': calories}),
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 201 && body['success'] == true) {
        final d = body['data'];
        setState(() {
          _activities.add(_ActivityItem(
              id: d['id'], name: d['name'], calories: d['calories']));
        });
        _fetchSummary();
      } else {
        _showError(body['message'] ?? 'Failed to add activity');
      }
    } catch (e) {
      _showError('Connection failed');
    }
  }

  Future<void> _deleteActivity(int activityID, int index) async {
    final removed = _activities[index];
    setState(() {
      _activities.removeAt(index);
    });
    try {
      final uri = Uri.parse(
          '$kBaseUrl/api/pahae/home/activities/$_clientID/$activityID');
      final resp =
          await http.delete(uri).timeout(const Duration(seconds: 10));
      final body = jsonDecode(resp.body);
      if (resp.statusCode != 200 || body['success'] != true) {
        setState(() {
          _activities.insert(index, removed);
        });
        _showError(body['message'] ?? 'Failed to delete activity');
      } else {
        _fetchSummary();
      }
    } catch (e) {
      setState(() {
        _activities.insert(index, removed);
      });
      _showError('Connection failed');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:         Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade800,
        behavior:        SnackBarBehavior.floating,
      ),
    );
  }

  // ── Greeting with user name ──────────────────────────────────────────────
  String get _greeting {
    final hour = DateTime.now().hour;
    final name = UserSession.instance.name.isNotEmpty
        ? UserSession.instance.name.split(' ').first
        : '';
    final salut = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    return name.isNotEmpty ? '$salut, $name 👋' : salut;
  }

  // ── Add Activity Dialog ──────────────────────────────────────────────────
  void _showAddActivityDialog() {
    final nameController     = TextEditingController();
    final caloriesController = TextEditingController();
    bool submitting          = false;

    showModalBottomSheet(
      context:          context,
      isScrollControlled: true,
      backgroundColor:  Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx2).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color:         const Color(0xFF1A1A1A),
              borderRadius:  const BorderRadius.vertical(
                  top: Radius.circular(24)),
              border: Border.all(
                  color: kNeonGreen.withOpacity(0.2), width: 1),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize:     MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color:         kNeonGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_run,
                          color: kNeonGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Add Activity',
                        style: TextStyle(
                            color:      Colors.white,
                            fontSize:   18,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller:  nameController,
                  label:       'Activity name',
                  hint:        'e.g. Running, Cycling...',
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 14),
                _buildInputField(
                  controller:  caloriesController,
                  label:       'Calories burned',
                  hint:        'e.g. 300',
                  keyboardType: TextInputType.number,
                  suffix:      'kcal',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: submitting
                        ? null
                        : () async {
                            final name =
                                nameController.text.trim();
                            final cal = int.tryParse(
                                caloriesController.text.trim());
                            if (name.isEmpty ||
                                cal == null ||
                                cal <= 0) return;
                            setSheetState(
                                () => submitting = true);
                            Navigator.pop(ctx2);
                            await _addActivity(name, cal);
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      decoration: BoxDecoration(
                        color: submitting
                            ? kNeonGreen.withOpacity(0.5)
                            : kNeonGreen,
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: submitting
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(
                                        Colors.black),
                              ),
                            )
                          : const Text('Add Activity',
                              style: TextStyle(
                                  color:      Colors.black,
                                  fontSize:   15,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              color:       Colors.white.withOpacity(0.6),
              fontSize:    12,
              fontWeight:  FontWeight.w600,
              letterSpacing: 0.5,
            )),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color:  Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.white.withOpacity(0.12), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller:  controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText:  hint,
                    hintStyle: TextStyle(
                        color:    Colors.white.withOpacity(0.3),
                        fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Text(suffix,
                      style: TextStyle(
                        color:      kNeonGreen.withOpacity(0.7),
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                      )),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Pendant que la session se charge, on affiche un loader global
    if (_sessionLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(kNeonGreen),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const Header(),
      body: RefreshIndicator(
        color:           kNeonGreen,
        backgroundColor: const Color(0xFF1A1A1A),
        onRefresh:       _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Greeting ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    // Infos complémentaires du profil
                    if (UserSession.instance.goal.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Goal: ${UserSession.instance.goal}',
                          style: TextStyle(
                            color:    kNeonGreen.withOpacity(0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildCaloriesCard(),
              const SizedBox(height: 14),
              _buildStatusMessage(),
              const SizedBox(height: 22),
              _buildMealsSection(),
              const SizedBox(height: 20),
              _buildActivitiesSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavBar(selectedIndex: 0),
    );
  }

  // ── Calories card ─────────────────────────────────────────────────────────
  Widget _buildCaloriesCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        decoration: BoxDecoration(
          color:         kDarkCard,
          borderRadius:  BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color:      kNeonGreen.withOpacity(0.08),
                blurRadius: 30,
                spreadRadius: 2),
          ],
          gradient: LinearGradient(
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF111111),
              kNeonGreen.withOpacity(0.03),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30, left: -30,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kNeonGreen.withOpacity(0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _loadingSummary
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(kNeonGreen),
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : _summaryError != null
                      ? _buildErrorRow(_summaryError!, _fetchSummary)
                      : Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.center,
                          children: [
                            _buildCircularProgress(),
                            const SizedBox(width: 24),
                            Expanded(child: _buildStats()),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorRow(String msg, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12)),
          ),
          GestureDetector(
            onTap: onRetry,
            child: const Text('Retry',
                style: TextStyle(
                    color:      kNeonGreen,
                    fontSize:   12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgress() {
    final consumed = _summary?.totalConsumed ?? 0;
    final goal     = _summary?.calorieGoal   ?? 2300;
    final progress = (consumed / goal).clamp(0.0, 1.0);
    final progressLabel =
        '${(progress * 100).toStringAsFixed(0)}%';

    return Column(
      children: [
        SizedBox(
          width: 150, height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(150, 150),
                painter: _CircularProgressPainter(
                    progress: progress),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department,
                      color: kNeonGreen, size: 22),
                  const SizedBox(height: 2),
                  Text(
                    _formatKcal(consumed),
                    style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '/ ${_formatKcal(goal)} kcal',
                    style: TextStyle(
                        color:    Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color:         kNeonGreen.withOpacity(0.15),
            borderRadius:  BorderRadius.circular(20),
            border: Border.all(
                color: kNeonGreen.withOpacity(0.4), width: 1),
          ),
          child: Text(progressLabel,
              style: const TextStyle(
                  color:      kNeonGreen,
                  fontSize:   13,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildStats() {
    final s = _summary;
    if (s == null) return const SizedBox.shrink();

    final burnedProgress    = (s.totalBurned   / 3000).clamp(0.0, 1.0);
    final consumedProgress  = (s.totalConsumed  / s.calorieGoal).clamp(0.0, 1.0);
    final remainingProgress = (s.remaining      / s.calorieGoal).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatItem(
          icon:     Icons.local_fire_department,
          label:    'BURNED',
          value:    '${_formatKcal(s.totalBurned)} kcal',
          progress: burnedProgress,
          subtitle:
              '+${_formatKcal(s.activityCalories)} activity · ${_formatKcal(s.baseBurned)} base',
        ),
        const SizedBox(height: 16),
        _buildStatItem(
          icon:     Icons.restaurant,
          label:    'CONSUMED',
          value:    '${_formatKcal(s.totalConsumed)} kcal',
          progress: consumedProgress,
        ),
        const SizedBox(height: 16),
        _buildStatItem(
          icon:     Icons.balance,
          label:    'REMAINING',
          value:    '${_formatKcal(s.remaining)} kcal',
          progress: remainingProgress,
        ),
      ],
    );
  }

  String _formatKcal(int value) {
    if (value >= 1000) {
      return '${value ~/ 1000},${(value % 1000).toString().padLeft(3, '0')}';
    }
    return value.toString();
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required double progress,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color:        kNeonGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: kNeonGreen, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    color:       Colors.white.withOpacity(0.45),
                    fontSize:    10,
                    fontWeight:  FontWeight.w600,
                    letterSpacing: 1,
                  )),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   13,
                      fontWeight: FontWeight.w700)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color:      kNeonGreen.withOpacity(0.7),
                        fontSize:   9,
                        fontWeight: FontWeight.w500)),
              ],
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:           progress,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      kNeonGreen),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Status message ────────────────────────────────────────────────────────
  Widget _buildStatusMessage() {
    final s        = _summary;
    final inDeficit = s != null && s.totalConsumed < s.totalBurned;
    final msg = s == null
        ? 'Loading calorie status...'
        : inDeficit
            ? "You're in a calorie deficit"
            : "You've reached your calorie goal";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:         kDarkCard,
          borderRadius:  BorderRadius.circular(16),
          border: Border.all(
              color: kNeonGreen.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
                color: kNeonGreen.withOpacity(0.06),
                blurRadius: 16),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color:        kNeonGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt,
                  color: kNeonGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   14,
                      fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.4), size: 14),
          ],
        ),
      ),
    );
  }

  // ── Meals section ──────────────────────────────────────────────────────────
  Widget _buildMealsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TODAY'S MEALS",
            style: TextStyle(
                color:       Colors.white,
                fontSize:    15,
                fontWeight:  FontWeight.w800,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          if (_loadingMeals)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(kNeonGreen),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_mealsError != null)
            _buildSectionError(_mealsError!, _fetchMeals)
          else ...[
            _buildMealCardFromGroup('BREAKFAST', 'breakfast',
                'https://images.pexels.com/photos/376464/pexels-photo-376464.jpeg?auto=compress&cs=tinysrgb&w=800&h=200&dpr=1'),
            const SizedBox(height: 14),
            _buildMealCardFromGroup('LUNCH', 'lunch',
                'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=800&h=200&dpr=1'),
            const SizedBox(height: 14),
            _buildMealCardFromGroup('DINNER', 'dinner',
                'https://images.pexels.com/photos/3763847/pexels-photo-3763847.jpeg?auto=compress&cs=tinysrgb&w=800&h=200&dpr=1'),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionError(String msg, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:         kDarkCard,
        borderRadius:  BorderRadius.circular(16),
        border: Border.all(
            color: Colors.red.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13))),
          GestureDetector(
            onTap: onRetry,
            child: const Text('Retry',
                style: TextStyle(
                    color:      kNeonGreen,
                    fontSize:   13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCardFromGroup(
      String label, String mealtime, String headerImage) {
    final group     = _meals[mealtime];
    final items     = group?.items    ?? [];
    final totalKcal = group?.totalKcal ?? 0;

    return _buildMealCard(
      mealType:       label,
      mealtime:       mealtime,
      totalKcal:      '$totalKcal kcal',
      headerImageUrl: headerImage,
      items:          items,
    );
  }

  Widget _buildMealCard({
    required String mealType,
    required String mealtime,
    required String totalKcal,
    required String headerImageUrl,
    required List<_MealItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:        kDarkCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset:     const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    headerImageUrl,
                    fit:          BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF1A1A1A)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:  Alignment.topCenter,
                        end:    Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.black.withOpacity(0.75),
                          Colors.black,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(mealType,
                            style: const TextStyle(
                              color:       Colors.white,
                              fontSize:    14,
                              fontWeight:  FontWeight.w700,
                              letterSpacing: 1,
                              shadows: [
                                Shadow(
                                    color:      Colors.black87,
                                    blurRadius: 8)
                              ],
                            )),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:        Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: kNeonGreen.withOpacity(0.55),
                                width: 1),
                          ),
                          child: Text(totalKcal,
                              style: const TextStyle(
                                  color:      kNeonGreen,
                                  fontSize:   12,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.keyboard_arrow_down,
                            color: Colors.white.withOpacity(0.6),
                            size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 14),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.white.withOpacity(0.3), size: 16),
                  const SizedBox(width: 8),
                  Text('No food logged yet',
                      style: TextStyle(
                          color:    Colors.white.withOpacity(0.35),
                          fontSize: 12)),
                ],
              ),
            )
          else
            ...items.map((item) => _buildFoodItem(item)),
          const Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.all(14),
            child: _buildAddFoodButton(mealtime),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(_MealItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    width: 52, height: 52, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _foodPlaceholder(),
                  )
                : _foodPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(item.portion,
                    style: TextStyle(
                        color:    Colors.white.withOpacity(0.45),
                        fontSize: 11)),
              ],
            ),
          ),
          Text('${item.calories} kcal',
              style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _foodPlaceholder() {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
          color:        Colors.grey[800],
          borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.fastfood,
          color: Colors.white38, size: 22),
    );
  }

  Widget _buildAddFoodButton(String mealtime) {
    return DashedBorderButton(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  AddFoodScreen(kMealtime: mealtime)),
        ).then((_) => _fetchMeals());
      },
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, color: kNeonGreen, size: 16),
          SizedBox(width: 6),
          Text('Add Food',
              style: TextStyle(
                  color:      kNeonGreen,
                  fontSize:   13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Activities section ────────────────────────────────────────────────────
  Widget _buildActivitiesSection() {
    final totalBurned =
        _summary?.totalBurned ?? (_summary?.baseBurned ?? 2200);
    final baseBurned = _summary?.baseBurned ?? 2200;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TODAY'S ACTIVITIES",
            style: TextStyle(
                color:       Colors.white,
                fontSize:    15,
                fontWeight:  FontWeight.w800,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color:        kDarkCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color:      Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    offset:     const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                _buildActivityHeader(totalBurned),
                const Divider(height: 1, color: Colors.white10),
                _buildBaseBurnedRow(baseBurned),
                if (_loadingActivities)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation(kNeonGreen),
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else if (_activitiesError != null)
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: _buildSectionError(
                        _activitiesError!, _fetchActivities),
                  )
                else if (_activities.isNotEmpty) ...[
                  const Divider(height: 1, color: Colors.white10),
                  ..._activities.asMap().entries.map(
                    (entry) =>
                        _buildActivityRow(entry.key, entry.value),
                  ),
                ],
                const Divider(height: 1, color: Colors.white10),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: _buildAddActivityButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityHeader(int totalBurned) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin:  Alignment.centerLeft,
          end:    Alignment.centerRight,
          colors: [
            const Color(0xFF1A1A1A),
            kNeonGreen.withOpacity(0.08)
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color:        kNeonGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_run,
                  color: kNeonGreen, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('ACTIVITY',
                  style: TextStyle(
                    color:       Colors.white,
                    fontSize:    14,
                    fontWeight:  FontWeight.w700,
                    letterSpacing: 1,
                  )),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:        Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: kNeonGreen.withOpacity(0.55), width: 1),
              ),
              child: Text('${_formatKcal(totalBurned)} kcal',
                  style: const TextStyle(
                      color:      kNeonGreen,
                      fontSize:   12,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaseBurnedRow(int baseBurned) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color:        kNeonGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: kNeonGreen.withOpacity(0.2), width: 1),
            ),
            child: const Icon(Icons.favorite,
                color: kNeonGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Base Metabolic Rate',
                    style: TextStyle(
                        color:      Colors.white,
                        fontSize:   13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('Always included in burned',
                    style: TextStyle(
                        color:    Colors.white.withOpacity(0.45),
                        fontSize: 11)),
              ],
            ),
          ),
          Text('${_formatKcal(baseBurned)} kcal',
              style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildActivityRow(int index, _ActivityItem activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center,
                color: Colors.white54, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.name,
                    style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('Manual entry',
                    style: TextStyle(
                        color:    Colors.white.withOpacity(0.45),
                        fontSize: 11)),
              ],
            ),
          ),
          Text('${activity.calories} kcal',
              style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _deleteActivity(activity.id, index),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color:        Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close,
                  color: Colors.redAccent, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddActivityButton() {
    return DashedBorderButton(
      onTap: _showAddActivityDialog,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, color: kNeonGreen, size: 16),
          SizedBox(width: 6),
          Text('Add Activity',
              style: TextStyle(
                  color:      kNeonGreen,
                  fontSize:   13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── PAINTERS ──────────────────────────────────────────────────────────────────

class _CircularProgressPainter extends CustomPainter {
  final double progress;

  _CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final safeProgress = progress.isNaN || progress.isInfinite
        ? 0.0
        : progress.clamp(0.0, 1.0);

    final center      = Offset(size.width / 2, size.height / 2);
    final radius      = (size.width - 20) / 2;
    if (radius <= 0) return;

    const strokeWidth = 13.0;

    final bgPaint = Paint()
      ..color       = Colors.white.withOpacity(0.08)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final rect        = Rect.fromCircle(center: center, radius: radius);
    const startAngle  = -math.pi / 2;
    final sweepAngle  = 2 * math.pi * safeProgress;
    if (sweepAngle <= 0) return;

    final progressPaint = Paint()
      ..color       = const Color(0xFFA3FF12)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    final glowPaint = Paint()
      ..color       = const Color(0xFFA3FF12).withOpacity(0.25)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 6
      ..strokeCap   = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter old) =>
      old.progress != progress;
}

// ── DASHED BORDER BUTTON ──────────────────────────────────────────────────────

class DashedBorderButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const DashedBorderButton(
      {super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: Container(
          width:   double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child:   child,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth  = 6.0;
    const dashSpace  = 4.0;
    final paint = Paint()
      ..color       = kNeonGreen.withOpacity(0.4)
      ..strokeWidth = 1.2
      ..style       = PaintingStyle.stroke;

    const radius = 12.0;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(radius),
      ));

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(
              distance,
              next < metric.length ? next : metric.length),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}