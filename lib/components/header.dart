import 'package:flutter/material.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/constants/names.dart';
import 'package:test_hh/screens/profileClient.dart';
import 'package:test_hh/screens/profileCoach.dart';
import 'package:test_hh/services/api_service.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildChatButton(),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: gymName.split(" ")[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  TextSpan(
                    text: gymName.split(" ")[1],
                    style: const TextStyle(
                      color: kNeonGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.signal_cellular_alt, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                const Icon(Icons.wifi, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                const Icon(Icons.battery_full, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                _buildAvatar(context), // Passer le contexte pour la navigation
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: kDarkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
        ),
        Positioned(
          top: -3,
          right: -3,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: kNeonGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kNeonGreen.withOpacity(0.7),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final role = await ApiService.getUserRole();
        if (role == 'client') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileClient()),
          );
        } else if (role == 'coach') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileCoach()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez vous connecter pour accéder au profil.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: kNeonGreen, width: 2),
          boxShadow: [
            BoxShadow(
              color: kNeonGreen.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=100&h=100&dpr=1',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[800],
              child: const Icon(Icons.person, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}