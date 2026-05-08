import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/models/client.dart';
import 'package:test_hh/constants/urls.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class WeightEntry {
  final DateTime date;
  final double weight;
  const WeightEntry({required this.date, required this.weight});
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class StatScreen extends StatefulWidget {
  StatScreen({super.key});

  final Client client = Client(
    id: 1,
    name: 'Test User',
    image: 'https://i.pravatar.cc/150?img=1',
    birth: DateTime(1995, 6, 15),
    weight: 80,
    height: 175,
    frequency: 4,
    goal: 'Perte de poids',
    weightGoal: 70,
    createdAt: DateTime(2024, 1, 1),
    coachID: 1,
    gender: 'male',
    email: '',
    password: '',
  );

  @override
  State<StatScreen> createState() => _StatScreenState();
}

class _StatScreenState extends State<StatScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _barCtrl;
  late Animation<double> _barAnim;

  // ── State de l'historique ─────────────────────────────────────────────────
  List<WeightEntry> _history = [];
  bool _loadingHistory = true;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
    _fetchWeightHistory();
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  // ── API ───────────────────────────────────────────────────────────────────

  Future<void> _fetchWeightHistory() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final uri = Uri.parse('$kBaseUrl/api/stat/${widget.client.id}/weight-history');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) throw Exception(body['message']);

      final list = body['data'] as List<dynamic>;
      final entries = list.map((e) {
        final map = e as Map<String, dynamic>;
        return WeightEntry(
          date: DateTime.parse(map['date'] as String),
          weight: (map['weight'] as num).toDouble(),
        );
      }).toList();

      setState(() {
        _history = entries;
        _loadingHistory = false;
      });

      // Lance l'animation de la barre de progression une fois les données prêtes
      Future.delayed(const Duration(milliseconds: 300), _barCtrl.forward);
    } catch (e) {
      setState(() {
        _historyError = e.toString();
        _loadingHistory = false;
      });
      // Lance quand même l'animation avec ratio 0
      Future.delayed(const Duration(milliseconds: 300), _barCtrl.forward);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  double get _start =>
      _history.isNotEmpty ? _history.first.weight : widget.client.weight;
  double get _current => widget.client.weight;
  double get _goal => widget.client.weightGoal;
  double get _change => _current - _start;
  double get _remaining => (_current - _goal).abs();

  double get _ratio {
    final total = (_start - _goal).abs();
    if (total == 0) return 1;
    return ((_start - _current).abs() / total).clamp(0.0, 1.0);
  }

  double get _bmi {
    final h = widget.client.height / 100;
    return widget.client.weight / (h * h);
  }

  String get _bmiLabel {
    if (_bmi < 18.5) return 'INSUFFISANT';
    if (_bmi < 25) return 'NORMAL';
    if (_bmi < 30) return 'SURPOIDS';
    return 'OBÉSITÉ';
  }

  Color get _bmiColor {
    if (_bmi < 18.5) return const Color(0xFF5BC4F5);
    if (_bmi < 25) return kNeonGreen;
    if (_bmi < 30) return const Color(0xFFFFA940);
    return const Color(0xFFFF6B6B);
  }

  int get _age {
    final n = DateTime.now();
    int a = n.year - widget.client.birth.year;
    if (n.month < widget.client.birth.month ||
        (n.month == widget.client.birth.month &&
            n.day < widget.client.birth.day))
      a--;
    return a;
  }

  String get _eta {
    if (_history.length < 2) return '—';
    if (_remaining < 0.5) return 'Atteint !';
    final months = _history.length - 1;
    final totalDelta = _history.last.weight - _history.first.weight;
    if (months == 0 || totalDelta.abs() < 0.1) return '—';
    final rate = totalDelta / months;
    if (rate.abs() < 0.05) return '—';
    final needed = (_current - _goal) / rate;
    if (needed <= 0) return 'Atteint !';
    final r = needed.round();
    if (r < 1) return '< 1 mois';
    if (r < 12) return '$r mois';
    final yr = r ~/ 12;
    final mo = r % 12;
    return mo == 0
        ? '$yr an${yr > 1 ? 's' : ''}'
        : '$yr an${yr > 1 ? 's' : ''} $mo mois';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: Header(),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                children: [
                  _profileCard(),
                  const SizedBox(height: 12),
                  _miniStatsRow(),
                  const SizedBox(height: 12),
                  _progressCard(),
                  const SizedBox(height: 12),
                  _chartCard(),
                  const SizedBox(height: 12),
                  _goalBanner(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(selectedIndex: 3),
    );
  }

  // ─── TOP BAR ──────────────────────────────────────────────────────────────
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: kDarkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STATISTIQUES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  widget.client.name,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _chip(_bmiLabel, _bmiColor),
        ],
      ),
    );
  }

  // ─── PROFILE CARD ─────────────────────────────────────────────────────────
  Widget _profileCard() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.client.image,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1A1A1A),
              child: const Icon(Icons.person, color: Colors.white12, size: 32),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, kDarkCard.withOpacity(0.97)],
                stops: const [0.2, 0.6],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 70),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _chip('CLIENT', kNeonGreen),
                      const SizedBox(height: 5),
                      Text(
                        widget.client.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$_age ans · ${widget.client.height.toStringAsFixed(0)} cm · ${widget.client.goal}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.38),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── MINI STATS ROW ───────────────────────────────────────────────────────
  Widget _miniStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _miniStat(
            Icons.monitor_weight_outlined,
            'POIDS',
            '${_current.toStringAsFixed(1)}',
            'kg',
            kNeonGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat(
            Icons.flag_outlined,
            'OBJECTIF',
            '${_goal.toStringAsFixed(1)}',
            'kg',
            const Color(0xFF5BC4F5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat(
            Icons.analytics_outlined,
            'IMC',
            _bmi.toStringAsFixed(1),
            '',
            _bmiColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat(
            Icons.fitness_center_rounded,
            'SÉANCES',
            '${widget.client.frequency}x',
            '/sem',
            const Color(0xFFFFA940),
          ),
        ),
      ],
    );
  }

  Widget _miniStat(
    IconData icon,
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── PROGRESS CARD ────────────────────────────────────────────────────────
  Widget _progressCard() {
    final isLoss = _goal < _start;
    final goingRight = (isLoss && _change <= 0) || (!isLoss && _change >= 0);
    final changeColor = goingRight ? kNeonGreen : const Color(0xFFFF6B6B);

    if (_loadingHistory) {
      return _loadingCard('Calcul de la progression…');
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kNeonGreen.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: kNeonGreen,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'PROGRESSION',
                style: TextStyle(
                  color: kNeonGreen.withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _barAnim,
            builder: (_, __) {
              final v = _ratio * _barAnim.value;
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(v * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        '${_remaining.toStringAsFixed(1)} kg restants',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.38),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.07),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        kNeonGreen,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _weightNode(
                'DÉPART',
                '${_start.toStringAsFixed(1)} kg',
                Colors.white.withOpacity(0.4),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.2),
                size: 18,
              ),
              _weightNode(
                'ACTUEL',
                '${_current.toStringAsFixed(1)} kg',
                kNeonGreen,
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.2),
                size: 18,
              ),
              _weightNode(
                'OBJECTIF',
                '${_goal.toStringAsFixed(1)} kg',
                const Color(0xFF5BC4F5),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _infoRow(
                  _change <= 0
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
                  changeColor,
                  'Changement total',
                  '${_change > 0 ? '+' : ''}${_change.toStringAsFixed(1)} kg',
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withOpacity(0.08),
              ),
              Expanded(
                child: _infoRow(
                  Icons.access_time_rounded,
                  const Color(0xFFFFA940),
                  'Temps estimé',
                  _eta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weightNode(String label, String value, Color color) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.28),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    ],
  );

  Widget _infoRow(IconData icon, Color iconColor, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── CHART CARD ───────────────────────────────────────────────────────────
  Widget _chartCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: kNeonGreen, size: 14),
              const SizedBox(width: 6),
              Text(
                'ÉVOLUTION DU POIDS',
                style: TextStyle(
                  color: kNeonGreen.withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                'par mois · kg',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Contenu du graphique ──────────────────────────────────────────
          SizedBox(
            height: 180,
            child: _loadingHistory
                ? const Center(
                    child: CircularProgressIndicator(
                      color: kNeonGreen,
                      strokeWidth: 2,
                    ),
                  )
                : _historyError != null
                ? _chartError()
                : _history.length < 2
                ? Center(
                    child: Text(
                      'Pas assez de données',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 13,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _ChartPainter(
                      history: _history,
                      goalWeight: _goal,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),

          const SizedBox(height: 14),
          Row(
            children: [
              _legend(kNeonGreen, 'Poids réel'),
              const SizedBox(width: 18),
              _legend(const Color(0xFF5BC4F5), 'Objectif', dashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.signal_wifi_off,
            color: Colors.white.withOpacity(0.12),
            size: 32,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _fetchWeightHistory,
            child: Text(
              'Réessayer',
              style: TextStyle(
                color: kNeonGreen.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label, {bool dashed = false}) {
    return Row(
      children: [
        SizedBox(
          width: 22,
          height: 2,
          child: dashed
              ? CustomPaint(painter: _DashLine(color: color))
              : Container(color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 11),
        ),
      ],
    );
  }

  // ─── GOAL BANNER ──────────────────────────────────────────────────────────
  Widget _goalBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kNeonGreen.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kNeonGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kNeonGreen.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: kNeonGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.client.goal,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Estimé dans $_eta',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kNeonGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kNeonGreen.withOpacity(0.22)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: kNeonGreen,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  _eta,
                  style: const TextStyle(
                    color: kNeonGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared ───────────────────────────────────────────────────────────────
  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _loadingCard(String label) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                color: kNeonGreen,
                strokeWidth: 1.5,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dash line painter ────────────────────────────────────────────────────────
class _DashLine extends CustomPainter {
  final Color color;
  const _DashLine({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset((x + 4).clamp(0.0, size.width), size.height / 2),
        p,
      );
      x += 8;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Chart painter ────────────────────────────────────────────────────────────
class _ChartPainter extends CustomPainter {
  final List<WeightEntry> history;
  final double goalWeight;

  const _ChartPainter({required this.history, required this.goalWeight});

  static const _lineColor = kNeonGreen;
  static const _goalColor = Color(0xFF5BC4F5);

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    const double pL = 36, pR = 10, pT = 8, pB = 26;
    final cW = size.width - pL - pR;
    final cH = size.height - pT - pB;

    final allW = [...history.map((e) => e.weight), goalWeight];
    final minW = allW.reduce(min) - 2;
    final maxW = allW.reduce(max) + 2;
    final range = maxW - minW;

    Offset pt(int i, double val) => Offset(
      pL + (i / (history.length - 1)) * cW,
      pT + (1 - (val - minW) / range) * cH,
    );

    final gridP = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 4; i++) {
      final y = pT + (i / 4) * cH;
      canvas.drawLine(Offset(pL, y), Offset(size.width - pR, y), gridP);
      _txt(
        canvas,
        (maxW - (i / 4) * range).toStringAsFixed(0),
        Offset(0, y - 6),
        Colors.white.withOpacity(0.28),
      );
    }

    final goalY = pT + (1 - (goalWeight - minW) / range) * cH;
    final dashP = Paint()
      ..color = _goalColor
      ..strokeWidth = 1.2;
    for (double x = pL; x < size.width - pR; x += 10) {
      canvas.drawLine(
        Offset(x, goalY),
        Offset((x + 5).clamp(0.0, size.width - pR), goalY),
        dashP,
      );
    }

    final fill = Path();
    for (int i = 0; i < history.length; i++) {
      final o = pt(i, history[i].weight);
      i == 0 ? fill.moveTo(o.dx, o.dy) : fill.lineTo(o.dx, o.dy);
    }
    fill
      ..lineTo(pt(history.length - 1, history.last.weight).dx, pT + cH)
      ..lineTo(pL, pT + cH)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x3AC8FF00), Color(0x00C8FF00)],
        ).createShader(Rect.fromLTWH(0, pT, size.width, cH)),
    );

    final line = Path();
    for (int i = 0; i < history.length; i++) {
      final o = pt(i, history[i].weight);
      i == 0 ? line.moveTo(o.dx, o.dy) : line.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = _lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (int i = 0; i < history.length; i++) {
      final o = pt(i, history[i].weight);
      canvas.drawCircle(o, 3.5, Paint()..color = const Color(0xFF111118));
      canvas.drawCircle(o, 2.5, Paint()..color = _lineColor);
    }

    const abbr = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jui',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    final step = ((history.length - 1) / 3).ceil().clamp(1, history.length);
    for (int i = 0; i < history.length; i += step) {
      final o = pt(i, history[i].weight);
      _txt(
        canvas,
        abbr[history[i].date.month - 1],
        Offset(o.dx - 10, pT + cH + 6),
        Colors.white.withOpacity(0.28),
      );
    }
  }

  void _txt(Canvas c, String text, Offset offset, Color color) {
    (TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout()).paint(c, offset);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.history != history || old.goalWeight != goalWeight;
}
