import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class ManualSearchScreen extends StatefulWidget {
  final String mealType;
  const ManualSearchScreen({super.key, required this.mealType});

  @override
  State<ManualSearchScreen> createState() => _ManualSearchScreenState();
}

class _ManualSearchScreenState extends State<ManualSearchScreen> {
  final _foodController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedServing = 'Medium';
  bool _isLoading = false;

  final List<String> _servingSizes = ['Small', 'Medium', 'Large'];

  @override
  void dispose() {
    _foodController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final result = await ApiService.predictManual(
      _foodController.text.trim(),
      widget.mealType,
      _selectedServing.toLowerCase(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
          backgroundColor: AppColors.terracotta,
        ),
      );
      return;
    }

    if (result['is_unknown'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Food not found in USDA database.'),
          backgroundColor: AppColors.terracotta,
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          imageFile: null,
          predictedFood: result['food_name']?.toString(),
          mealType: widget.mealType,
          confidence: '100%',
          calorieRange:
              '${result['calorie_min']}-${result['calorie_max']} Cal',
          calorieCategory: result['calorie_category']?.toString(),
          top3Suggestions: const [],
          disclaimer: result['disclaimer']?.toString() ??
              'Calorie estimate provided by USDA FoodData Central.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientTop,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.brandBrown, width: 1.5),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: AppColors.brandBrown, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Search Food',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandBrown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 44),
                    child: Text(
                      'Calories fetched from USDA FoodData Central',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Food name field
                  Text(
                    'FOOD NAME',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandBrown,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _foodController,
                    textCapitalization: TextCapitalization.words,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.white,
                      hintText: 'e.g. Chicken Biryani',
                      hintStyle: GoogleFonts.montserrat(
                        color: AppColors.textLight,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.brandBrown),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Please enter a food name'
                        : null,
                  ),
                  const SizedBox(height: 28),

                  // Serving size
                  Text(
                    'SERVING SIZE',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandBrown,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _servingSizes.map((size) {
                      final isSelected = _selectedServing == size;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedServing = size),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: size != 'Large' ? 10 : 0,
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.terracotta
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  size,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.brandBrown,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  size == 'Small'
                                      ? '~150g'
                                      : size == 'Medium'
                                          ? '~250g'
                                          : '~400g',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    color: isSelected
                                        ? AppColors.white.withOpacity(0.8)
                                        : AppColors.textMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 48),

                  // Search button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sageGreen,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'SEARCH USDA DATABASE',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Powered by USDA FoodData Central',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: AppColors.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}