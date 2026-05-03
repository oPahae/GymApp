import 'package:flutter/material.dart';
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/models/bodyPart.dart';
import 'package:test_hh/models/exercice.dart';
import 'package:test_hh/screens/exercices.dart';

// ─── Mock Data ─────────────────────────────────────────────────────────────────

final List<BodyPartModel> kBodyParts = [
  BodyPartModel(
    id: 'bp1',
    name: 'Chest',
    imageUrl:
        'https://images.pexels.com/photos/3837781/pexels-photo-3837781.jpeg?auto=compress&cs=tinysrgb&w=400',
    exercices: [
      ExerciceModel(
        id: 'e1',
        name: 'Bench Press',
        description: 'A compound push exercise targeting the pectoral muscles.',
        image:
            'https://images.pexels.com/photos/3837781/pexels-photo-3837781.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp1', 'Chest'),
        type: ExerciceType.strength,
        notes: [],
      ),
      ExerciceModel(
        id: 'e2',
        name: 'Push-Up',
        description: 'Bodyweight exercise engaging chest, shoulders and triceps.',
        image:
            'https://images.pexels.com/photos/4162449/pexels-photo-4162449.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp1', 'Chest'),
        type: ExerciceType.strength,
        notes: [],
      ),
      ExerciceModel(
        id: 'e3',
        name: 'Cable Fly',
        description: 'Isolation exercise for inner and outer chest definition.',
        image:
            'https://images.pexels.com/photos/1552242/pexels-photo-1552242.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp1', 'Chest'),
        type: ExerciceType.strength,
        notes: [],
      ),
    ],
  ),
  BodyPartModel(
    id: 'bp2',
    name: 'Back',
    imageUrl:
        'https://images.pexels.com/photos/1431282/pexels-photo-1431282.jpeg?auto=compress&cs=tinysrgb&w=400',
    exercices: [
      ExerciceModel(
        id: 'e4',
        name: 'Pull-Up',
        description: 'Compound upper-body pull targeting lats and biceps.',
        image:
            'https://images.pexels.com/photos/1431282/pexels-photo-1431282.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp2', 'Back'),
        type: ExerciceType.strength,
        notes: [],
      ),
      ExerciceModel(
        id: 'e5',
        name: 'Barbell Row',
        description: 'Heavy compound movement for overall back thickness.',
        image:
            'https://images.pexels.com/photos/3837757/pexels-photo-3837757.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp2', 'Back'),
        type: ExerciceType.strength,
        notes: [],
      ),
    ],
  ),
  BodyPartModel(
    id: 'bp3',
    name: 'Legs',
    imageUrl:
        'https://images.pexels.com/photos/4162451/pexels-photo-4162451.jpeg?auto=compress&cs=tinysrgb&w=400',
    exercices: [
      ExerciceModel(
        id: 'e6',
        name: 'Squat',
        description: 'King of leg exercises — quads, hamstrings, glutes.',
        image:
            'https://images.pexels.com/photos/4162451/pexels-photo-4162451.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp3', 'Legs'),
        type: ExerciceType.strength,
        notes: [],
      ),
      ExerciceModel(
        id: 'e7',
        name: 'Leg Press',
        description: 'Machine-based quad and glute developer.',
        image:
            'https://images.pexels.com/photos/3837800/pexels-photo-3837800.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp3', 'Legs'),
        type: ExerciceType.strength,
        notes: [],
      ),
      ExerciceModel(
        id: 'e8',
        name: 'Romanian Deadlift',
        description: 'Hip-hinge movement targeting hamstrings and glutes.',
        image:
            'https://images.pexels.com/photos/1552252/pexels-photo-1552252.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp3', 'Legs'),
        type: ExerciceType.strength,
        notes: [],
      ),
    ],
  ),
  BodyPartModel(
    id: 'bp4',
    name: 'Shoulders',
    imageUrl:
        'https://images.pexels.com/photos/1552249/pexels-photo-1552249.jpeg?auto=compress&cs=tinysrgb&w=400',
    exercices: [
      ExerciceModel(
        id: 'e9',
        name: 'Overhead Press',
        description: 'Primary shoulder mass builder — front and lateral delts.',
        image:
            'https://images.pexels.com/photos/1552249/pexels-photo-1552249.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp4', 'Shoulders'),
        type: ExerciceType.strength,
        notes: [],
      ),
      ExerciceModel(
        id: 'e10',
        name: 'Lateral Raise',
        description: 'Isolation for the lateral deltoid head.',
        image:
            'https://images.pexels.com/photos/3837763/pexels-photo-3837763.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp4', 'Shoulders'),
        type: ExerciceType.strength,
        notes: [],
      ),
    ],
  ),
  BodyPartModel(
    id: 'bp5',
    name: 'Arms',
    imageUrl:
        'https://images.pexels.com/photos/3837761/pexels-photo-3837761.jpeg?auto=compress&cs=tinysrgb&w=400',
    exercices: [
      ExerciceModel(
        id: 'e11',
        name: 'Barbell Curl',
        description: 'Classic bicep mass builder with full range of motion.',
        image:
            'https://images.pexels.com/photos/3837761/pexels-photo-3837761.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp5', 'Arms'),
        type: ExerciceType.strength,
        notes: [],
      ),
      ExerciceModel(
        id: 'e12',
        name: 'Tricep Dip',
        description: 'Compound tricep exercise using bodyweight.',
        image:
            'https://images.pexels.com/photos/4162455/pexels-photo-4162455.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp5', 'Arms'),
        type: ExerciceType.strength,
        notes: [],
      ),
    ],
  ),
  BodyPartModel(
    id: 'bp6',
    name: 'Core',
    imageUrl:
        'https://images.pexels.com/photos/3823039/pexels-photo-3823039.jpeg?auto=compress&cs=tinysrgb&w=400',
    exercices: [
      ExerciceModel(
        id: 'e13',
        name: 'Plank',
        description: 'Isometric core stabiliser — full mid-section activation.',
        image:
            'https://images.pexels.com/photos/3823039/pexels-photo-3823039.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp6', 'Core'),
        type: ExerciceType.strength,
        notes: [],
      ),
      ExerciceModel(
        id: 'e14',
        name: 'Cable Crunch',
        description: 'Weighted crunch for upper abdominal hypertrophy.',
        image:
            'https://images.pexels.com/photos/1547248/pexels-photo-1547248.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp6', 'Core'),
        type: ExerciceType.strength,
        notes: [],
      ),
    ],
  ),
  BodyPartModel(
    id: 'bp7',
    name: 'Cardio',
    imageUrl:
        'https://images.pexels.com/photos/936094/pexels-photo-936094.jpeg?auto=compress&cs=tinysrgb&w=400',
    exercices: [
      ExerciceModel(
        id: 'e15',
        name: 'Treadmill Run',
        description: 'Steady-state or interval running for cardiovascular health.',
        image:
            'https://images.pexels.com/photos/936094/pexels-photo-936094.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp7', 'Cardio'),
        type: ExerciceType.cardio,
        notes: [],
      ),
      ExerciceModel(
        id: 'e16',
        name: 'Jump Rope',
        description: 'High-intensity cardio improving coordination and stamina.',
        image:
            'https://images.pexels.com/photos/4164761/pexels-photo-4164761.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp7', 'Cardio'),
        type: ExerciceType.cardio,
        notes: [],
      ),
    ],
  ),
  BodyPartModel(
    id: 'bp8',
    name: 'Flexibility',
    imageUrl:
        'https://images.pexels.com/photos/317157/pexels-photo-317157.jpeg?auto=compress&cs=tinysrgb&w=400',
    exercices: [
      ExerciceModel(
        id: 'e17',
        name: 'Hip Flexor Stretch',
        description: 'Deep lunge stretch releasing tight hip flexors.',
        image:
            'https://images.pexels.com/photos/317157/pexels-photo-317157.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp8', 'Flexibility'),
        type: ExerciceType.flexibility,
        notes: [],
      ),
      ExerciceModel(
        id: 'e18',
        name: 'Seated Hamstring Stretch',
        description: 'Static stretch improving posterior chain flexibility.',
        image:
            'https://images.pexels.com/photos/4056535/pexels-photo-4056535.jpeg?auto=compress&cs=tinysrgb&w=400',
        video: '',
        part: _placeholderPart('bp8', 'Flexibility'),
        type: ExerciceType.flexibility,
        notes: [],
      ),
    ],
  ),
];

