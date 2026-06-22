import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class UploadScreen extends StatefulWidget {
  final String mealType;
  const UploadScreen({super.key, required this.mealType});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isPredicting = false;

  // ============ PICK FROM CAMERA ============
  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
        _startPrediction();
      }
    } catch (e) {
      _showError('Camera error: ${e.toString()}');
    }
  }

  // ============ PICK FROM GALLERY ============
  Future<void> _openGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
        _startPrediction();
      }
    } catch (e) {
      _showError('Gallery error: ${e.toString()}');
    }
  }

  // ============ START PREDICTION ============
  Future<void> _startPrediction() async {
    if (_selectedImage == null) return;

    setState(() => _isPredicting = true);

    try {
      final result = await ApiService.predictImage(_selectedImage!, widget.mealType);

      if (!mounted) return;

      // Extract data from API response
      final List<String> suggestions = (result['top3_suggestions'] as List?)?.map((e) => e.toString()).toList() ?? [];

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            imageFile: _selectedImage,
            predictedFood: result['food_label']?.toString(),
            mealType: widget.mealType,
            confidence: result['confidence'] != null
                ? '${result['confidence'].toStringAsFixed(1)}%'
                : null,
            calorieRange: result['calorie_min'] != null && result['calorie_max'] != null
                ? '${result['calorie_min']}-${result['calorie_max']} Cal'
                : null,
            calorieCategory: result['calorie_category']?.toString(),
            top3Suggestions: suggestions,
            disclaimer: result['disclaimer']?.toString(),
          ),
        ),
      );
    } catch (e) {
      _showError('Prediction failed: ${e.toString()}');
      setState(() => _isPredicting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  // ============ UPLOAD ACTION (top right) ============
  void _onUploadTap() {
    if (_selectedImage != null && !_isPredicting) {
      _startPrediction();
    } else {
      _openGallery(); // shortcut to gallery
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.terracotta,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _buildImageArea(),
            ),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============ TOP BAR (back + upload) ============
  Widget _buildTopBar() {
    return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.white,
            size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ============ IMAGE AREA (with corner brackets) ============
  Widget _buildImageArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.gradientTop,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Selected image OR placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : _buildPlaceholder(),
            ),

            // Corner brackets (frame guide)
            _buildCornerBrackets(),

            // Predicting overlay
            if (_isPredicting) _buildPredictingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.gradientTop,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: AppColors.brandBrown.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Take or upload a photo\nof your food',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.brandBrown.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ CORNER BRACKETS ============
  Widget _buildCornerBrackets() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Top Left
          Align(
            alignment: Alignment.topLeft,
            child: _cornerBracket(topLeft: true),
          ),
          // Top Right
          Align(
            alignment: Alignment.topRight,
            child: _cornerBracket(topRight: true),
          ),
          // Bottom Left
          Align(
            alignment: Alignment.bottomLeft,
            child: _cornerBracket(bottomLeft: true),
          ),
          // Bottom Right
          Align(
            alignment: Alignment.bottomRight,
            child: _cornerBracket(bottomRight: true),
          ),
        ],
      ),
    );
  }

  Widget _cornerBracket({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    const double size = 28;
    const double thickness = 3;
    const color = AppColors.brandBrown;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Horizontal line
          Positioned(
            top: topLeft || topRight ? 0 : null,
            bottom: bottomLeft || bottomRight ? 0 : null,
            left: topLeft || bottomLeft ? 0 : null,
            right: topRight || bottomRight ? 0 : null,
            child: Container(
              width: size,
              height: thickness,
              color: color,
            ),
          ),
          // Vertical line
          Positioned(
            top: topLeft || topRight ? 0 : null,
            bottom: bottomLeft || bottomRight ? 0 : null,
            left: topLeft || bottomLeft ? 0 : null,
            right: topRight || bottomRight ? 0 : null,
            child: Container(
              width: thickness,
              height: size,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============ PREDICTING OVERLAY ============
  Widget _buildPredictingOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.terracotta,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: AppColors.accentYellow,
              strokeWidth: 4,
              backgroundColor: AppColors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'PREDICTING...',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============ ACTION BUTTONS (Camera / Gallery) ============
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionButton(
            label: 'Camera',
            onTap: _isPredicting ? null : _openCamera,
          ),
          _actionButton(
            label: 'Gallery',
            onTap: _isPredicting ? null : _openGallery,
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.brandBrown,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}