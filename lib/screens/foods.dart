import 'package:flutter/material.dart';
import 'package:test_hh/components/header.dart';
import 'package:test_hh/components/navbar.dart';
import 'package:test_hh/screens/addRecipe.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/constants/urls.dart';
import 'package:test_hh/models/food.dart';
import 'package:test_hh/models/recipe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─── Screen ────────────────────────────────────────────────────────────────────

class FoodsScreen extends StatefulWidget {
  const FoodsScreen({super.key});

  @override
  State<FoodsScreen> createState() => _FoodsScreenState();
}

class _FoodsScreenState extends State<FoodsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Cart: id -> quantity
  final Map<String, int> _cart = {};

  // Data from API
  List<FoodModel> _allFoods = [];
  List<FoodModel> _recentFoods = [];
  List<RecipeModel> _recipes = [];
  bool _isLoadingFoods = true;
  bool _isLoadingRecipes = true;
  bool _hasErrorFoods = false;
  bool _hasErrorRecipes = false;

  // Mock clientID (à remplacer par la valeur réelle plus tard)
  final int kClientID = 1;

  int get _cartTotal => _cart.values.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFoods();
    _fetchRecipes();
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() {
        _searchQuery = '';
        _searchController.clear();
      });
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── API Calls ───────────────────────────────────────────────────────────────

  Future<void> _fetchFoods() async {
    setState(() {
      _isLoadingFoods = true;
      _hasErrorFoods = false;
    });
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/pahae/addFood/ingredients'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> foodsData = data['data'];
          setState(() {
            _allFoods = foodsData
                .map((food) => FoodModel.fromJson(food))
                .toList();
            _recentFoods = _allFoods.take(6).toList(); // Mock recent foods (à adapter si l'API retourne les "recents")
          });
        } else {
          setState(() => _hasErrorFoods = true);
        }
      } else {
        setState(() => _hasErrorFoods = true);
      }
    } catch (e) {
      setState(() => _hasErrorFoods = true);
    } finally {
      setState(() => _isLoadingFoods = false);
    }
  }

  Future<void> _fetchRecipes() async {
    setState(() {
      _isLoadingRecipes = true;
      _hasErrorRecipes = false;
    });
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/pahae/addFood/recipes/$kClientID'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> recipesData = data['data'];
          setState(() {
            _recipes = recipesData
                .map((recipe) => RecipeModel.fromJson(recipe))
                .toList();
          });
        } else {
          setState(() => _hasErrorRecipes = true);
        }
      } else {
        setState(() => _hasErrorRecipes = true);
      }
    } catch (e) {
      setState(() => _hasErrorRecipes = true);
    } finally {
      setState(() => _isLoadingRecipes = false);
    }
  }

  // ─── Filtered Lists ─────────────────────────────────────────────────────────

  List<FoodModel> get _filteredFoods =>
      _allFoods.where((f) => f.name.toLowerCase().contains(_searchQuery)).toList();

  List<RecipeModel> get _filteredRecipes =>
      _recipes.where((r) => r.name.toLowerCase().contains(_searchQuery)).toList();

  // ─── Build Methods ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,

      appBar: const Header(),

      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _isLoadingFoods
                      ? _buildLoading()
                      : _hasErrorFoods
                          ? _buildError("Failed to load foods")
                          : _buildFoodList(),
                  _isLoadingRecipes
                      ? _buildLoading()
                      : _hasErrorRecipes
                          ? _buildError("Failed to load recipes")
                          : _buildRecipeList(),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: _cartTotal > 0 ? _buildCartFAB() : null,

      bottomNavigationBar: NavBar(selectedIndex: 1),
    );
  }

  // ─── TOP BAR ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => {
              if (Navigator.canPop(context)) {Navigator.pop(context)}
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
              'FOODS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          // Live cart badge
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _cartTotal > 0
                ? Container(
                    key: const ValueKey('badge'),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kNeonGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_basket_outlined,
                            color: Colors.black, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          '$_cartTotal',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
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
            hintText: 'Search...',
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

  // ─── TAB BAR ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: kNeonGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white.withOpacity(0.45),
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
          tabs: const [
            Tab(text: 'FOODS'),
            Tab(text: 'RECIPES'),
          ],
        ),
      ),
    );
  }

  // ─── FOODS TAB ────────────────────────────────────────────────────────────
  Widget _buildFoodList() {
    final foods = _filteredFoods;
    if (foods.isEmpty) return _buildEmpty();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      itemCount: foods.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildFoodCard(foods[i]),
      ),
    );
  }

  // ─── RECIPES TAB ───────────────────────────────────────────────────────────
  Widget _buildRecipeList() {
    final recipes = _filteredRecipes;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      children: [
        // Add Recipe CTA
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kNeonGreen, width: 1.5),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: kNeonGreen, size: 18),
                SizedBox(width: 8),
                Text(
                  'CREATE NEW RECIPE',
                  style: TextStyle(
                    color: kNeonGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (recipes.isEmpty)
          _buildEmpty()
        else
          ...recipes.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRecipeCard(r),
            ),
          ),
      ],
    );
  }

  // ─── Food Card ───────────────────────────────────────────────────────────────
  Widget _buildFoodCard(FoodModel food) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _cart[food.id] = (_cart[food.id] ?? 0) + 1;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            // Thumbnail with right-gradient fade
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    food.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.fastfood,
                          color: Colors.white24, size: 24),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          kDarkCard.withOpacity(0.65),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeChip(food.typeLabel),
                    const SizedBox(height: 5),
                    Text(
                      food.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      food.calLabel,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Recipe Card ─────────────────────────────────────────────────────────────
  Widget _buildRecipeCard(RecipeModel recipe) {
    return Container(
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Header image
          GestureDetector(
            onTap: () =>
                setState(() => recipe.isExpanded = !recipe.isExpanded),
            child: SizedBox(
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF1A1A1A)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.82),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                recipe.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black87, blurRadius: 8)
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.local_fire_department,
                                      color: kNeonGreen, size: 12),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${recipe.calories.toInt()} kcal',
                                    style: const TextStyle(
                                      color: kNeonGreen,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '  ·  ${recipe.ingredients.length} ingredients',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          recipe.isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.white.withOpacity(0.55),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable ingredients
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: recipe.isExpanded
                ? Column(
                    children: [
                      const Divider(height: 1, color: Colors.white10),
                      ...recipe.ingredients.map(
                        (ing) => Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      ing.imageUrl,
                                      width: 42,
                                      height: 42,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 42,
                                        height: 42,
                                        color: Colors.white10,
                                        child: const Icon(Icons.fastfood,
                                            color: Colors.white24, size: 18),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ing.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          ing.calLabel,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.35),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildTypeChip(ing.typeLabel),
                                ],
                              ),
                            ),
                            if (ing != recipe.ingredients.last)
                              const Divider(
                                  height: 1,
                                  color: Colors.white10,
                                  indent: 68),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─── Shared Widgets ────────────────────────────────────────────────────────
  Widget _buildTypeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: kNeonGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kNeonGreen.withOpacity(0.22), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: kNeonGreen,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

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

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: kNeonGreen),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                color: Colors.red.withOpacity(0.5), size: 52),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.red.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_tabController.index == 0) {
                  _fetchFoods();
                } else {
                  _fetchRecipes();
                }
              },
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
      ),
    );
  }

  Widget _buildCartFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          // Confirm and add to meal
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
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Text(
                'ADD $_cartTotal ITEM${_cartTotal > 1 ? 'S' : ''} TO MEAL',
                style: const TextStyle(
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
}