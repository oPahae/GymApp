import 'package:flutter/material.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import '../models/coach.dart';

final List<Coach> fakeCoaches = [
  Coach(id: 1, name: 'Zaynab Zidane',   createdAt: DateTime(2023, 3, 12), image: ''),
  Coach(id: 2, name: 'Jihane Tayef',    createdAt: DateTime(2023, 7, 12), image: ''),
  Coach(id: 3, name: 'Sanaa El Fassi',  createdAt: DateTime(2024, 6, 4),  image: ''),
  Coach(id: 4, name: 'Youssef Chraibi', createdAt: DateTime(2024, 5, 1),  image: ''),
  Coach(id: 5, name: 'Samir Salim',     createdAt: DateTime(2023, 8, 6),  image: ''),
];

class CoachesPage extends StatefulWidget {
  const CoachesPage({super.key});

  @override
  State<CoachesPage> createState() => _CoachesPageState();
}

class _CoachesPageState extends State<CoachesPage> {

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _onInvite(Coach coach) {
    // TODO: appel API invite
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invitation sent to ${coach.name}'),
        backgroundColor: kDarkCard,
        behavior: SnackBarBehavior.floating,
      ),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              'COACHES',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: fakeCoaches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final coach = fakeCoaches[index];
                return _CoachCard(
                  coach: coach,
                  formattedDate: _formatDate(coach.createdAt),
                  onInvite: () => _onInvite(coach),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  final Coach coach;
  final String formattedDate;
  final VoidCallback onInvite;

  const _CoachCard({
    required this.coach,
    required this.formattedDate,
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
                border: Border.all(color: kNeonGreen.withOpacity(0.4), width: 1.5),
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
                          size: 11, color: Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Text(
                        'A member since $formattedDate',
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
              onTap: onInvite,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kNeonGreen, width: 1.5),
                ),
                child: const Text(
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