// Helper to avoid circular const dependency in mock data
BodyPartModel _placeholderPart(String id, String name) => BodyPartModel(
      id: id,
      name: name,
      imageUrl: '',
      exercices: [],
    );

// ─── Screen ────────────────────────────────────────────────────────────────────

class BodyPartsScreen extends StatefulWidget {
  const BodyPartsScreen({super.key});

  @override
  State<BodyPartsScreen> createState() => _BodyPartsScreenState();
}

class _BodyPartsScreenState extends State<BodyPartsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BodyPartModel> get _filtered => kBodyParts
      .where((b) => b.name.toLowerCase().contains(_searchQuery))
      .toList();

  @override
  Widget build(BuildContext context) {
    final parts = _filtered;
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: Header(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildSearchBar(),
            const SizedBox(height: 14),
            Expanded(
              child: parts.isEmpty
                  ? _buildEmpty()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: parts.length,
                      itemBuilder: (_, i) => _buildBodyPartCard(parts[i]),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(),
    );
  }

  // ─── TOP BAR ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: kDarkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'BODY PARTS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kNeonGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kNeonGreen.withOpacity(0.3)),
            ),
            child: Text(
              '${kBodyParts.length} GROUPS',
              style: const TextStyle(
                color: kNeonGreen,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEARCH BAR ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search muscle group...',
            hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
            prefixIcon: Icon(Icons.search,
                color: Colors.white.withOpacity(0.3), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: Icon(Icons.close,
                        color: Colors.white.withOpacity(0.3), size: 18),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ─── BODY PART CARD ─────────────────────────────────────────────────────────

  Widget _buildBodyPartCard(BodyPartModel part) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExercicesScreen(bodyPart: part),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.network(
              part.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1A1A1A),
                child:
                    const Icon(Icons.fitness_center, color: Colors.white12, size: 40),
              ),
            ),
            // Dark gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.88),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercises count badge (top-right)
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        '${part.exercices.length} exercises',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Name
                  Text(
                    part.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Arrow row
                  Row(
                    children: [
                      Text(
                        'EXPLORE',
                        style: TextStyle(
                          color: kNeonGreen.withOpacity(0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          color: kNeonGreen.withOpacity(0.85), size: 10),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── EMPTY STATE ────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                color: Colors.white.withOpacity(0.12), size: 52),
            const SizedBox(height: 12),
            Text(
              'No results found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.28),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}