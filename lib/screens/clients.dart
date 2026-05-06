// import 'package:flutter/material.dart';
// import 'package:test_hh/components/header.dart';
// import 'package:test_hh/components/navbar.dart';
// import 'package:test_hh/constants/colors.dart';
// import 'package:test_hh/models/client.dart';

// // ── Sample data ─────────────────────────────────────────────────────────────
// final List<Client> _allClients = [
//   Client(
//     id: 1,
//     name: 'Lucas Martin',
//     image: 'https://randomuser.me/api/portraits/men/32.jpg',
//     gender: "male",
//     birth: DateTime(1995, 4, 12),
//     weight: 10, height: 10, frequency: 10, goal: '', weightGoal: 10, createdAt: new DateTime.now(), coachID: 10, email: '', password: '',
//   ),
//   Client(
//     id: 1,
//     name: 'Emma Dupont',
//     image: 'https://randomuser.me/api/portraits/women/44.jpg',
//     gender: "female",
//     birth: DateTime(1999, 8, 22),
//     weight: 10, height: 10, frequency: 10, goal: '', weightGoal: 10, createdAt: new DateTime.now(), coachID: 10, email: '', password: '',
//   ),
//   Client(
//     id: 1,
//     name: 'Noah Bernard',
//     image: 'https://randomuser.me/api/portraits/men/56.jpg',
//     gender: "male",
//     birth: DateTime(1990, 1, 5),
//     weight: 10, height: 10, frequency: 10, goal: '', weightGoal: 10, createdAt: new DateTime.now(), coachID: 10, email: '', password: '',
//   ),
//   Client(
//     id: 1,
//     name: 'Chloé Leroy',
//     image: 'https://randomuser.me/api/portraits/women/68.jpg',
//     gender: "female",
//     birth: DateTime(2001, 11, 30),
//     weight: 10, height: 10, frequency: 10, goal: '', weightGoal: 10, createdAt: new DateTime.now(), coachID: 10, email: '', password: '',
//   ),
//   Client(
//     id: 1,
//     name: 'Ethan Moreau',
//     image: 'https://randomuser.me/api/portraits/men/77.jpg',
//     gender: "male",
//     birth: DateTime(1988, 7, 17),
//     weight: 10, height: 10, frequency: 10, goal: '', weightGoal: 10, createdAt: new DateTime.now(), coachID: 10, email: '', password: '',
//   ),
//   Client(
//     id: 1,
//     name: 'Léa Simon',
//     image: 'https://randomuser.me/api/portraits/women/12.jpg',
//     gender: "female",
//     birth: DateTime(1997, 3, 8),
//     weight: 10, height: 10, frequency: 10, goal: '', weightGoal: 10, createdAt: new DateTime.now(), coachID: 10, email: '', password: '',
//   ),
//   Client(
//     id: 1,
//     name: 'Hugo Laurent',
//     image: 'https://randomuser.me/api/portraits/men/90.jpg',
//     gender: "male",
//     birth: DateTime(2000, 6, 25),
//     weight: 10, height: 10, frequency: 10, goal: '', weightGoal: 10, createdAt: new DateTime.now(), coachID: 10, email: '', password: '',
//   ),
//   Client(
//     id: 1,
//     name: 'Camille Petit',
//     image: 'https://randomuser.me/api/portraits/women/35.jpg',
//     gender: "female",
//     birth: DateTime(1993, 9, 14),
//     weight: 10, height: 10, frequency: 10, goal: '', weightGoal: 10, createdAt: new DateTime.now(), coachID: 10, email: '', password: '',
//   ),
// ];

// // ── Screen ──────────────────────────────────────────────────────────────────
// class ClientsScreen extends StatefulWidget {
//   const ClientsScreen({super.key});

//   @override
//   State<ClientsScreen> createState() => _ClientsScreenState();
// }

// class _ClientsScreenState extends State<ClientsScreen> {
//   final TextEditingController _searchCtrl = TextEditingController();
//   String _query = '';
//   // null = all, "male", "female"
//   String? _filterGender;

//   late List<Client> _clients;

//   @override
//   void initState() {
//     super.initState();
//     _clients = List.from(_allClients);
//     _searchCtrl.addListener(() {
//       setState(() => _query = _searchCtrl.text.toLowerCase());
//     });
//   }

