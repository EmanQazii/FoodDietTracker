import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'record_screen.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  final File? imageFile;
  final String? predictedFood;
  final String? confidence;
  final String? calorieRange;
  final String? calorieCategory;
  final List<String>? top3Suggestions;
  final String? disclaimer;
  final String? mealType;          

  const ResultScreen({
    super.key,
    required this.imageFile,
    this.predictedFood,
    this.confidence,
    this.calorieRange,
    this.calorieCategory,
    this.top3Suggestions,
    this.disclaimer,
    this.mealType,                 
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // ============ EDITABLE FIELDS ============
  late TextEditingController _foodLabelController;
  late TextEditingController _confidenceController;
  late TextEditingController _calorieRangeController;
  late TextEditingController _calorieCategoryController;
  late String _selectedMealType;

  bool _hasChanges = false;
  bool _isSaved = false;
  bool _foodNameDirty = false;
  bool _isUpdatingCalories = false;
  String? _originalFoodLabel;

  final List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with prediction data (or defaults)
    _foodLabelController =
        TextEditingController(text: widget.predictedFood ?? 'Biryani');
    _confidenceController =
        TextEditingController(text: widget.confidence ?? '87%');
    _calorieRangeController =
        TextEditingController(text: widget.calorieRange ?? '500-800 Cal');
    _calorieCategoryController = TextEditingController(
        text: widget.calorieCategory ?? 'High Calorie Rice Meal');
    // Initialize meal type
    _selectedMealType = widget.mealType ?? 'Lunch';
    // Track changes
    _foodLabelController.addListener(_onFieldChanged);
    _confidenceController.addListener(_onFieldChanged);
    _calorieRangeController.addListener(_onFieldChanged);
    _calorieCategoryController.addListener(_onFieldChanged);
    _originalFoodLabel = widget.predictedFood ?? '';
  // add listener for dirty tracking:
  _foodLabelController.addListener(() {
    final isDirty = _foodLabelController.text != _originalFoodLabel;
    if (isDirty != _foodNameDirty) setState(() => _foodNameDirty = isDirty);
  });
  }

  @override
  void dispose() {
    _foodLabelController.dispose();
    _confidenceController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Food not found — calories unchanged.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ));
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
  // ============ SAVE MEAL ============
  void _handleSaveMeal() async {
    FocusScope.of(context).unfocus();

    // Collect all data
    final mealData = {
      'food_label': _foodLabelController.text,
      'confidence': widget.confidence ?? '0',
      'calorie_min': int.tryParse(
        _calorieRangeController.text.split('-').first.replaceAll(RegExp(r'[^0-9]'), '')
      ) ?? 0,
      'calorie_max': int.tryParse(
        _calorieRangeController.text.split('-').last.replaceAll(RegExp(r'[^0-9]'), '')
      ) ?? 0,
      'calorie_category': _calorieCategoryController.text,
      'meal_type': _selectedMealType.toLowerCase(),
      'image_path': widget.imageFile?.path ?? '',
    };

    // Save to backend
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
        SnackBar(
          content: const Text('Failed to save meal. Please try again.'),
          backgroundColor: AppColors.terracotta,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Navigate to Records Screen after save
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const RecordsScreen(),
          ),
          (route) => route.isFirst,
        );
      }
    });
  }

  // ============ HANDLE BACK ============
  Future<bool> _handleBackPress() async {
    FocusScope.of(context).unfocus();

  // If already saved, just go home
  if (_isSaved) {
    _goToHome();
    return false;
  }

  // Ask user what to do
  final result = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: AppColors.gradientTop,
      title: Text(
        'Save Result?',
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w700,
          color: AppColors.brandBrown,
        ),
      ),
      content: Text(
        'Do you want to save this meal before leaving?',
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
    return false; // _handleSaveMeal handles navigation
  } else if (result == 'discard') {
    _goToHome(); //  Go to home on discard
    return false;
  } else {
    return false; // cancel - stay on screen
  }
}

