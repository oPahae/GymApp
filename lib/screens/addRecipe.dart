import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/models/food.dart';
import 'package:test_hh/models/recipeIngredient.dart';

// ─── Mock ingredient catalogue ───────────────────────────────────────────────
final List<FoodModel> kCatalogue = [
  const FoodModel(
    id: '1',
    name: 'Oatmeal',
    imageUrl: 'https://images.pexels.com/photos/704971/pexels-photo-704971.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 389,
    type: FoodType.solid,
  ),
  const FoodModel(
    id: '2',
    name: 'Almond Milk',
    imageUrl: 'https://images.pexels.com/photos/3735218/pexels-photo-3735218.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 17,
    type: FoodType.liquid,
  ),
  const FoodModel(
    id: '3',
    name: 'Chicken Breast',
    imageUrl: 'https://images.pexels.com/photos/2338407/pexels-photo-2338407.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 165,
    type: FoodType.solid,
  ),
  const FoodModel(
    id: '4',
    name: 'Whey Protein',
    imageUrl: 'https://images.pexels.com/photos/4162493/pexels-photo-4162493.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 400,
    type: FoodType.grains,
  ),
  const FoodModel(
    id: '5',
    name: 'Banana',
    imageUrl: 'https://images.pexels.com/photos/1093038/pexels-photo-1093038.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 89,
    type: FoodType.unit,
  ),
  const FoodModel(
    id: '6',
    name: 'Greek Yogurt',
    imageUrl: 'https://images.pexels.com/photos/1132047/pexels-photo-1132047.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 59,
    type: FoodType.solid,
  ),
  const FoodModel(
    id: '7',
    name: 'Orange Juice',
    imageUrl: 'https://images.pexels.com/photos/158053/fresh-orange-juice-squeezed-158053.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 45,
    type: FoodType.liquid,
  ),
  const FoodModel(
    id: '8',
    name: 'Quinoa',
    imageUrl: 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 120,
    type: FoodType.solid,
  ),
  const FoodModel(
    id: '9',
    name: 'Salmon',
    imageUrl: 'https://images.pexels.com/photos/3763847/pexels-photo-3763847.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 208,
    type: FoodType.solid,
  ),
  const FoodModel(
    id: '10',
    name: 'Egg',
    imageUrl: 'https://images.pexels.com/photos/824635/pexels-photo-824635.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 78,
    type: FoodType.unit,
  ),
  const FoodModel(
    id: '11',
    name: 'Green Tea',
    imageUrl: 'https://images.pexels.com/photos/1417945/pexels-photo-1417945.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 2,
    type: FoodType.liquid,
  ),
  const FoodModel(
    id: '12',
    name: 'Avocado',
    imageUrl: 'https://images.pexels.com/photos/557659/pexels-photo-557659.jpeg?auto=compress&cs=tinysrgb&w=200',
    calories: 160,
    type: FoodType.solid,
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen>
    with SingleTickerProviderStateMixin {
  // Form state
  final _nameController = TextEditingController();
  File? _pickedImage;

  // Ingredients chosen for the recipe
  final List<RecipeIngredientModel> _entries = [];

  // Search for the picker sheet
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Tab: 0 = ingredient picker, 1 = summary
  late TabController _tabController;

  double get _totalCalories =>
      _entries.fold(0.0, (s, e) => s + e.contributedCalories);

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _entries.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController.addListener(() => setState(() {}));
    _searchController.addListener(
        () => setState(() => _searchQuery = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────────

  bool _isAdded(FoodModel f) => _entries.any((e) => e.food.id == f.id);

  void _toggleFood(FoodModel f) {
    setState(() {
      if (_isAdded(f)) {
        _entries.removeWhere((e) => e.food.id == f.id);
      } else {
        _entries.add(RecipeIngredientModel(food: f));
      }
    });
  }

  void _removeEntry(RecipeIngredientModel entry) {
    setState(() => _entries.removeWhere((e) => e.food.id == entry.food.id));
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) setState(() => _pickedImage = File(xfile.path));
  }

  List<FoodModel> get _filteredCatalogue => kCatalogue
      .where((f) => f.name.toLowerCase().contains(_searchQuery))
      .toList();

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    _buildImageAndNameSection(),
                    const SizedBox(height: 20),
                    _buildLiveRecipeSummary(),
                    const SizedBox(height: 22),
                    _buildIngredientPickerSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _canSave ? _buildSaveFAB() : null,
    );
  }

  // ─── TOP BAR ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
              'NEW RECIPE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          // Ingredient count badge
          if (_entries.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kDarkCard,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: kNeonGreen.withOpacity(0.4), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu,
                      color: kNeonGreen, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    '${_entries.length} items',
                    style: const TextStyle(
                      color: kNeonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── IMAGE + NAME ────────────────────────────────────────────────────────────

  Widget _buildImageAndNameSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: kDarkCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: kNeonGreen.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: _pickedImage != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_pickedImage!, fit: BoxFit.cover),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit,
                                color: kNeonGreen, size: 12),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: kNeonGreen.withOpacity(0.7), size: 26),
                        const SizedBox(height: 5),
                        Text(
                          'ADD\nIMAGE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kNeonGreen.withOpacity(0.6),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Name field + macro hint
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: kDarkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _nameController.text.isNotEmpty
                          ? kNeonGreen.withOpacity(0.4)
                          : Colors.white10,
                    ),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Recipe name…',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.25),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Quick calorie pill
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _entries.isEmpty
                      ? Text(
                          'Add ingredients below',
                          key: const ValueKey('hint'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                            fontSize: 12,
                          ),
                        )
                      : Row(
                          key: const ValueKey('cals'),
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: kNeonGreen, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              '${_totalCalories.toInt()} kcal total',
                              style: const TextStyle(
                                color: kNeonGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '  ·  ${_entries.length} ingredient${_entries.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── LIVE RECIPE SUMMARY ────────────────────────────────────────────────────

  Widget _buildLiveRecipeSummary() {
    if (_entries.isEmpty) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Container(
          decoration: BoxDecoration(
            color: kDarkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Text(
                      'RECIPE SUMMARY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    // Total calories pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kNeonGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: kNeonGreen.withOpacity(0.35), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department,
                              color: kNeonGreen, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${_totalCalories.toInt()} kcal',
                            style: const TextStyle(
                              color: kNeonGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              // Recipe name preview with image
              Padding(
                padding: const EdgeInsets.all(14),
                child: _buildRecipePreviewCard(),
              ),
              // Ingredient rows
              ..._entries.map((entry) => _buildSummaryIngredientRow(entry)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipePreviewCard() {
    final hasName = _nameController.text.trim().isNotEmpty;
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background: picked image or first ingredient image
          if (_pickedImage != null)
            Image.file(_pickedImage!, fit: BoxFit.cover)
          else if (_entries.isNotEmpty)
            Image.network(
              _entries.first.food.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF1A1A1A)),
            ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.78),
                ],
              ),
            ),
          ),
          // Text
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  hasName ? _nameController.text : 'Unnamed Recipe',
                  style: TextStyle(
                    color:
                        hasName ? Colors.white : Colors.white.withOpacity(0.3),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontStyle:
                        hasName ? FontStyle.normal : FontStyle.italic,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 6)
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_entries.length} ingredient${_entries.length > 1 ? 's' : ''}  ·  ${_totalCalories.toInt()} kcal',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryIngredientRow(RecipeIngredientModel entry) {
    return Column(
      children: [
        const Divider(height: 1, color: Colors.white10, indent: 14),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  entry.food.imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 40,
                    height: 40,
                    color: Colors.white10,
                    child: const Icon(Icons.fastfood,
                        color: Colors.white24, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + calories
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.food.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${entry.contributedCalories.toInt()} kcal',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Quantity stepper
              _buildQuantityStepper(entry),
              const SizedBox(width: 8),
              // Remove
              GestureDetector(
                onTap: () => _removeEntry(entry),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.close,
                      color: Colors.red.withOpacity(0.7), size: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityStepper(RecipeIngredientModel entry) {
    final step = entry.food.type == FoodType.unit ? 1.0 : 10.0;
    final min = entry.food.type == FoodType.unit ? 1.0 : 10.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepperBtn(
          icon: Icons.remove,
          onTap: () {
            setState(() {
              if (entry.quantity > min) entry.quantity -= step;
            });
          },
        ),
        Container(
          width: 52,
          alignment: Alignment.center,
          child: Text(
            entry.quantityLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _stepperBtn(
          icon: Icons.add,
          onTap: () => setState(() => entry.quantity += step),
          isPlus: true,
        ),
      ],
    );
  }

  Widget _stepperBtn(
      {required IconData icon,
      required VoidCallback onTap,
      bool isPlus = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isPlus
              ? kNeonGreen.withOpacity(0.12)
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(7),
          border: isPlus
              ? Border.all(color: kNeonGreen.withOpacity(0.35), width: 1)
              : null,
        ),
        child: Icon(icon,
            color: isPlus ? kNeonGreen : Colors.white.withOpacity(0.6),
            size: 14),
      ),
    );
  }

  // ─── INGREDIENT PICKER ──────────────────────────────────────────────────────

  Widget _buildIngredientPickerSection() {
    final catalogue = _filteredCatalogue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Text(
                'INGREDIENTS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${_entries.length} selected',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search
          Container(
            decoration: BoxDecoration(
              color: kDarkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search ingredients…',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.28), fontSize: 13),
                prefixIcon: Icon(Icons.search,
                    color: Colors.white.withOpacity(0.28), size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: Icon(Icons.close,
                            color: Colors.white.withOpacity(0.28), size: 16),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // List
          if (catalogue.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  'No ingredients found',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.25), fontSize: 13),
                ),
              ),
            )
          else
            ...catalogue.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCatalogueRow(f),
                )),
        ],
      ),
    );
  }

  Widget _buildCatalogueRow(FoodModel food) {
    final added = _isAdded(food);
    return GestureDetector(
      onTap: () => _toggleFood(food),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: added
              ? kNeonGreen.withOpacity(0.07)
              : kDarkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: added
                ? kNeonGreen.withOpacity(0.4)
                : Colors.white.withOpacity(0.07),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14)),
              child: SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      food.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1A1A1A),
                        child: const Icon(Icons.fastfood,
                            color: Colors.white24, size: 20),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            (added ? kNeonGreen.withOpacity(0.07) : kDarkCard)
                                .withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Name + cal label
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildTypeChip(food.typeLabel,
                            highlighted: added),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      food.name,
                      style: TextStyle(
                        color: added ? Colors.white : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      food.calLabel,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.38),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Toggle button
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: added
                      ? kNeonGreen
                      : kNeonGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: kNeonGreen.withOpacity(added ? 1 : 0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  added ? Icons.check : Icons.add,
                  color: added ? Colors.black : kNeonGreen,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SAVE FAB ────────────────────────────────────────────────────────────────

  Widget _buildSaveFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          // Build the recipe object and return/save it
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: kNeonGreen,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kNeonGreen.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.save_alt_rounded,
                  color: Colors.black, size: 20),
              const SizedBox(width: 8),
              const Text(
                'SAVE RECIPE',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Shared helpers ──────────────────────────────────────────────────────────

  Widget _buildTypeChip(String label, {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: kNeonGreen.withOpacity(highlighted ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
            color: kNeonGreen.withOpacity(highlighted ? 0.5 : 0.2), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: kNeonGreen,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
