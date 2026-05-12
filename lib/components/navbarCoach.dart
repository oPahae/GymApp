import 'package:flutter/material.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/screens/clients.dart';
import 'package:test_hh/screens/invites.dart';

class NavBarCoach extends StatefulWidget {
  NavBarCoach({ super.key, required this.selectedIndex });

  int selectedIndex;

  @override
  State<NavBarCoach> createState() => _NavBarCoachState();
}

// test

class _NavBarCoachState extends State<NavBarCoach> {

  @override
  Widget build(BuildContext context) {
    print("slm hh");
    final items = [
      _NavItem(
        icon: Icons.people,
        label: 'Clients',
        href: ClientsScreen()
      ),
      _NavItem(
        icon: Icons.person_add,
        label: 'Invites',
        href: InvitesPage(),
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: kNeonGreen.withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isActive = index == widget.selectedIndex;
          return GestureDetector(
            onTap: () => {
              // setState(() => _selectedIndex = index),
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item.href),
              ),
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? kNeonGreen.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color: isActive ? kNeonGreen : kGrayText,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isActive ? kNeonGreen : kGrayText,
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget href;
  const _NavItem({required this.icon, required this.label, required this.href});
}