// ============ HELPER: GO TO HOME ============
void _goToHome() {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => const HomeScreen(),
    ),
    (route) => false, // clear entire stack
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
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + keyboardHeight,
              ),
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

  // ============ HEADER ============
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
              border: Border.all(
                color: AppColors.brandBrown,
                width: 1.5,
              ),
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
          'Result',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.brandBrown,
          ),
        ),
      ],
    );
  }

  // ============ IMAGE (captured/uploaded) ============
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
          child: widget.imageFile != null
              ? Image.file(
                  widget.imageFile!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              : _buildFallbackImage(),
        ),
      ),
    );
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

  // ============ MEALS INFORMATION TITLE ============
  Widget _buildMealsInfoTitle() {
    return Text(
      'Meals Information:',
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.brandBrown,
      ),
    );
  }

  // ============ INFO CARD ============
  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.gradientMiddle.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Label
          _buildFieldLabel('FOOD LABEL:'),
          const SizedBox(height: 6),
            Row(children: [
            Expanded(child: _buildEditableField(controller: _foodLabelController)),
            if (_foodNameDirty) ...[
              const SizedBox(width: 8),
              _isUpdatingCalories
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : GestureDetector(
                      onTap: _updateCalories,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.sageGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Update',
                          style: GoogleFonts.montserrat(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: AppColors.white)),
                      ),
                    ),
            ],
          ]),
          const SizedBox(height: 14),

          // Confidence
          _buildFieldLabel('CONFIDENCE:'),
          const SizedBox(height: 6),
          _buildReadOnlyField(value: widget.confidence ?? '—'),
          const SizedBox(height: 14),

          // Calorie Range
          _buildFieldLabel('CALORIE RANGE:'),
          const SizedBox(height: 6),
          _buildEditableField(controller: _calorieRangeController),
          const SizedBox(height: 14),

          // Calorie Category
          _buildFieldLabel('CALORIE CATEGORY'),
          const SizedBox(height: 6),
          _buildEditableField(controller: _calorieCategoryController),
          const SizedBox(height: 14),

          // Low‑Confidence Alternatives (chips)
          if (widget.top3Suggestions != null && widget.top3Suggestions!.isNotEmpty) ...[
            _buildFieldLabel('ALTERNATIVES'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: widget.top3Suggestions!
                  .map((s) => ChoiceChip(
                        label: Text(s),
                        selected: false,
                        onSelected: (_) {
                          // Update fields with selected alternative
                          _foodLabelController.text = s;
                          // TODO: you may also want to update calorie range etc. if backend provides them.
                          _hasChanges = true;
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Meal Type
          _buildFieldLabel('MEAL TYPE'),
          const SizedBox(height: 6),
          _buildMealTypeDropdown(),

          // Disclaimer
          if (widget.disclaimer != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.disclaimer!,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textLight,
              ),
            ),
          ],
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
        letterSpacing: 0.8,
      ),
    );
  }
  Widget _buildReadOnlyField({required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textMedium,
        ),
      ),
    );
  }
  Widget _buildEditableField({required TextEditingController controller}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        scrollPadding: const EdgeInsets.only(bottom: 120),
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildMealTypeDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMealType,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.brandBrown,
          ),
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
          dropdownColor: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          alignment: Alignment.center,
          items: _mealTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              alignment: Alignment.center,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMealType = value;
                _hasChanges = true;
              });
            }
          },
        ),
      ),
    );
  }

  // ============ SAVE BUTTON ============
  Widget _buildSaveButton() {
    return Center(
      child: SizedBox(
        width: 240,
        height: 50,
        child: ElevatedButton(
          onPressed: _handleSaveMeal,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sageGreen,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 3,
            shadowColor: AppColors.darkSage.withOpacity(0.4),
          ),
          child: Text(
            'SAVE THE MEAL',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}