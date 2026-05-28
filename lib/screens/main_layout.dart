import 'package:flutter/material.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/components/navbarCoach.dart';
import 'package:test_hh/session/user_session.dart';

// Client screens
import 'package:test_hh/screens/home.dart';
import 'package:test_hh/screens/foods.dart';
import 'package:test_hh/screens/bodyParts.dart';
import 'package:test_hh/screens/stats.dart';

// Coach screens
import 'package:test_hh/screens/clients.dart';
import 'package:test_hh/screens/invites.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  late PageController _pageController;

  late final List<Widget> _clientScreens;
  late final List<Widget> _coachScreens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    
    _clientScreens = [
      const HomeScreen(),
      const FoodsScreen(),
      const BodyPartsScreen(),
      const StatScreen(),
    ];
    _coachScreens = [
      const ClientsScreen(),
      const InvitesPage(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClient = UserSession.instance.isClient;
    final screens = isClient ? _clientScreens : _coachScreens;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: screens,
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: MediaQuery.of(context).padding.bottom + 10,
            child: isClient
                ? NavBar(
                    selectedIndex: _selectedIndex,
                    onTap: _onItemTapped,
                  )
                : NavBarCoach(
                    selectedIndex: _selectedIndex,
                    onTap: _onItemTapped,
                  ),
          ),
        ],
      ),
    );
  }
}
