import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import '../models/client.dart';

// ─── Config ────────────────────────────────────────────────────────────────
const String _baseUrl = 'http://localhost:5000/api'; // Android emulator
// const String _baseUrl = 'http://localhost:3000/api'; // iOS simulator

// ─── Service ───────────────────────────────────────────────────────────────
class InviteService {
  /// Récupère les invitations en attente pour un coach
  static Future<List<Client>> fetchInvites(int coachID) async {
    final response =
        await http.get(Uri.parse('$_baseUrl/invite/coach/$coachID'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((j) => Client.fromJson(j)).toList();
    }
    throw Exception('Impossible de charger les invitations (${response.statusCode})');
  }

  /// Accepter un client
  static Future<void> acceptInvite(
      {required int coachID, required int clientID}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/invite/accept'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'coachID': coachID, 'clientID': clientID}),
    );
    if (response.statusCode != 200) {
      throw Exception('Échec de l\'acceptation (${response.statusCode})');
    }
  }

  /// Refuser un client
  static Future<void> refuseInvite(
      {required int coachID, required int clientID}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/invite/refuse'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'coachID': coachID, 'clientID': clientID}),
    );
    if (response.statusCode != 200) {
      throw Exception('Échec du refus (${response.statusCode})');
    }
  }
}

// ─── Page ──────────────────────────────────────────────────────────────────
class InvitesPage extends StatefulWidget {
  /// ID du coach connecté — à passer depuis la session/auth
  final int currentCoachID;

  const InvitesPage({super.key, required this.currentCoachID});

  @override
  State<InvitesPage> createState() => _InvitesPageState();
}

class _InvitesPageState extends State<InvitesPage> {
  late Future<List<Client>> _invitesFuture;
  // Liste locale pour les suppressions optimistes
  List<Client>? _invites;
  // IDs en cours de traitement (loading)
  final Set<int> _processing = {};

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  void _loadInvites() {
    _invitesFuture = InviteService.fetchInvites(widget.currentCoachID)
      ..then((list) {
        if (mounted) setState(() => _invites = list);
      });
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  int _calculateAge(DateTime birth) {
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) age--;
    return age;
  }

  // ── Accept ──────────────────────────────────────────────────────────────
  Future<void> _onAccept(Client client) async {
    if (_processing.contains(client.id)) return;
    setState(() => _processing.add(client.id));

    try {
      await InviteService.acceptInvite(
        coachID: widget.currentCoachID,
        clientID: client.id,
      );
      if (!mounted) return;
      setState(() {
        _invites?.remove(client);
        _processing.remove(client.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${client.name} accepté(e) ✓'),
          backgroundColor: kNeonGreen.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing.remove(client.id));
      _showError('$e');
    }
  }

  // ── Refuse ──────────────────────────────────────────────────────────────
  void _onRefuse(Client client) {
    final TextEditingController reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: kDarkCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Reason of Refusal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Explain to ${client.name} why you refused their invitation.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: reasonController,
                    maxLines: 4,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ex : complet pour l\'instant...',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Annuler
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Center(
                            child: Text('Cancel',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Confirmer refus
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Veuillez écrire une raison.'),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          await _doRefuse(client);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text('Refuse',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _doRefuse(Client client) async {
    setState(() => _processing.add(client.id));
    try {
      await InviteService.refuseInvite(
        coachID: widget.currentCoachID,
        clientID: client.id,
      );
      if (!mounted) return;
      setState(() {
        _invites?.remove(client);
        _processing.remove(client.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande de ${client.name} refusée.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing.remove(client.id));
      _showError('$e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur : $message'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final invites = _invites;

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
              children: [
                const Text(
                  'INVITATIONS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 10),
                // Badge compteur — affiché uniquement quand les données sont là
                if (invites != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: kNeonGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: kNeonGreen.withOpacity(0.4)),
                    ),
                    child: Text(
                      '${invites.length}',
                      style: const TextStyle(
                        color: kNeonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const Spacer(),
                // Bouton refresh
                GestureDetector(
                  onTap: _loadInvites,
                  child: Icon(Icons.refresh_rounded,
                      color: Colors.white.withOpacity(0.4), size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: FutureBuilder<List<Client>>(
              future: _invitesFuture,
              builder: (context, snapshot) {
                // Chargement initial
                if (snapshot.connectionState == ConnectionState.waiting &&
                    invites == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: kNeonGreen),
                  );
                }
                // Erreur
                if (snapshot.hasError && invites == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            color: Colors.white.withOpacity(0.3), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Impossible de charger les invitations',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => setState(_loadInvites),
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

                final list = invites ?? [];

                if (list.isEmpty) return _buildEmptyState();

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final client = list[index];
                    final isProcessing = _processing.contains(client.id);
                    return _InviteCard(
                      client: client,
                      age: _calculateAge(client.birth),
                      formattedBirth: _formatDate(client.birth),
                      isProcessing: isProcessing,
                      onAccept: () => _onAccept(client),
                      onRefuse: () => _onRefuse(client),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded,
              size: 48, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 14),
          Text(
            'No invitations',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card ──────────────────────────────────────────────────────────────────
class _InviteCard extends StatelessWidget {
  final Client client;
  final int age;
  final String formattedBirth;
  final bool isProcessing;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;

  const _InviteCard({
    required this.client,
    required this.age,
    required this.formattedBirth,
    required this.isProcessing,
    required this.onAccept,
    required this.onRefuse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isProcessing ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10, width: 1),
          boxShadow: [
            BoxShadow(color: kNeonGreen.withOpacity(0.04), blurRadius: 16),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Infos client ──
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: kNeonGreen.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: kNeonGreen.withOpacity(0.4), width: 1.5),
                    ),
                    child: client.image.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              client.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildInitial(),
                            ),
                          )
                        : _buildInitial(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.cake_outlined,
                                size: 12,
                                color: Colors.white.withOpacity(0.4)),
                            const SizedBox(width: 4),
                            Text(
                              '$formattedBirth  •  $age ans',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Spinner si en cours
                  if (isProcessing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: kNeonGreen),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Colors.white10),
              const SizedBox(height: 14),
              // ── Boutons ──
              Row(
                children: [
                  // Refuser
                  Expanded(
                    child: GestureDetector(
                      onTap: isProcessing ? null : onRefuse,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isProcessing
                                  ? Colors.redAccent.withOpacity(0.4)
                                  : Colors.redAccent,
                              width: 1.5),
                        ),
                        child: const Center(
                          child: Text('Refuse',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Accepter
                  Expanded(
                    child: GestureDetector(
                      onTap: isProcessing ? null : onAccept,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isProcessing
                                  ? kNeonGreen.withOpacity(0.4)
                                  : kNeonGreen,
                              width: 1.5),
                        ),
                        child: const Center(
                          child: Text('Accept',
                              style: TextStyle(
                                  color: kNeonGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        client.name[0],
        style: const TextStyle(
          color: kNeonGreen,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}