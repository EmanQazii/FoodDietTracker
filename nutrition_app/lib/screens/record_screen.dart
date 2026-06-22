import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'meal_detail_screen.dart';
import 'upload_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  // ============ DYNAMIC MEALS ============
  List<dynamic> _allMeals = [];
  List<dynamic> _filteredMeals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMeals();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMeals() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final meals = await ApiService.fetchMeals();
      if (!mounted) return;
      setState(() {
        _allMeals = meals;
        _filteredMeals = meals;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print('Error loading records: $e');
    }
  }

  // ============ FILTER LOGIC ============
  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      _filteredMeals =
          _allMeals.where((meal) {
            // Search filter
            final name = (meal['food_label'] ?? '').toString().toLowerCase();
            final mealType = (meal['meal_type'] ?? '').toString().toLowerCase();
            final matchesSearch =
                query.isEmpty ||
                name.contains(query) ||
                mealType.contains(query);

            // Date filter
            bool matchesDate = true;
            if (_selectedDate != null && meal['created_at'] != null) {
              try {
                final createdAt = DateTime.parse(meal['created_at']);
                matchesDate =
                    createdAt.year == _selectedDate!.year &&
                    createdAt.month == _selectedDate!.month &&
                    createdAt.day == _selectedDate!.day;
              } catch (_) {
                matchesDate = false;
              }
            }

            return matchesSearch && matchesDate;
          }).toList();
    });
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ============ DATE PICKER ============
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandBrown,
              onPrimary: AppColors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _applyFilters();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
    _applyFilters();
  }

  // ============ RECORD TAP ============
  void _onRecordTap(dynamic meal) {
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
            : '';

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
              image: imageUrl,
            ),
      ),
    ).then((updated) {
      if (mounted && updated == true) {
        _loadMeals();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientTop,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar + Calendar
            _buildSearchBar(),

            // Date filter chip (shows when date is selected)
            if (_selectedDate != null) _buildDateChip(),

            // Records list
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brandBrown,
                        ),
                      )
                      : _filteredMeals.isEmpty
                      ? _buildEmptyState()
                      : _buildRecordsList(),
            ),

            // Bottom nav bar
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  // ============ SEARCH BAR ============
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brandBrown,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandBrown.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Search field
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.gradientMiddle,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search, color: AppColors.white, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search Old Record',
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white.withOpacity(0.8),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Calendar button
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brandBrown, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.brandBrown,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ DATE FILTER CHIP ============
  Widget _buildDateChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandBrown,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDate(_selectedDate!),
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _clearDateFilter,
                  child: const Icon(
                    Icons.close,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '${_filteredMeals.length} records',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ============ RECORDS LIST ============
  Widget _buildRecordsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      itemCount: _filteredMeals.length,
      itemBuilder: (context, index) {
        return _buildRecordCard(_filteredMeals[index]);
      },
    );
  }

  Widget _buildRecordCard(dynamic meal) {
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
      onTap: () => _onRecordTap(meal),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Meal image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: AppColors.gradientTop,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
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

            // Meal name + date + meal type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$dateStr, $mealType',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),

            // Calories
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

  // ============ EMPTY STATE ============
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No records found',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try changing your search or date filter',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
        ],
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
    final bool isSelected = index == 1;
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.pop(context);
        } else if (index == 1) {
          // already on Records
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
          );
        } else if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
      },
      child: Icon(
        icon,
        color: isSelected ? AppColors.white : AppColors.white.withOpacity(0.7),
        size: 28,
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UploadScreen(mealType: 'lunch'),
          ),
        );
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
