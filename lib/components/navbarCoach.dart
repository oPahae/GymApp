import 'package:flutter/material.dart';
import 'package:test_hh/constants/colors.dart';

class NavBarCoach extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const NavBarCoach({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      const _NavData(icon: Icons.people, label: 'Clients'),
      const _NavData(icon: Icons.person_add, label: 'Invites'),
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isActive = index == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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

class _NavData {
  final IconData icon;
  final String label;
  const _NavData({required this.icon, required this.label});
}
