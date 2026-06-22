import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'record_screen.dart';
import 'home_screen.dart';

class MealDetailScreen extends StatefulWidget {
  final String name;
  final String date;
  final String meal;
  final String calories;
  final String image; // Can be file path or network URL
  final File? imageFile; // Optional: for new predictions
  final bool isNewMeal; // true = prediction result, false = saved meal

  const MealDetailScreen({
    super.key,
    required this.name,
    required this.date,
    required this.meal,
    required this.calories,
    required this.image,
    this.imageFile,
    this.isNewMeal = false,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  late TextEditingController _foodLabelController;
  late TextEditingController _calorieRangeController;
  late TextEditingController _calorieCategoryController;
  late String _selectedMealType;

  bool _hasChanges = false;
  bool _isSaved = false;
  bool _foodNameDirty = false;
  bool _isUpdatingCalories = false;
  String? _originalFoodLabel;

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();

    // Initialize food label
    _foodLabelController = TextEditingController(text: widget.name);
    _originalFoodLabel = widget.name;

    // Parse calorie range from widget.calories
    String calorieRange = widget.calories;
    if (calorieRange.contains('-')) {
      _calorieRangeController = TextEditingController(text: calorieRange);
    } else {
      _calorieRangeController = TextEditingController(text: '0-0 Cal');
    }

    _calorieCategoryController = TextEditingController(text: 'Meal');

    // Initialize meal type
    String mealTypeTitleCase =
        widget.meal.length > 0
            ? widget.meal[0].toUpperCase() +
                widget.meal.substring(1).toLowerCase()
            : 'Lunch';
    _selectedMealType = mealTypeTitleCase;

    // Track changes
    _foodLabelController.addListener(_onFieldChanged);
    _calorieRangeController.addListener(_onFieldChanged);
    _calorieCategoryController.addListener(_onFieldChanged);

    _foodLabelController.addListener(() {
      final isDirty = _foodLabelController.text != _originalFoodLabel;
      if (isDirty != _foodNameDirty) setState(() => _foodNameDirty = isDirty);
    });
  }

  @override
  void dispose() {
    _foodLabelController.dispose();
    _calorieRangeController.dispose();
    _calorieCategoryController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _updateCalories() async {
    final name = _foodLabelController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isUpdatingCalories = true);
    final result = await ApiService.lookupCalories(name);
    if (!mounted) return;
    setState(() => _isUpdatingCalories = false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food not found — calories unchanged.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _calorieRangeController.text =
          '${result['calorie_min']}-${result['calorie_max']} Cal';
      _calorieCategoryController.text = result['calorie_category'] ?? '';
      _originalFoodLabel = name;
      _foodNameDirty = false;
      _hasChanges = true;
    });
  }

  void _handleSaveMeal() async {
    FocusScope.of(context).unfocus();

    final mealData = {
      'food_label': _foodLabelController.text,
      'confidence': '0',
      'calorie_min':
          int.tryParse(
            _calorieRangeController.text
                .split('-')
                .first
                .replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0,
      'calorie_max':
          int.tryParse(
            _calorieRangeController.text
                .split('-')
                .last
                .replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0,
      'calorie_category': _calorieCategoryController.text,
      'meal_type': _selectedMealType.toLowerCase(),
      'image_path': widget.imageFile?.path ?? '',
    };

    bool success = await ApiService.saveMeal(mealData);
    if (!mounted) return;

    if (success) {
      setState(() {
        _isSaved = true;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_foodLabelController.text} saved successfully!'),
          backgroundColor: AppColors.sageGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save meal. Please try again.'),
          backgroundColor: AppColors.terracotta,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RecordsScreen()),
          (route) => route.isFirst,
        );
      }
    });
  }

  Future<bool> _handleBackPress() async {
    FocusScope.of(context).unfocus();

    if (_isSaved) {
      _goToHome();
      return false;
    }

    if (!_hasChanges) {
      Navigator.pop(context);
      return false;
    }

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: AppColors.gradientTop,
            title: Text(
              'Save Changes?',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                color: AppColors.brandBrown,
              ),
            ),
            content: Text(
              'Do you want to save this meal?',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textMedium,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'discard'),
                child: Text(
                  'Discard',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    color: AppColors.terracotta,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'save'),
                child: Text(
                  'Save',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    color: AppColors.sageGreen,
                  ),
                ),
              ),
            ],
          ),
    );

    if (result == 'save') {
      _handleSaveMeal();
      return false;
    } else if (result == 'discard') {
      Navigator.pop(context);
      return false;
    }
    return false;
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: AppColors.gradientTop,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + keyboardHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildImage(),
                  const SizedBox(height: 24),
                  _buildMealsInfoTitle(),
                  const SizedBox(height: 14),
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            await _handleBackPress();
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brandBrown, width: 1.5),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.brandBrown,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Meal Details',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.brandBrown,
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    return Center(
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildImageContent(),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    // Try file image first (for new predictions)
    if (widget.imageFile != null) {
      return Image.file(
        widget.imageFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Try network image (for saved meals)
    if (widget.image.isNotEmpty &&
        (widget.image.startsWith('http') || widget.image.contains('/'))) {
      return Image.network(
        widget.image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
      );
    }

    // Fallback
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      color: AppColors.gradientMiddle.withOpacity(0.3),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 60,
          color: AppColors.brandBrown,
        ),
      ),
    );
  }

  Widget _buildMealsInfoTitle() {
    return Text(
      'Edit Meal',
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.brandBrown,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gradientMiddle.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('FOOD NAME:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildEditableField(
                  controller: _foodLabelController,
                  hintText: 'Enter food name',
                ),
              ),
              if (_foodNameDirty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child:
                      _isUpdatingCalories
                          ? SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    AppColors.terracotta,
                                  ),
                                ),
                              ),
                            ),
                          )
                          : GestureDetector(
                            onTap: _updateCalories,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.terracotta,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.refresh,
                                color: AppColors.white,
                                size: 18,
                              ),
                            ),
                          ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('CALORIE RANGE:'),
          const SizedBox(height: 8),
          _buildEditableField(
            controller: _calorieRangeController,
            hintText: 'e.g., 500-800 Cal',
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('CALORIE CATEGORY:'),
          const SizedBox(height: 8),
          _buildEditableField(
            controller: _calorieCategoryController,
            hintText: 'e.g., High Calorie',
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('MEAL TYPE:'),
          const SizedBox(height: 8),
          _buildMealTypeDropdown(),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.brandBrown,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.textLight.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.montserrat(
            fontSize: 13,
            color: AppColors.textLight,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildMealTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.textLight.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButton<String>(
        value: _selectedMealType,
        isExpanded: true,
        underline: const SizedBox(),
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        onChanged: (newValue) {
          if (newValue != null) {
            setState(() {
              _selectedMealType = newValue;
              _onFieldChanged();
            });
          }
        },
        items:
            _mealTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _hasChanges ? _handleSaveMeal : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _hasChanges ? AppColors.sageGreen : AppColors.textLight,
          disabledBackgroundColor: AppColors.textLight.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Text(
          'Save Meal',
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
