import 'package:flutter/material.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/models/coach.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:test_hh/constants/urls.dart';

class CoachesScreen extends StatefulWidget {
  const CoachesScreen({super.key});

  @override
  State<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends State<CoachesScreen> {
  List<Coach> _coaches = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Exemple : clientID = 1 (à remplacer par la valeur réelle plus tard)
  final int kClientID = 1;

  // État pour gérer l'invitation
  Coach? _invitedCoach;
  bool _isCheckingInvitation = true;

  @override
  void initState() {
    super.initState();
    _fetchCoaches();
    _checkInvitation();
  }

  // ─── API Calls ───────────────────────────────────────────────────────────────

  Future<void> _fetchCoaches() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/temp/coaches'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> coachesData = data['data'];
          setState(() {
            _coaches = coachesData
                .map((coach) => Coach.fromJson(coach))
                .toList();
          });
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = data['message'] ?? 'Failed to load coaches';
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load coaches (HTTP ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Network error: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkInvitation() async {
    setState(() => _isCheckingInvitation = true);
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/temp/coaches/invited/$kClientID'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _invitedCoach = Coach.fromJson(data['data']);
          });
        } else {
          setState(() => _invitedCoach = null);
        }
      } else {
        setState(() => _invitedCoach = null);
      }
    } catch (e) {
      setState(() => _invitedCoach = null);
    } finally {
      setState(() => _isCheckingInvitation = false);
    }
  }

  Future<void> _onInvite(Coach coach) async {
    if (_invitedCoach != null) {
      // Afficher un message que le client a déjà invité un coach
      _showAlreadyInvitedDialog(coach);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/temp/coaches/invite'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'clientID': kClientID,
          'coachID': coach.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invitation sent to ${coach.name}', style: TextStyle(color: Colors.lightGreenAccent)),
              backgroundColor: kDarkCard,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Mettre à jour l'état local
          setState(() => _invitedCoach = coach);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to send invitation', style: TextStyle(color: Colors.orange)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invitation (HTTP ${response.statusCode})', style: TextStyle(color: Colors.orange)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onCancelInvitation() async {
    try {
      final response = await http.delete(
        Uri.parse('$kBaseUrl/api/temp/coaches/cancel-invite'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'clientID': kClientID,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Invitation cancelled', style: TextStyle(color: Colors.lightGreenAccent)),
              backgroundColor: kDarkCard,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Mettre à jour l'état local
          setState(() => _invitedCoach = null);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to cancel invitation'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel invitation (HTTP ${response.statusCode})'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAlreadyInvitedDialog(Coach newCoach) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kDarkCard,
        title: const Text(
          'Already Invited a Coach',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'You have already invited ${_invitedCoach!.name}. '
          'You can only invite one coach at a time.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: kNeonGreen),
            ),
          ),
          if (_invitedCoach != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _onCancelInvitation();
              },
              child: const Text(
                'Cancel Invitation',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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
            child: _isLoading
                ? _buildLoading()
                : _hasError
                    ? _buildError()
                    : _coaches.isEmpty
                        ? _buildEmpty()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _coaches.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final coach = _coaches[index];
                              return _CoachCard(
                                coach: coach,
                                formattedDate: _formatDate(coach.createdAt),
                                isInvited: _invitedCoach?.id == coach.id,
                                onInvite: () => _onInvite(coach),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: kNeonGreen),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.withOpacity(0.5),
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            style: TextStyle(
              color: Colors.red.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchCoaches,
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeonGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'No coaches available',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ─── Coach Card ───────────────────────────────────────────────────────────────
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
            // Avatar (image ou initiale)
            _buildAvatar(),
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
                      Icon(
                        Icons.calendar_today,
                        size: 11,
                        color: Colors.white.withOpacity(0.4),
                      ),
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
            // Bouton Inviter ou "Invited"
            isInvited
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: kNeonGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Invited',
                      style: TextStyle(
                        color: kNeonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                : GestureDetector(
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

  Widget _buildAvatar() {
    if (coach.image != null && coach.image!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          coach.image!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildDefaultAvatar();
          },
        ),
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: kNeonGreen.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: kNeonGreen.withOpacity(0.4), width: 1.5),
      ),
      child: Center(
        child: Text(
          coach.name.isNotEmpty ? coach.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: kNeonGreen,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}