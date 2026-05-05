import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_hh/screens/addRecipe.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/constants/urls.dart';
import 'package:test_hh/models/food.dart';
import 'package:test_hh/models/recipe.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
// localhost ne fonctionne pas depuis un émulateur/device physique.
// - Émulateur Android  → 10.0.2.2
// - Device physique    → l'IP locale de ton PC (ex: 192.168.1.42)
// - iOS Simulator      → localhost fonctionne
// - Web (kIsWeb)       → localhost fonctionne

const int kClientID = 1;
const String kMealtime = 'breakfast'; // breakfast | lunch | dinner | snacks

// ─── Screen ──────────────────────────────────────────────────────────────────

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // id -> quantity
  final Map<String, int> _cart = {};
  // id -> 'ingredient' | 'recipe'
  final Map<String, String> _cartItemTypes = {};

  List<FoodModel> _allFoods = [];
  List<FoodModel> _recentFoods = [];
  List<RecipeModel> _recipes = [];

  bool _loadingFoods = true;
  bool _loadingRecent = true;
  bool _loadingRecipes = true;
  bool _isLogging = false;

  String? _foodsError;
  String? _recentError;
  String? _recipesError;

  int get _cartTotal => _cart.values.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() {
        _searchQuery = '';
        _searchController.clear();
      });
    });
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text.toLowerCase()),
    );
    _fetchFoods();
    _fetchRecent();
    _fetchRecipes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── API ─────────────────────────────────────────────────────────────────────

  Future<void> _fetchFoods() async {
    setState(() { _loadingFoods = true; _foodsError = null; });
    try {
      final uri = Uri.parse('$kBaseUrl/api/pahae/addFood/ingredients');
      debugPrint('[AddFood] GET $uri');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      debugPrint('[AddFood] foods status=${res.statusCode} body=${res.body}');
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        final List data = body['data'] as List? ?? [];
        setState(() {
          _allFoods = data.map((j) => FoodModel.fromJson(j as Map<String, dynamic>)).toList();
          _loadingFoods = false;
        });
      } else {
        setState(() { _foodsError = body['message'] ?? 'Erreur serveur'; _loadingFoods = false; });
      }
    } catch (e) {
      debugPrint('[AddFood] fetchFoods error: $e');
      setState(() { _foodsError = 'Erreur réseau: $e'; _loadingFoods = false; });
    }
  }

  Future<void> _fetchRecent() async {
    setState(() { _loadingRecent = true; _recentError = null; });
    try {
      final uri = Uri.parse('$kBaseUrl/api/pahae/addFood/recent/$kClientID');
      debugPrint('[AddFood] GET $uri');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      debugPrint('[AddFood] recent status=${res.statusCode}');
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        final List data = body['data'] as List? ?? [];
        setState(() {
          _recentFoods = data.map((j) => FoodModel.fromJson(j as Map<String, dynamic>)).toList();
          _loadingRecent = false;
        });
      } else {
        setState(() { _recentError = body['message'] ?? 'Erreur serveur'; _loadingRecent = false; });
      }
    } catch (e) {
      debugPrint('[AddFood] fetchRecent error: $e');
      setState(() { _recentError = 'Erreur réseau: $e'; _loadingRecent = false; });
    }
  }

  Future<void> _fetchRecipes() async {
    setState(() { _loadingRecipes = true; _recipesError = null; });
    try {
      final uri = Uri.parse('$kBaseUrl/api/pahae/addFood/recipes/$kClientID');
      debugPrint('[AddFood] GET $uri');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      debugPrint('[AddFood] recipes status=${res.statusCode}');
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        final List data = body['data'] as List? ?? [];
        setState(() {
          _recipes = data.map((j) => RecipeModel.fromJson(j as Map<String, dynamic>)).toList();
          _loadingRecipes = false;
        });
      } else {
        setState(() { _recipesError = body['message'] ?? 'Erreur serveur'; _loadingRecipes = false; });
      }
    } catch (e) {
      debugPrint('[AddFood] fetchRecipes error: $e');
      setState(() { _recipesError = 'Erreur réseau: $e'; _loadingRecipes = false; });
    }
  }

  Future<void> _logItems() async {
    if (_cart.isEmpty || _isLogging) return;
    setState(() => _isLogging = true);

    final items = _cart.entries.map((e) => {
      'type': _cartItemTypes[e.key] ?? 'ingredient',
      'id': int.tryParse(e.key) ?? 0,
      'quantity': e.value,
    }).toList();

    final payload = {
      'clientID': kClientID,
      'mealtime': kMealtime,
      'items': items,
    };

    debugPrint('[AddFood] POST log payload: ${jsonEncode(payload)}');

    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/api/pahae/addFood/log'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('[AddFood] log status=${res.statusCode} body=${res.body}');

      if (!mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(body['message'] ?? 'Ajouté au repas !'),
          backgroundColor: kNeonGreen,
          behavior: SnackBarBehavior.floating,
        ));
        if (Navigator.canPop(context)) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(body['message'] ?? 'Échec de l\'enregistrement'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      debugPrint('[AddFood] logItems error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur réseau: $e'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }
  }

  // ─── Cart ─────────────────────────────────────────────────────────────────────

  void _addToCart(String id, String type) => setState(() {
        _cart[id] = (_cart[id] ?? 0) + 1;
        _cartItemTypes[id] = type;
      });

  void _removeFromCart(String id) => setState(() {
        if ((_cart[id] ?? 0) > 1) {
          _cart[id] = _cart[id]! - 1;
        } else {
          _cart.remove(id);
          _cartItemTypes.remove(id);
        }
      });

  // ─── Filters ──────────────────────────────────────────────────────────────────

  List<FoodModel> get _filteredFoods =>
      _allFoods.where((f) => f.name.toLowerCase().contains(_searchQuery)).toList();

  List<FoodModel> get _filteredRecent =>
      _recentFoods.where((f) => f.name.toLowerCase().contains(_searchQuery)).toList();

  List<RecipeModel> get _filteredRecipes =>
      _recipes.where((r) => r.name.toLowerCase().contains(_searchQuery)).toList();

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
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
                  _buildFoodList(),
                  _buildHistoryList(),
                  _buildRecipeList(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _cartTotal > 0 ? _buildCartFAB() : null,
    );
  }

  // ─── Top Bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { if (Navigator.canPop(context)) Navigator.pop(context); },
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: kDarkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text('ADD FOOD',
                style: TextStyle(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w800, letterSpacing: 2)),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _cartTotal > 0
                ? Container(
                    key: const ValueKey('badge'),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: kNeonGreen, borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      const Icon(Icons.shopping_basket_outlined,
                          color: Colors.black, size: 14),
                      const SizedBox(width: 5),
                      Text('$_cartTotal',
                          style: const TextStyle(
                              color: Colors.black, fontSize: 13, fontWeight: FontWeight.w800)),
                    ]),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }

  // ─── Search Bar ───────────────────────────────────────────────────────────────

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
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.3), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: Icon(Icons.close, color: Colors.white.withOpacity(0.3), size: 18),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ─── Tab Bar ──────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Container(
        decoration: BoxDecoration(color: kDarkCard, borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(color: kNeonGreen, borderRadius: BorderRadius.circular(10)),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white.withOpacity(0.45),
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
          unselectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
          tabs: const [Tab(text: 'FOODS'), Tab(text: 'HISTORY'), Tab(text: 'RECIPES')],
        ),
      ),
    );
  }

  // ─── Foods Tab ────────────────────────────────────────────────────────────────

  Widget _buildFoodList() {
    if (_loadingFoods) return _buildLoader();
    if (_foodsError != null) return _buildError(_foodsError!, _fetchFoods);
    final foods = _filteredFoods;
    if (foods.isEmpty) return _buildEmpty();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      itemCount: foods.length,
      itemBuilder: (_, i) =>
          Padding(padding: const EdgeInsets.only(bottom: 10), child: _buildFoodCard(foods[i])),
    );
  }

  // ─── History Tab ──────────────────────────────────────────────────────────────

  Widget _buildHistoryList() {
    if (_loadingRecent) return _buildLoader();
    if (_recentError != null) return _buildError(_recentError!, _fetchRecent);
    final foods = _filteredRecent;
    if (foods.isEmpty) return _buildEmpty(message: 'Aucun aliment récent');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      itemCount: foods.length,
      itemBuilder: (_, i) =>
          Padding(padding: const EdgeInsets.only(bottom: 10), child: _buildFoodCard(foods[i])),
    );
  }

  // ─── Recipes Tab ──────────────────────────────────────────────────────────────

  Widget _buildRecipeList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      children: [
        GestureDetector(
          onTap: () async {
            final created = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
            );
            if (created == true) _fetchRecipes();
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
                Text('CREATE NEW RECIPE',
                    style: TextStyle(
                        color: kNeonGreen, fontSize: 12,
                        fontWeight: FontWeight.w700, letterSpacing: 1)),
              ],
            ),
          ),
        ),
        if (_loadingRecipes)
          _buildLoader()
        else if (_recipesError != null)
          _buildError(_recipesError!, _fetchRecipes)
        else if (_filteredRecipes.isEmpty)
          _buildEmpty(message: 'Aucune recette')
        else
          ..._filteredRecipes.map((r) =>
              Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildRecipeCard(r))),
      ],
    );
  }

  // ─── Food Card ────────────────────────────────────────────────────────────────

  Widget _buildFoodCard(FoodModel food) {
    final qty = _cart[food.id] ?? 0;
    return Container(
      decoration: BoxDecoration(color: kDarkCard, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          SizedBox(
            width: 80, height: 80,
            child: Stack(fit: StackFit.expand, children: [
              Image.network(food.imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.fastfood, color: Colors.white24, size: 24))),
              Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.transparent, kDarkCard.withOpacity(0.65)]))),
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildTypeChip(food.typeLabel),
                const SizedBox(height: 5),
                Text(food.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(food.calLabel,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: qty == 0
                ? _buildAddBtn(() => _addToCart(food.id, 'ingredient'))
                : _buildQtyControl(qty, () => _addToCart(food.id, 'ingredient'),
                    () => _removeFromCart(food.id)),
          ),
        ],
      ),
    );
  }

  // ─── Recipe Card ──────────────────────────────────────────────────────────────

  Widget _buildRecipeCard(RecipeModel recipe) {
    final qty = _cart[recipe.id] ?? 0;
    return Container(
      decoration: BoxDecoration(color: kDarkCard, borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.hardEdge,
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => recipe.isExpanded = !recipe.isExpanded),
          child: SizedBox(
            height: 100,
            child: Stack(fit: StackFit.expand, children: [
              Image.network(recipe.imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A1A))),
              Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.82)
                          ],
                          stops: const [0.0, 1.0]))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(recipe.name,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700,
                                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)])),
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.local_fire_department, color: kNeonGreen, size: 12),
                            const SizedBox(width: 3),
                            Text('${recipe.calories.toInt()} kcal',
                                style: const TextStyle(
                                    color: kNeonGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                            Text('  ·  ${recipe.ingredients.length} ingredients',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5), fontSize: 11)),
                          ]),
                        ]),
                  ),
                  const SizedBox(width: 10),
                  qty == 0
                      ? _buildAddBtn(() => _addToCart(recipe.id, 'recipe'))
                      : _buildQtyControl(qty, () => _addToCart(recipe.id, 'recipe'),
                          () => _removeFromCart(recipe.id)),
                  const SizedBox(width: 8),
                  Icon(
                      recipe.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white.withOpacity(0.55), size: 22),
                ]),
              ),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: recipe.isExpanded
              ? recipe.ingredients.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text('Aucun ingrédient',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.35), fontSize: 12)))
                  : Column(children: [
                      const Divider(height: 1, color: Colors.white10),
                      ...recipe.ingredients.map((ing) => Column(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(ing.imageUrl,
                                      width: 42, height: 42, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                          width: 42, height: 42, color: Colors.white10,
                                          child: const Icon(Icons.fastfood,
                                              color: Colors.white24, size: 18))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(ing.name,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text(ing.calLabel,
                                            style: TextStyle(
                                                color: Colors.white.withOpacity(0.35),
                                                fontSize: 11)),
                                      ]),
                                ),
                                _buildTypeChip(ing.typeLabel),
                              ]),
                            ),
                            if (ing != recipe.ingredients.last)
                              const Divider(height: 1, color: Colors.white10, indent: 68),
                          ])),
                    ])
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }

  // ─── Shared Widgets ───────────────────────────────────────────────────────────

  Widget _buildAddBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: kNeonGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kNeonGreen.withOpacity(0.45), width: 1),
        ),
        child: const Icon(Icons.add, color: kNeonGreen, size: 18),
      ),
    );
  }

  Widget _buildQtyControl(int qty, VoidCallback onAdd, VoidCallback onRemove) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: onRemove,
        child: Container(
          width: 30, height: 30,
          decoration:
              BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.remove, color: Colors.white, size: 16),
        ),
      ),
      SizedBox(
        width: 28,
        child: Text('$qty',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      ),
      GestureDetector(
        onTap: onAdd,
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: kNeonGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kNeonGreen.withOpacity(0.45), width: 1),
          ),
          child: const Icon(Icons.add, color: kNeonGreen, size: 16),
        ),
      ),
    ]);
  }

  Widget _buildTypeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: kNeonGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kNeonGreen.withOpacity(0.22), width: 1),
      ),
      child: Text(label,
          style: const TextStyle(
              color: kNeonGreen, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
    );
  }

  Widget _buildEmpty({String message = 'No results found'}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off, color: Colors.white.withOpacity(0.12), size: 52),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.28),
                  fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 80),
        child: CircularProgressIndicator(color: kNeonGreen, strokeWidth: 2),
      ),
    );
  }

  Widget _buildError(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80, left: 24, right: 24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white.withOpacity(0.18), size: 48),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: kNeonGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kNeonGreen.withOpacity(0.4), width: 1),
              ),
              child: const Text('RETRY',
                  style: TextStyle(
                      color: kNeonGreen, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCartFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: _isLogging ? null : _logItems,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: _isLogging ? kNeonGreen.withOpacity(0.6) : kNeonGreen,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: kNeonGreen.withOpacity(0.22),
                  blurRadius: 18, offset: const Offset(0, 4))
            ],
          ),
          child: _isLogging
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle_outline, color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ADD $_cartTotal ITEM${_cartTotal > 1 ? 'S' : ''} TO MEAL',
                    style: const TextStyle(
                        color: Colors.black, fontSize: 13,
                        fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ]),
        ),
      ),
    );
  }
}