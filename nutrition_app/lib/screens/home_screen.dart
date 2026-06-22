import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../main.dart' as app_main;
import 'record_screen.dart';
import 'meal_detail_screen.dart';
import 'upload_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'manual_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int _selectedNavIndex = 0;

  int _consumedCalories = 0;
  final int _totalCalories = 2000;
  List<dynamic> _todayMeals = [];
  bool _isMealsLoading = false;

  final List<Map<String, dynamic>> mealCategories = [
    {'name': 'Breakfast', 'icon': Icons.breakfast_dining},
    {'name': 'Lunch', 'icon': Icons.lunch_dining},
    {'name': 'Dinner', 'icon': Icons.dinner_dining},
    {'name': 'Snack', 'icon': Icons.fastfood},
  ];

  @override
  void initState() {
    super.initState();
    _loadTodaysData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    app_main.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    app_main.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadTodaysData();
  }

  Future<void> _loadTodaysData() async {
    if (!mounted) return;
    setState(() => _isMealsLoading = true);
    try {
      final meals = await ApiService.fetchMeals();
      final today = DateTime.now();

      final todayMeals =
          meals.where((meal) {
            if (meal['created_at'] == null) return false;
            try {
              final createdAt = DateTime.parse(meal['created_at']);
              return createdAt.year == today.year &&
                  createdAt.month == today.month &&
                  createdAt.day == today.day;
            } catch (_) {
              return false;
            }
          }).toList();

      int consumed = 0;
      for (var meal in todayMeals) {
        consumed += (meal['calorie_max'] as num?)?.toInt() ?? 0;
      }

      if (!mounted) return;
      setState(() {
        _todayMeals = todayMeals;
        _consumedCalories = consumed;
        _isMealsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMealsLoading = false);
      debugPrint('Error loading today meals: $e');
    }
  }

  // ============ MEAL CATEGORY TAP ============
  void _onMealCategoryTap(String category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: const BoxDecoration(
              color: AppColors.gradientTop,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log $category',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandBrown,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose how you would like to track this meal:',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 24),
                _buildBottomSheetOption(
                  icon: Icons.camera_alt_rounded,
                  title: 'SCAN WITH CAMERA',
                  subtitle: 'Use AI recognition to identify food automatically',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UploadScreen(mealType: category),
                      ),
                    ).then((_) => _loadTodaysData());
                  },
                ),
                const SizedBox(height: 16),
                _buildBottomSheetOption(
                  icon: Icons.edit_note_rounded,
                  title: 'SEARCH MANUALLY',
                  subtitle: 'Type food name to retrieve from USDA database',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ManualSearchScreen(mealType: category),
                      ),
                    ).then((_) => _loadTodaysData());
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.gradientMiddle.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gradientMiddle, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.terracotta,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandBrown,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.brandBrown,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientTop,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.brandBrown,
                backgroundColor: AppColors.white,
                onRefresh: _loadTodaysData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildTodaysTarget(),
                      const SizedBox(height: 28),
                      _buildMealCategories(),
                      const SizedBox(height: 28),
                      _buildRecentMealsTitle(),
                      const SizedBox(height: 14),
                      _buildRecentMealsList(),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  // ============ HEADER ============
  Widget _buildHeader() {
    final displayUser =
        ApiService.username.isNotEmpty ? ApiService.username : 'User';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Hello, $displayUser',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.brandBrown,
          ),
        ),
        Stack(
          children: [
            const Icon(
              Icons.notifications,
              color: AppColors.brandBrown,
              size: 28,
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============ TODAY'S TARGET ============
  Widget _buildTodaysTarget() {
    final bool exceeded = _consumedCalories > _totalCalories;
    final double ratio = (_consumedCalories / _totalCalories).clamp(0.0, 1.0);
    final int remaining = (_totalCalories - _consumedCalories).clamp(
      0,
      _totalCalories,
    );

    return Center(
      child: Column(
        children: [
          Text(
            "TODAY'S TARGET",
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.brandBrown,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 230,
            height: 140,
            child: CustomPaint(
              painter: _CalorieArcPainter(
                consumedRatio: ratio,
                exceeded: exceeded,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // warning message when exceeded
          if (exceeded)
            Container(
              margin: const EdgeInsets.only(bottom: 8, top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.terracotta.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.terracotta.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.terracotta,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Daily limit exceeded by ${_consumedCalories - _totalCalories} kcal',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.terracotta,
                    ),
                  ),
                ],
              ),
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCalorieInfo(
                '\nConsumed\nCalories',
                '$_consumedCalories kcal',
                exceeded ? AppColors.terracotta : AppColors.textDark,
              ),
              _buildCalorieInfo(
                exceeded ? '\nExceeded\nBy' : '\nRemaining\nCalories',
                exceeded
                    ? '${_consumedCalories - _totalCalories} kcal'
                    : '$remaining kcal',
                exceeded ? AppColors.terracotta : AppColors.textDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieInfo(String label, String value, [Color? color]) {
    final textColor = color ?? AppColors.textDark;
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // ============ MEAL CATEGORIES ============
  Widget _buildMealCategories() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children:
          mealCategories.map((meal) {
            return GestureDetector(
              onTap: () => _onMealCategoryTap(meal['name']),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppColors.sageGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.darkSage.withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          meal['icon'],
                          color: AppColors.white,
                          size: 28,
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.brandBrown,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.gradientTop,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: AppColors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    meal['name'],
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandBrown,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  // ============ RECENT MEALS ============
  Widget _buildRecentMealsTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Today's Logged Meals:",
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.brandBrown,
          ),
        ),
        if (_todayMeals.length > 3)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecordsScreen()),
              );
            },
            child: Text(
              'View all',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.terracotta,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentMealsList() {
    if (_isMealsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.brandBrown),
        ),
      );
    }

    if (_todayMeals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.restaurant_menu_rounded,
                size: 40,
                color: AppColors.brandBrown.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No meals logged today yet.',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
              ),
              Text(
                'Tap a category above to log your food!',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final recentMeals = _todayMeals.take(3).toList();
    return Column(
      children: recentMeals.map((meal) => _buildMealCard(meal)).toList(),
    );
  }

  Widget _buildMealCard(dynamic meal) {
    final name =
        meal['food_label'] != null
            ? meal['food_label'].toString().toUpperCase()
            : 'UNKNOWN';
    final calorieMin = meal['calorie_min'] ?? 0;
    final calorieMax = meal['calorie_max'] ?? 0;
    final caloriesStr = '$calorieMin-$calorieMax Cal';
    final mealType =
        meal['meal_type'] != null
            ? meal['meal_type'].toString().toUpperCase()
            : 'MEAL';

    String dateStr = '';
    if (meal['created_at'] != null) {
      try {
        final dt = DateTime.parse(meal['created_at']);
        dateStr = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {
        dateStr = meal['created_at'].toString().split('T').first;
      }
    }

    final imageUrl =
        meal['image_path'] != null && meal['image_path'].toString().isNotEmpty
            ? '${ApiService.baseUrl}/${meal['image_path']}'
            : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MealDetailScreen(
                  mealId: meal['id'] as int?,
                  name: name,
                  date: dateStr,
                  meal: mealType,
                  calories: caloriesStr,
                  image: imageUrl ?? '',
                ),
          ),
        ).then((updated) {
          if (mounted && updated == true) {
            _loadTodaysData();
          }
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.gradientMiddle,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    imageUrl != null
                        ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.restaurant,
                                color: AppColors.brandBrown,
                              ),
                        )
                        : const Icon(
                          Icons.restaurant,
                          color: AppColors.brandBrown,
                        ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandBrown,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$mealType • $dateStr',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              caloriesStr,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ BOTTOM NAV BAR ============
  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.brandBrown,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(Icons.home_outlined, 0),
          _buildNavIcon(Icons.menu_book_outlined, 1),
          _buildAddButton(),
          _buildNavIcon(Icons.bar_chart_rounded, 3),
          _buildNavIcon(Icons.person_outline, 4),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final bool isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        // update highlight immediately
        setState(() => _selectedNavIndex = index);

        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RecordsScreen()),
          ).then((_) {
            if (!mounted) return;
            _loadTodaysData();
            setState(() => _selectedNavIndex = 0);
          });
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
          ).then((_) {
            if (!mounted) return;
            setState(() => _selectedNavIndex = 0);
          });
        } else if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          ).then((_) {
            if (!mounted) return;
            setState(() => _selectedNavIndex = 0);
          });
        }
        // index 0 — already on home, nothing to push
      },
      child: Icon(
        icon,
        color: isSelected ? AppColors.white : AppColors.white.withOpacity(0.5),
        size: 28,
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        // opens bottom sheet with Breakfast as default so user picks category
        _onMealCategoryTap('Lunch');
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: AppColors.brandBrown, size: 28),
      ),
    );
  }
}

// ============================================================
// CUSTOM PAINTER FOR CALORIE ARC
// ============================================================
class _CalorieArcPainter extends CustomPainter {
  final double consumedRatio;
  final bool exceeded;

  _CalorieArcPainter({required this.consumedRatio, required this.exceeded});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 20;

    final bgPaint =
        Paint()
          ..color = AppColors.gradientMiddle
          ..strokeWidth = 40
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159,
      3.14159,
      false,
      bgPaint,
    );

    final fgPaint =
        Paint()
          ..color = exceeded ? Colors.red.shade600 : AppColors.terracotta
          ..strokeWidth = 40
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159,
      3.14159 * consumedRatio, // clamped to 1.0 so arc stays full but turns red
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