//   @override
//   void dispose() {
//     _searchCtrl.dispose();
//     super.dispose();
//   }

//   List<Client> get _filtered {
//     return _clients.where((c) {
//       final matchSearch = c.name.toLowerCase().contains(_query);
//       final matchGender =
//           _filterGender == null || c.gender == _filterGender;
//       return matchSearch && matchGender;
//     }).toList();
//   }

//   void _removeClient(Client client) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: const Color(0xFF1A1A1A),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text('Remove client',
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
//         content: Text(
//           'Remove ${client.name} from your client list?',
//           style: TextStyle(color: Colors.white.withOpacity(0.6)),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child:
//                 Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
//           ),
//           TextButton(
//             onPressed: () {
//               setState(() => _clients.remove(client));
//               Navigator.pop(context);
//             },
//             child: const Text('Remove',
//                 style: TextStyle(color: Color(0xFFFF4D4D), fontWeight: FontWeight.w700)),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filtered = _filtered;

//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: const Header(),
//       body: Stack(
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 20),
//               _buildTitle(),
//               const SizedBox(height: 16),
//               _buildSearchBar(),
//               const SizedBox(height: 12),
//               _buildFilterChips(),
//               const SizedBox(height: 16),
//               _buildCount(filtered.length),
//               const SizedBox(height: 10),
//               Expanded(
//                 child: filtered.isEmpty
//                     ? _buildEmpty()
//                     : ListView.separated(
//                         padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
//                         itemCount: filtered.length,
//                         separatorBuilder: (_, __) => const SizedBox(height: 12),
//                         itemBuilder: (_, i) => _buildClientCard(filtered[i]),
//                       ),
//               ),
//             ],
//           ),
//         ],
//       ),
//       bottomNavigationBar: NavBar(),
//     );
//   }

//   // ── Section title ──────────────────────────────────────────────────────────
//   Widget _buildTitle() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 18),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Text(
//             "MY CLIENTS",
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 15,
//               fontWeight: FontWeight.w800,
//               letterSpacing: 1.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Search bar ─────────────────────────────────────────────────────────────
//   Widget _buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 18),
//       child: Container(
//         decoration: BoxDecoration(
//           color: kDarkCard,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
//           boxShadow: [
//             BoxShadow(
//               color: kNeonGreen.withOpacity(0.04),
//               blurRadius: 16,
//             ),
//           ],
//         ),
//         child: TextField(
//           controller: _searchCtrl,
//           style: const TextStyle(color: Colors.white, fontSize: 14),
//           decoration: InputDecoration(
//             hintText: 'Search by name or ID…',
//             hintStyle: TextStyle(
//                 color: Colors.white.withOpacity(0.3), fontSize: 14),
//             prefixIcon:
//                 Icon(Icons.search, color: Colors.white.withOpacity(0.4), size: 20),
//             suffixIcon: _query.isNotEmpty
//                 ? GestureDetector(
//                     onTap: () {
//                       _searchCtrl.clear();
//                       setState(() => _query = '');
//                     },
//                     child: Icon(Icons.close,
//                         color: Colors.white.withOpacity(0.4), size: 18),
//                   )
//                 : null,
//             border: InputBorder.none,
//             contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Filter chips ───────────────────────────────────────────────────────────
//   Widget _buildFilterChips() {
//     final filters = <String, String?>{
//       'ALL': null,
//       '♂ MALE': "male",
//       '♀ FEMALE': "female",
//     };

