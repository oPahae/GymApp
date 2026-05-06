import 'package:flutter/material.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/screens/chat.dart';
import 'package:test_hh/services/chatApi_service.dart';

/// Écran liste pour le COACH : affiche toutes ses conversations avec ses clients.
class CoachConversationsScreen extends StatefulWidget {
  final int coachId;
  final String coachName;

  const CoachConversationsScreen({
    super.key,
    required this.coachId,
    required this.coachName,
  });

  @override
  State<CoachConversationsScreen> createState() => _CoachConversationsScreenState();
}

class _CoachConversationsScreenState extends State<CoachConversationsScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final convs = await ChatApiService.getConversations();
      setState(() { _conversations = convs; _isLoading = false; });
    } catch (e) {
      setState(() { _isLoading = false; _errorMsg = 'Erreur de chargement : $e'; });
    }
  }

  void _openChat(Map<String, dynamic> conv) {
    final clientId = conv['clientID'] as int?;
    final clientName = conv['clientName'] as String? ?? 'Client';

    if (clientId == null) {
      _showSnack('ID client manquant.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          session: ChatSession(
            coachId: widget.coachId,
            coachName: widget.coachName,
            coachInitials: _initials(widget.coachName),
            clientId: clientId,
            clientName: clientName,
            clientInitials: _initials(clientName),
            role: 'coach',
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _formatTime(String rawTime) {
    try {
      final dt = DateTime.parse(rawTime).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        title: const Text(
          'Mes conversations',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.07),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kNeonGreen),
      );
    }

    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMsg!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: kNeonGreen,
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Text(
          'Aucun client assigné pour le moment.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 14,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: kNeonGreen,
      backgroundColor: const Color(0xFF111111),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => Divider(
          color: Colors.white.withOpacity(0.06),
          height: 1,
        ),
        itemBuilder: (_, i) => _buildTile(_conversations[i]),
      ),
    );
  }

  Widget _buildTile(Map<String, dynamic> conv) {
    final clientName = conv['clientName'] as String? ?? 'Client';
    final lastMessage = conv['lastMessage'] as String? ?? 'Aucun message';
    final unread = (conv['unreadCount'] as num?)?.toInt() ?? 0;
    final rawTime = conv['lastMessageTime'];
    final timeLabel = rawTime != null ? _formatTime(rawTime.toString()) : '';

    return InkWell(
      onTap: () => _openChat(conv),
      splashColor: kNeonGreen.withOpacity(0.05),
      highlightColor: kNeonGreen.withOpacity(0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kNeonGreen.withOpacity(0.10),
                border: Border.all(
                  color: kNeonGreen.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  _initials(clientName),
                  style: const TextStyle(
                    color: kNeonGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unread > 0
                          ? Colors.white.withOpacity(0.75)
                          : Colors.white.withOpacity(0.35),
                      fontSize: 12,
                      fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: kNeonGreen,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: kNeonGreen.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
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
}