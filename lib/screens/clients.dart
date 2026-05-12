import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbarCoach.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/constants/urls.dart';
import 'package:test_hh/screens/client.dart';
import 'package:test_hh/models/client.dart';

// ── Screen ──────────────────────────────────────────────────────────────────
class ClientsScreen extends StatefulWidget {
  final int coachID;
  const ClientsScreen({super.key, this.coachID = 3}); // example coachID = 1

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String? _filterGender; // null = all, "male", "female"

  List<Client> _clients = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchClients();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── API calls ──────────────────────────────────────────────────────────────

  Future<void> _fetchClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('$kBaseUrl/api/pahae/clients/coach/${widget.coachID}');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['clients'] ?? [];
        setState(() {
          _clients = list.map((json) => Client.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load clients (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeClientFromCoach(Client client) async {
    try {
      final uri = Uri.parse(
          '$kBaseUrl/api/pahae/clients/${client.id}/coach/${widget.coachID}');
      final response = await http.delete(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() => _clients.removeWhere((c) => c.id == client.id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${client.name} removed from your clients.'),
              backgroundColor: const Color(0xFF1A1A1A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        _showError(data['error'] ?? 'Failed to remove client.');
      }
    } catch (e) {
      _showError('Network error. Could not remove client.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF4D4D),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  List<Client> get _filtered {
    return _clients.where((c) {
      final matchSearch = c.name.toLowerCase().contains(_query);
      final matchGender = _filterGender == null || c.gender == _filterGender;
      return matchSearch && matchGender;
    }).toList();
  }

  // ── Remove dialog ──────────────────────────────────────────────────────────

  void _confirmRemove(Client client) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove client',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove ${client.name} from your client list?',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeClientFromCoach(client);
            },
            child: const Text(
              'Remove',
              style: TextStyle(
                  color: Color(0xFFFF4D4D), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const Header(),
      body: _buildBody(),
      bottomNavigationBar: NavBarCoach(selectedIndex: 0),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kNeonGreen),
      );
    }

    if (_errorMessage != null) {
      return _buildNetworkError();
    }

    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildTitle(),
        const SizedBox(height: 16),
        _buildSearchBar(),
        const SizedBox(height: 12),
        _buildFilterChips(),
        const SizedBox(height: 16),
        _buildCount(filtered.length),
        const SizedBox(height: 10),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: kNeonGreen,
                  backgroundColor: const Color(0xFF1A1A1A),
                  onRefresh: _fetchClients,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _buildClientCard(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Network error ──────────────────────────────────────────────────────────

  Widget _buildNetworkError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_outlined,
                color: Colors.white.withOpacity(0.3), size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetchClients,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: kNeonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kNeonGreen.withOpacity(0.5)),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                      color: kNeonGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "MY CLIENTS",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          // Refresh button
          GestureDetector(
            onTap: _fetchClients,
            child: Icon(
              Icons.refresh_rounded,
              color: Colors.white.withOpacity(0.4),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          boxShadow: [
            BoxShadow(
              color: kNeonGreen.withOpacity(0.04),
              blurRadius: 16,
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by name…',
            hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
            prefixIcon: Icon(Icons.search,
                color: Colors.white.withOpacity(0.4), size: 20),
            suffixIcon: _query.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                    child: Icon(Icons.close,
                        color: Colors.white.withOpacity(0.4), size: 18),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Filter chips ───────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    final filters = <String, String?>{
      'ALL': null,
      '♂ MALE': "male",
      '♀ FEMALE': "female",
    };

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: filters.entries.map((e) {
          final selected = _filterGender == e.value;
          return GestureDetector(
            onTap: () => setState(() => _filterGender = e.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? kNeonGreen.withOpacity(0.15) : kDarkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? kNeonGreen.withOpacity(0.7)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                e.key,
                style: TextStyle(
                  color:
                      selected ? kNeonGreen : Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Count label ────────────────────────────────────────────────────────────

  Widget _buildCount(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(
        '$count client${count == 1 ? '' : 's'}',
        style: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Client card ────────────────────────────────────────────────────────────

  Widget _buildClientCard(Client client) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClientScreen(client: client)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.white.withOpacity(0.06), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _buildAvatar(client),
              const SizedBox(width: 14),
              Expanded(child: _buildInfo(client)),
              _buildRemoveButton(client),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Client client) {
    final isMale = client.gender.toLowerCase() == "male";
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: kNeonGreen.withOpacity(0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: kNeonGreen.withOpacity(0.12),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: (client.image.isNotEmpty)
                ? Image.network(
                    client.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(isMale),
                  )
                : _avatarFallback(isMale),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isMale
                  ? const Color(0xFF1A3A5C)
                  : const Color(0xFF5C1A3A),
              shape: BoxShape.circle,
              border: Border.all(color: kDarkCard, width: 1.5),
            ),
            child: Center(
              child: Text(
                isMale ? '♂' : '♀',
                style: TextStyle(
                  fontSize: 10,
                  color: isMale
                      ? const Color(0xFF5BB8FF)
                      : const Color(0xFFFF8FC8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback(bool isMale) {
    return Container(
      color: const Color(0xFF222222),
      child: Icon(
        isMale ? Icons.person : Icons.person_outline,
        color: Colors.white38,
        size: 28,
      ),
    );
  }

  Widget _buildInfo(Client client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          client.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildBadge(
              icon: Icons.cake_outlined,
              label: '${client.calculateAge()} years',
            ),
            const SizedBox(width: 8),
            _buildBadge(
              icon: client.gender.toLowerCase() == "male"
                  ? Icons.male_outlined
                  : Icons.female_outlined,
              label: client.gender.toLowerCase() == "male" ? 'Male' : 'Female',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.4), size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveButton(Client client) {
    return GestureDetector(
      onTap: () => _confirmRemove(client),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFFF4D4D).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFFF4D4D).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.person_remove_outlined,
          color: Color(0xFFFF4D4D),
          size: 16,
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    // If filtering/searching and nothing matches
    final isFiltering = _query.isNotEmpty || _filterGender != null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: kNeonGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline,
                color: kNeonGreen.withOpacity(0.5), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltering ? 'No clients found' : 'No clients yet',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltering
                ? 'Try adjusting your search or filters'
                : 'Your clients will appear here once assigned',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}