//     return SizedBox(
//       height: 34,
//       child: ListView(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 18),
//         children: filters.entries.map((e) {
//           final selected = _filterGender == e.value;
//           return GestureDetector(
//             onTap: () => setState(() => _filterGender = e.value),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               margin: const EdgeInsets.only(right: 8),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               decoration: BoxDecoration(
//                 color: selected ? kNeonGreen.withOpacity(0.15) : kDarkCard,
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(
//                   color: selected
//                       ? kNeonGreen.withOpacity(0.7)
//                       : Colors.white.withOpacity(0.1),
//                   width: 1,
//                 ),
//               ),
//               alignment: Alignment.center,
//               child: Text(
//                 e.key,
//                 style: TextStyle(
//                   color: selected ? kNeonGreen : Colors.white.withOpacity(0.5),
//                   fontSize: 11,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 0.8,
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   // ── Count label ────────────────────────────────────────────────────────────
//   Widget _buildCount(int count) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 18),
//       child: Text(
//         '$count client${count == 1 ? '' : 's'}',
//         style: TextStyle(
//           color: Colors.white.withOpacity(0.35),
//           fontSize: 12,
//           fontWeight: FontWeight.w500,
//           letterSpacing: 0.5,
//         ),
//       ),
//     );
//   }

//   // ── Client card ────────────────────────────────────────────────────────────
//   Widget _buildClientCard(Client client) {
//     return GestureDetector(
//       onTap: () {
//         // Navigator.push(
//         //   context,
//         //   MaterialPageRoute(builder: (_) => ClientScreen(client: client)),
//         // );
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: kDarkCard,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.4),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(14),
//           child: Row(
//             children: [
//               // Avatar
//               _buildAvatar(client),
//               const SizedBox(width: 14),
//               // Info
//               Expanded(child: _buildInfo(client)),
//               // Remove button
//               _buildRemoveButton(client),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAvatar(Client client) {
//     return Stack(
//       children: [
//         Container(
//           width: 60,
//           height: 60,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             border: Border.all(color: kNeonGreen.withOpacity(0.4), width: 2),
//             boxShadow: [
//               BoxShadow(
//                 color: kNeonGreen.withOpacity(0.12),
//                 blurRadius: 12,
//                 spreadRadius: 1,
//               ),
//             ],
//           ),
//           child: ClipOval(
//             child: Image.network(
//               client.image,
//               fit: BoxFit.cover,
//               errorBuilder: (_, __, ___) => Container(
//                 color: const Color(0xFF222222),
//                 child: Icon(
//                   client.gender == "male"
//                       ? Icons.person
//                       : Icons.person_outline,
//                   color: Colors.white38,
//                   size: 28,
//                 ),
//               ),
//             ),
//           ),
//         ),
//         // Gender badge
//         Positioned(
//           bottom: 0,
//           right: 0,
//           child: Container(
//             width: 20,
//             height: 20,
//             decoration: BoxDecoration(
//               color: client.gender == "male"
//                   ? const Color(0xFF1A3A5C)
//                   : const Color(0xFF5C1A3A),
//               shape: BoxShape.circle,
//               border: Border.all(color: kDarkCard, width: 1.5),
//             ),
//             child: Center(
//               child: Text(
//                 client.gender == "male" ? '♂' : '♀',
//                 style: TextStyle(
//                   fontSize: 10,
//                   color: client.gender == "male"
//                       ? const Color(0xFF5BB8FF)
//                       : const Color(0xFFFF8FC8),
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInfo(Client client) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           client.name,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 14,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           "${client.id}",
//           style: TextStyle(
//             color: kNeonGreen.withOpacity(0.8),
//             fontSize: 11,
//             fontWeight: FontWeight.w600,
//             letterSpacing: 0.5,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             _buildBadge(
//               icon: Icons.cake_outlined,
//               label: '${client.age} years',
//             ),
//             const SizedBox(width: 8),
//             _buildBadge(
//               icon: client.gender == "male"
//                   ? Icons.male_outlined
//                   : Icons.female_outlined,
//               label: client.gender == "male" ? 'Male' : 'Female',
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildBadge({required IconData icon, required String label}) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.06),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: Colors.white.withOpacity(0.4), size: 11),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.55),
//               fontSize: 10,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRemoveButton(Client client) {
//     return GestureDetector(
//       onTap: () => _removeClient(client),
//       child: Container(
//         width: 36,
//         height: 36,
//         decoration: BoxDecoration(
//           color: const Color(0xFFFF4D4D).withOpacity(0.1),
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: const Color(0xFFFF4D4D).withOpacity(0.3),
//             width: 1,
//           ),
//         ),
//         child: const Icon(
//           Icons.person_remove_outlined,
//           color: Color(0xFFFF4D4D),
//           size: 16,
//         ),
//       ),
//     );
//   }

//   // ── Empty state ────────────────────────────────────────────────────────────
//   Widget _buildEmpty() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 70,
//             height: 70,
//             decoration: BoxDecoration(
//               color: kNeonGreen.withOpacity(0.08),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(Icons.people_outline,
//                 color: kNeonGreen.withOpacity(0.5), size: 32),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'No clients found',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 15,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             'Try adjusting your search or filters',
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.4),
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
