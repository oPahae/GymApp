import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import '../models/coach.dart';

// ─── Config ────────────────────────────────────────────────────────────────
const String _baseUrl = 'http://localhost:5000/api'; // Android emulator
// const String _baseUrl = 'http://localhost:3000/api'; // iOS simulator

// ─── Service ───────────────────────────────────────────────────────────────
class CoachService {
  /// Récupère tous les coaches depuis l'API
  static Future<List<Coach>> fetchCoaches() async {
    final response = await http.get(Uri.parse('$_baseUrl/coach'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Coach.fromJson(json)).toList();
    }
    throw Exception('Impossible de charger les coaches (${response.statusCode})');
  }

  /// Envoie une invitation coach ↔ client
  static Future<void> sendInvite({
    required int coachID,
    required int clientID,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/invite'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'coachID': coachID, 'clientID': clientID}),
    );
    if (response.statusCode != 201) {
      throw Exception('Échec de l\'invitation (${response.statusCode})');
    }
  }
}

// ─── Page ──────────────────────────────────────────────────────────────────
class CoachesPage extends StatefulWidget {
  /// ID du client connecté — à passer depuis la session/auth
  final int currentClientID;

  const CoachesPage({super.key, required this.currentClientID});

  @override
  State<CoachesPage> createState() => _CoachesPageState();
}

class _CoachesPageState extends State<CoachesPage> {
  late Future<List<Coach>> _coachesFuture;
  // Garde les IDs des coaches déjà invités pour feedback immédiat
  final Set<int> _pendingInvites = {};

  @override
  void initState() {
    super.initState();
    _coachesFuture = CoachService.fetchCoaches();
  }

  void _refresh() {
    setState(() {
      _coachesFuture = CoachService.fetchCoaches();
    });
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  Future<void> _onInvite(Coach coach) async {
    if (_pendingInvites.contains(coach.id)) return; // évite double tap

    setState(() => _pendingInvites.add(coach.id));

    try {
      await CoachService.sendInvite(
        coachID: coach.id,
        clientID: widget.currentClientID,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitation envoyée à ${coach.name} ✓'),
          backgroundColor: kNeonGreen.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _pendingInvites.remove(coach.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'COACHES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                // Bouton refresh
                GestureDetector(
                  onTap: _refresh,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white.withOpacity(0.5),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: FutureBuilder<List<Coach>>(
              future: _coachesFuture,
              builder: (context, snapshot) {
                // ── Chargement ──
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kNeonGreen),
                  );
                }
                // ── Erreur ──
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            color: Colors.white.withOpacity(0.3), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Impossible de charger les coaches',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _refresh,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: kNeonGreen),
                            ),
                            child: const Text('Réessayer',
                                style: TextStyle(
                                    color: kNeonGreen,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // ── Vide ──
                final coaches = snapshot.data!;
                if (coaches.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun coach disponible',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 13),
                    ),
                  );
                }
                // ── Liste ──
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: coaches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final coach = coaches[index];
                    final isInvited = _pendingInvites.contains(coach.id);
                    return _CoachCard(
                      coach: coach,
                      formattedDate: _formatDate(coach.createdAt),
                      isInvited: isInvited,
                      onInvite: () => _onInvite(coach),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card ──────────────────────────────────────────────────────────────────
class _CoachCard extends StatelessWidget {
  final Coach coach;
  final String formattedDate;
  final bool isInvited;
  final VoidCallback onInvite;

  const _CoachCard({
    required this.coach,
    required this.formattedDate,
    required this.isInvited,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10, width: 1),
        boxShadow: [
          BoxShadow(
            color: kNeonGreen.withOpacity(0.05),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kNeonGreen.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: kNeonGreen.withOpacity(0.4), width: 1.5),
              ),
              child: Center(
                child: Text(
                  coach.name[0],
                  style: const TextStyle(
                    color: kNeonGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 11,
                          color: Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Text(
                        'Membre depuis $formattedDate',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Bouton Inviter
            GestureDetector(
              onTap: isInvited ? null : onInvite,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isInvited
                      ? kNeonGreen.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isInvited
                        ? kNeonGreen.withOpacity(0.5)
                        : kNeonGreen,
                    width: 1.5,
                  ),
                ),
                child: isInvited
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: kNeonGreen, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Invited',
                            style: TextStyle(
                              color: kNeonGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Invite',
                        style: TextStyle(
                          color: kNeonGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}