import 'package:flutter/material.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import '../models/client.dart';


final List<Client> fakeInvites = [
  Client(
    id: 1, name: 'Amine Berrada', image: '',
    birth: DateTime(1998, 4, 15), weight: 82, height: 178,
    frequency: 4, goal: 'Prise de masse', weightGoal: 90,
    createdAt: DateTime(2024, 11, 1), coachId: 1,
  ),
  Client(
    id: 2, name: 'Fatima Zahra', image: '',
    birth: DateTime(2000, 8, 22), weight: 60, height: 163,
    frequency: 3, goal: 'Perte de poids', weightGoal: 52,
    createdAt: DateTime(2024, 12, 5), coachId: 1,
  ),
  Client(
    id: 3, name: 'Khalid Mansouri', image: '',
    birth: DateTime(1995, 1, 10), weight: 95, height: 182,
    frequency: 5, goal: 'Musculation', weightGoal: 88,
    createdAt: DateTime(2025, 1, 20), coachId: 1,
  ),
];

class InvitesPage extends StatefulWidget {
  const InvitesPage({super.key});
 
  @override
  State<InvitesPage> createState() => _InvitesPageState();
}
 
class _InvitesPageState extends State<InvitesPage> {
 
  // TODO: remplacer par les vraies données depuis l'API
  final List<Client> _invites = List.from(fakeInvites);
 
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
 
  int _calculateAge(DateTime birth) {
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }
 

 
  void _onAccept(Client client) {
    // TODO: appel API POST /invites/:id/accept
    setState(() => _invites.remove(client));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${client.name} accepté(e) !'),
        backgroundColor: kNeonGreen.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
 

 
  void _onRefuse(Client client) {
    final TextEditingController reasonController = TextEditingController();
 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
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
                  'Explain to ${client.name} why did you refuse their invitation.',
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
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ex : full...',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.25), fontSize: 13),
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
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Confirmer refus
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
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
                          // TODO: appel API POST /invites/:id/refuse { reason }
                          setState(() => _invites.remove(client));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Demande de ${client.name} refusée.'),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Refuse',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
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
                // Badge compteur
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: kNeonGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kNeonGreen.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${_invites.length}',
                    style: const TextStyle(
                      color: kNeonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _invites.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _invites.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final client = _invites[index];
                      return _InviteCard(
                        client: client,
                        age: _calculateAge(client.birth),
                        formattedBirth: _formatDate(client.birth),
                        onAccept: () => _onAccept(client),
                        onRefuse: () => _onRefuse(client),
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
 

 
class _InviteCard extends StatelessWidget {
  final Client client;
  final int age;
  final String formattedBirth;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;
 
  const _InviteCard({
    required this.client,
    required this.age,
    required this.formattedBirth,
    required this.onAccept,
    required this.onRefuse,
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
            color: kNeonGreen.withOpacity(0.04),
            blurRadius: 16,
          ),
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
                            errorBuilder: (_, __, ___) => _buildInitial(),
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
                    onTap: onRefuse,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.redAccent, width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          'Refuse',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Accepter
                Expanded(
                  child: GestureDetector(
                    onTap: onAccept,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kNeonGreen, width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          'Accept',
                          style: TextStyle(
                            color: kNeonGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
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