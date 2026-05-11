import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/constants/urls.dart';
import 'package:test_hh/models/food.dart';
import 'package:test_hh/models/recipeIngredient.dart';
import 'package:test_hh/services/api_service.dart';
import 'package:test_hh/session/user_session.dart'; // ← ajout

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  // ── Session ─────────────────────────────────────────────────────────────────
  // Lecture directe depuis UserSession — plus de Future/loading pour la session.
  int get _clientID => UserSession.instance.id;

  // ── Form state ──────────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  XFile? _pickedImage;

  // ── Ingredient state ────────────────────────────────────────────────────────
  List<FoodModel> _catalogue = [];
  bool _loadingCatalogue = true;
  String? _catalogueError;

  final List<RecipeIngredientModel> _entries = [];

  // ── Search ──────────────────────────────────────────────────────────────────
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // ── Save state ──────────────────────────────────────────────────────────────
  bool _saving = false;

  // ── Derived ─────────────────────────────────────────────────────────────────
  double get _totalCalories =>
      _entries.fold(0.0, (s, e) => s + e.contributedCalories);

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      _entries.isNotEmpty &&
      !_saving &&
      UserSession.instance.isLoaded &&
      UserSession.instance.isClient;

  List<FoodModel> get _filteredCatalogue => _catalogue
      .where((f) => f.name.toLowerCase().contains(_searchQuery))
      .toList();

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _searchController.addListener(
      () => setState(
          () => _searchQuery = _searchController.text.toLowerCase()),
    );
    // Plus besoin de charger la session : on la lit directement.
    // On vérifie uniquement que la session est valide avant de fetch.
    if (UserSession.instance.isLoaded && UserSession.instance.isClient) {
      _fetchIngredients();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Headers avec token ────────────────────────────────────────────────────────

  Future<Map<String, String>> _headers() async {
    final token = await ApiService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── API calls ────────────────────────────────────────────────────────────────

  Future<void> _fetchIngredients() async {
    setState(() {
      _loadingCatalogue = true;
      _catalogueError = null;
    });
    try {
      final uri = Uri.parse('$kBaseUrl/api/pahae/addRecipe/ingredients');
      final headers = await _headers();
      final response =
          await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> raw = body['data'] ?? [];
          setState(() {
            _catalogue =
                raw.map((json) => FoodModel.fromJson(json)).toList();
            _loadingCatalogue = false;
          });
        } else {
          throw Exception(body['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _catalogueError = 'Could not load ingredients.\nTap to retry.';
        _loadingCatalogue = false;
      });
    }
  }

  Future<String?> uploadImageToCloudinary(XFile imageFile) async {
    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/dlqcknocf/image/upload",
      );
      final request = http.MultipartRequest("POST", uri);
      request.fields['upload_preset'] = 'GymApp';

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('file', bytes,
            filename: imageFile.name));
      } else {
        request.files
            .add(await http.MultipartFile.fromPath('file', imageFile.path));
      }

      final response = await request.send();
      final res = await response.stream.bytesToString();
      final data = jsonDecode(res);

      if (response.statusCode == 200) {
        return data['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveRecipe() async {
    if (!_canSave) return;
    setState(() => _saving = true);

    try {
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await uploadImageToCloudinary(_pickedImage!);
        if (imageUrl == null) throw Exception("Image upload failed");
      } else if (_entries.isNotEmpty) {
        imageUrl = _entries.first.food.imageUrl;
      }

      final headers = await _headers();
      final body = jsonEncode({
        'clientID': _clientID, // ← lu depuis UserSession
        'name': _nameController.text.trim(),
        'image': imageUrl,
        'calories': _totalCalories.toInt(),
        'ingredients': _entries
            .map((e) => {
                  'ingredientID': int.tryParse(e.food.id) ?? 0,
                  'quantity': e.quantity.toInt(),
                })
            .toList(),
      });

      final uri = Uri.parse('$kBaseUrl/api/pahae/addRecipe/save');
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 201 && decoded['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe saved successfully!'),
            backgroundColor: kNeonGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showErrorSnack(decoded['message'] ?? 'Failed to save recipe.');
      }
    } catch (e) {
      _showErrorSnack('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // ── Ingredient helpers ───────────────────────────────────────────────────────

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
    setState(() =>
        _entries.removeWhere((e) => e.food.id == entry.food.id));
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) setState(() => _pickedImage = xfile);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ── Vérification de session (synchrone) ────────────────────────────────
    if (!UserSession.instance.isLoaded || !UserSession.instance.isClient) {
      return Scaffold(
        backgroundColor: kDarkBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline,
                    color: Colors.white.withOpacity(0.2), size: 52),
                const SizedBox(height: 16),
                Text(
                  UserSession.instance.isLoaded
                      ? 'Accès réservé aux clients.'
                      : 'Session introuvable. Reconnectez-vous.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 14),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: kNeonGreen.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('RETOUR',
                        style: TextStyle(
                            color: kNeonGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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

  // ── TOP BAR ──────────────────────────────────────────────────────────────────

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
            child: Text('NEW RECIPE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
          ),
          if (_entries.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kDarkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: kNeonGreen.withOpacity(0.4), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu,
                      color: kNeonGreen, size: 13),
                  const SizedBox(width: 5),
                  Text('${_entries.length} items',
                      style: const TextStyle(
                          color: kNeonGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── IMAGE + NAME ─────────────────────────────────────────────────────────────

  Widget _buildImageAndNameSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: kDarkCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: kNeonGreen.withOpacity(0.3), width: 1.5),
              ),
              clipBehavior: Clip.hardEdge,
              child: _pickedImage != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(_pickedImage!.path, fit: BoxFit.cover),
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
                        Text('ADD\nIMAGE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: kNeonGreen.withOpacity(0.6),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8)),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 14),
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
                        fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'Recipe name…',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _entries.isEmpty
                      ? Text('Add ingredients below',
                          key: const ValueKey('hint'),
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.25),
                              fontSize: 12))
                      : Row(
                          key: const ValueKey('cals'),
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: kNeonGreen, size: 14),
                            const SizedBox(width: 5),
                            Text('${_totalCalories.toInt()} kcal total',
                                style: const TextStyle(
                                    color: kNeonGreen,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            Text(
                                '  ·  ${_entries.length} ingredient${_entries.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 12)),
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

  // ── LIVE RECIPE SUMMARY ───────────────────────────────────────────────────────

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
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Text('RECIPE SUMMARY',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5)),
                    const Spacer(),
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
                          Text('${_totalCalories.toInt()} kcal',
                              style: const TextStyle(
                                  color: kNeonGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              Padding(
                padding: const EdgeInsets.all(14),
                child: _buildRecipePreviewCard(),
              ),
              ..._entries.map((e) => _buildSummaryIngredientRow(e)),
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
          borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_pickedImage != null)
            Image.network(_pickedImage!.path, fit: BoxFit.cover)
          else if (_entries.isNotEmpty)
            Image.network(_entries.first.food.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF1A1A1A))),
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
                    color: hasName
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontStyle: hasName
                        ? FontStyle.normal
                        : FontStyle.italic,
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
                        fontSize: 11)),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(entry.food.imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        width: 40,
                        height: 40,
                        color: Colors.white10,
                        child: const Icon(Icons.fastfood,
                            color: Colors.white24, size: 16))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.food.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    Text('${entry.contributedCalories.toInt()} kcal',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11)),
                  ],
                ),
              ),
              _buildQuantityStepper(entry),
              const SizedBox(width: 8),
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
        SizedBox(
          width: 52,
          child: Text(entry.quantityLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
        _stepperBtn(
            icon: Icons.add,
            onTap: () => setState(() => entry.quantity += step),
            isPlus: true),
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

  // ── INGREDIENT PICKER ────────────────────────────────────────────────────────

  Widget _buildIngredientPickerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('INGREDIENTS',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
              const Spacer(),
              Text('${_entries.length} selected',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingCatalogue) ...[
            const SizedBox(height: 40),
            const Center(
                child: CircularProgressIndicator(
                    color: kNeonGreen, strokeWidth: 2)),
            const SizedBox(height: 12),
            Center(
              child: Text('Loading ingredients…',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 12)),
            ),
          ] else if (_catalogueError != null) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetchIngredients,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: kDarkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        color: Colors.redAccent.withOpacity(0.7), size: 28),
                    const SizedBox(height: 10),
                    Text(_catalogueError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12)),
                    const SizedBox(height: 8),
                    Text('TAP TO RETRY',
                        style: TextStyle(
                            color: kNeonGreen.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: kDarkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _searchController,
                style:
                    const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search ingredients…',
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.28),
                      fontSize: 13),
                  prefixIcon: Icon(Icons.search,
                      color: Colors.white.withOpacity(0.28), size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _searchController.clear(),
                          child: Icon(Icons.close,
                              color: Colors.white.withOpacity(0.28),
                              size: 16),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_filteredCatalogue.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'No ingredients match "$_searchQuery"'
                        : 'No ingredients available',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.25),
                        fontSize: 13),
                  ),
                ),
              )
            else
              ..._filteredCatalogue.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCatalogueRow(f),
                ),
              ),
          ],
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
          color: added ? kNeonGreen.withOpacity(0.07) : kDarkCard,
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
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(14)),
              child: SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(food.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF1A1A1A),
                            child: const Icon(Icons.fastfood,
                                color: Colors.white24, size: 20))),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            (added
                                    ? kNeonGreen.withOpacity(0.07)
                                    : kDarkCard)
                                .withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeChip(food.typeLabel, highlighted: added),
                    const SizedBox(height: 4),
                    Text(food.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(food.calLabel,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.38),
                            fontSize: 11)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: added ? kNeonGreen : kNeonGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          kNeonGreen.withOpacity(added ? 1 : 0.4), width: 1),
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

  // ── SAVE FAB ─────────────────────────────────────────────────────────────────

  Widget _buildSaveFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: _saving ? null : _saveRecipe,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: _saving ? kNeonGreen.withOpacity(0.5) : kNeonGreen,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: kNeonGreen.withOpacity(0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_saving)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.black, strokeWidth: 2))
              else
                const Icon(Icons.save_alt_rounded,
                    color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Text(_saving ? 'SAVING…' : 'SAVE RECIPE',
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────────

  Widget _buildTypeChip(String label, {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: kNeonGreen.withOpacity(highlighted ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
            color: kNeonGreen.withOpacity(highlighted ? 0.5 : 0.2),
            width: 1),
      ),
      child: Text(label,
          style: const TextStyle(
              color: kNeonGreen,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6)),
    );
  }
}