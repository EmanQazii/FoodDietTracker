import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'upload_screen.dart';
import 'record_screen.dart';
import 'profile_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = false;

  // summary
  int _totalMeals = 0;
  double _averageCalories = 0;
  int _highCalorieMeals = 0;

  // weekly
  final List<String> _dayLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];
  List<double> _weeklyCalories = List.filled(7, 0);
  int _daysLogged = 0;

  // meal types
  int _breakfast = 0;
  int _lunch = 0;
  int _dinner = 0;
  int _snack = 0;

  // unhealthy
  List<Map<String, dynamic>> _unhealthyMeals = [];

  static const double _dailyGoal = 2000;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final overview = await ApiService.fetchAnalyticsOverview();
      if (overview.containsKey('error')) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final summary = overview['summary'] as Map<String, dynamic>? ?? {};
      final weekly = overview['weekly'] as List<dynamic>? ?? [];
      final unhealthy = overview['unhealthy'] as List<dynamic>? ?? [];
      final mealTypes = overview['meal_types'] as Map<String, dynamic>? ?? {};

      _totalMeals = summary['total_meals'] ?? 0;
      _averageCalories = (summary['average_calories'] as num?)?.toDouble() ?? 0;
      _highCalorieMeals = summary['high_calorie_meals'] ?? 0;

      final calSlots = List.filled(7, 0.0);
      int daysLogged = 0;
      for (final log in weekly) {
        if (log['log_date'] == null) continue;
        try {
          final dt = DateTime.parse(log['log_date']);
          final slot = dt.weekday % 7;
          calSlots[slot] = (log['total_calorie_max'] as num?)?.toDouble() ?? 0;
          if (((log['meal_count'] as num?)?.toInt() ?? 0) > 0) daysLogged++;
        } catch (_) {}
      }
      _weeklyCalories = calSlots;
      _daysLogged = daysLogged;

      _breakfast = (mealTypes['breakfast'] as num?)?.toInt() ?? 0;
      _lunch = (mealTypes['lunch'] as num?)?.toInt() ?? 0;
      _dinner = (mealTypes['dinner'] as num?)?.toInt() ?? 0;
      _snack = (mealTypes['snack'] as num?)?.toInt() ?? 0;

      _unhealthyMeals =
          unhealthy
              .take(5)
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── health score (0–100) ──────────────────────────────────
  double get _healthScore {
    // 50% from days logged (7 days = full score)
    final logScore = (_daysLogged / 7).clamp(0.0, 1.0) * 50;
    // 50% from avg calories vs 2000 goal
    double calScore;
    if (_averageCalories == 0) {
      calScore = 0;
    } else if (_averageCalories <= _dailyGoal) {
      calScore = 50;
    } else {
      // penalise proportionally up to 2x goal
      final excess = ((_averageCalories - _dailyGoal) / _dailyGoal).clamp(
        0.0,
        1.0,
      );
      calScore = (1 - excess) * 50;
    }
    return (logScore + calScore).clamp(0.0, 100.0);
  }

  String get _healthLabel {
    final s = _healthScore;
    if (s >= 80) return 'Excellent';
    if (s >= 60) return 'Good';
    if (s >= 40) return 'Fair';
    return 'Needs Work';
  }

  Color get _healthColor {
    final s = _healthScore;
    if (s >= 80) return AppColors.sageGreen;
    if (s >= 60) return Colors.orange;
    return AppColors.terracotta;
  }

  String get _healthInsight {
    final s = _healthScore;
    if (s >= 80) {
      return 'Great work! You are logging consistently and keeping calories balanced. Keep it up.';
    }
    if (s >= 60) {
      if (_daysLogged < 5)
        return 'Try logging every day — consistency is half the battle.';
      return 'Your calorie average is a bit high. Aim to stay under ${_dailyGoal.toInt()} kcal per meal.';
    }
    if (s >= 40) {
      return 'You logged $_daysLogged out of 7 days. Even logging once a day builds a strong habit.';
    }
    return 'Start by logging at least 3 meals this week. Small steps add up.';
  }

  // ── weekly insight ────────────────────────────────────────
  String get _weeklyInsight {
    final nonZero = _weeklyCalories.where((v) => v > 0).toList();
    if (nonZero.isEmpty)
      return 'No meals logged this week yet. Start tracking to see your trends.';

    final maxVal = _weeklyCalories.reduce((a, b) => a > b ? a : b);
    final maxDay = _dayLabels[_weeklyCalories.indexOf(maxVal)];
    final overGoalDays = _weeklyCalories.where((v) => v > _dailyGoal).length;
    final avgWeekly = nonZero.reduce((a, b) => a + b) / nonZero.length;

    if (overGoalDays == 0) {
      return 'All logged days stayed under your ${_dailyGoal.toInt()} kcal goal. Well done!';
    }
    if (overGoalDays == 1) {
      return '$maxDay was your highest day at ${maxVal.toInt()} kcal - slightly over your ${_dailyGoal.toInt()} kcal goal. Watch portion sizes that day.';
    }
    return '$overGoalDays days exceeded your ${_dailyGoal.toInt()} kcal goal. Your average this week was ${avgWeekly.toInt()} kcal. Try lighter options mid-week.';
  }

  // ── meal type insight ─────────────────────────────────────
  String get _mealTypeInsight {
    if (_mealTypeTotal == 0) return 'No meal data yet.';
    final counts = {
      'Breakfast': _breakfast,
      'Lunch': _lunch,
      'Dinner': _dinner,
      'Snack': _snack,
    };
    final heaviest = counts.entries.reduce((a, b) => a.value > b.value ? a : b);
    final lowest =
        counts.entries.where((e) => e.value > 0).isEmpty
            ? null
            : counts.entries
                .where((e) => e.value > 0)
                .reduce((a, b) => a.value < b.value ? a : b);

    String msg =
        '${heaviest.key} is your most logged meal (${heaviest.value} times). ';
    if (lowest != null && lowest.key != heaviest.key) {
      msg +=
          'You log ${lowest.key.toLowerCase()} least - consider tracking it more regularly.';
    }
    return msg;
  }

  // ── unhealthy insight ─────────────────────────────────────
  String get _unhealthyInsight {
    if (_unhealthyMeals.isEmpty)
      return 'No high-calorie meals found. Excellent discipline!';
    if (_unhealthyMeals.length == 1)
      return 'You had 1 high-calorie meal this period. Keep an eye on it next time.';
    return 'You had ${_unhealthyMeals.length} high-calorie meals (above 500 kcal). Try swapping one of these for a lighter alternative next week.';
  }

  int get _mealTypeTotal => _breakfast + _lunch + _dinner + _snack;

  String _pct(int val) {
    if (_mealTypeTotal == 0) return '0%';
    return '${((val / _mealTypeTotal) * 100).round()}%';
  }

  // ── build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientTop,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brandBrown,
                        ),
                      )
                      : RefreshIndicator(
                        color: AppColors.brandBrown,
                        backgroundColor: AppColors.white,
                        onRefresh: _loadAll,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 20),
                              _buildStatCards(),
                              const SizedBox(height: 16),
                              _buildHealthScore(),
                              const SizedBox(height: 16),
                              _buildWeeklyChart(),
                              const SizedBox(height: 16),
                              _buildMealTypePie(),
                              const SizedBox(height: 16),
                              _buildUnhealthyCard(),
                              const SizedBox(height: 8),
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

  // ── header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
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
          'Analytics',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.brandBrown,
          ),
        ),
      ],
    );
  }

  // ── stat cards ────────────────────────────────────────────
  Widget _buildStatCards() {
    return Row(
      children: [
        _statCard(
          'Total\nMeals',
          '$_totalMeals',
          Icons.restaurant_menu_rounded,
          AppColors.white,
        ),
        const SizedBox(width: 10),
        _statCard(
          'Avg\nCalories',
          '${_averageCalories.toInt()} kcal',
          Icons.local_fire_department_rounded,
          AppColors.white,
        ),
        const SizedBox(width: 10),
        _statCard(
          'Days\nLogged',
          '$_daysLogged / 7',
          Icons.calendar_today_rounded,
          AppColors.white,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkSage,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.white.withOpacity(0.85), size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.white.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── health score ring ─────────────────────────────────────
  Widget _buildHealthScore() {
    final score = _healthScore;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('HEALTH SCORE THIS WEEK'),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 8,
                        backgroundColor: AppColors.gradientMiddle,
                        color: _healthColor,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${score.toInt()}',
                          style: GoogleFonts.montserrat(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _healthColor,
                          ),
                        ),
                        Text(
                          '/ 100',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _healthColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _healthLabel,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _healthColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 6,
                          color: AppColors.sageGreen.withOpacity(0.4),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$_daysLogged/7 days logged',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 6,
                          color: AppColors.sageGreen.withOpacity(0.4),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Avg ${_averageCalories.toInt()} kcal vs ${_dailyGoal.toInt()} goal',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _insightBox(_healthInsight, _healthColor),
        ],
      ),
    );
  }

  // ── weekly bar chart ──────────────────────────────────────
  Widget _buildWeeklyChart() {
    final maxY =
        _weeklyCalories.isEmpty
            ? 2500.0
            : (_weeklyCalories.reduce((a, b) => a > b ? a : b) * 1.25).clamp(
              500.0,
              double.infinity,
            );

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('CALORIES THIS WEEK'),
          const SizedBox(height: 2),
          Text(
            'Daily goal: ${_dailyGoal.toInt()} kcal  •  Red bar = over goal',
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: AppColors.accentYellow,
                    getTooltipItem:
                        (group, _, rod, __) => BarTooltipItem(
                          '${rod.toY.toInt()} kcal',
                          GoogleFonts.montserrat(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: maxY / 4,
                      getTitlesWidget: (val, _) {
                        if (val == 0) return const SizedBox.shrink();
                        final t =
                            val >= 1000
                                ? '${(val / 1000).toStringAsFixed(1)}k'
                                : val.toInt().toString();
                        return Text(
                          t,
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandBrown,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, _) {
                        final i = val.toInt();
                        if (i < 0 || i >= _dayLabels.length)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _dayLabels[i],
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandBrown,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  horizontalInterval: _dailyGoal,
                  getDrawingHorizontalLine:
                      (_) => FlLine(
                        color: AppColors.sageGreen.withOpacity(0.4),
                        strokeWidth: 1,
                        dashArray: [5, 4],
                      ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final val = _weeklyCalories[i];
                  final overGoal = val > _dailyGoal;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        color:
                            val == 0
                                ? AppColors.textLight.withOpacity(0.2)
                                : overGoal
                                ? AppColors.terracotta
                                : AppColors.sageGreen,
                        width: 14,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _insightBox(_weeklyInsight, AppColors.darkSage),
        ],
      ),
    );
  }

  // ── meal type pie ─────────────────────────────────────────
  Widget _buildMealTypePie() {
    final hasData = _mealTypeTotal > 0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('MEAL TYPE BREAKDOWN'),
          const SizedBox(height: 2),
          Text(
            'Distribution across all logged meals',
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 14),
          hasData
              ? Row(
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 36,
                            startDegreeOffset: -90,
                            sections: [
                              _pieSection(_breakfast, AppColors.terracotta),
                              _pieSection(_lunch, AppColors.sageGreen),
                              _pieSection(_dinner, AppColors.accentYellow),
                              _pieSection(_snack, AppColors.textLight),
                            ],
                          ),
                        ),
                        Text(
                          '$_totalMeals\nmeals',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _pieRow(
                          AppColors.terracotta,
                          'Breakfast',
                          _breakfast,
                          _pct(_breakfast),
                        ),
                        const SizedBox(height: 8),
                        _pieRow(
                          AppColors.sageGreen,
                          'Lunch',
                          _lunch,
                          _pct(_lunch),
                        ),
                        const SizedBox(height: 8),
                        _pieRow(
                          AppColors.accentYellow,
                          'Dinner',
                          _dinner,
                          _pct(_dinner),
                        ),
                        const SizedBox(height: 8),
                        _pieRow(
                          AppColors.textLight,
                          'Snack',
                          _snack,
                          _pct(_snack),
                        ),
                      ],
                    ),
                  ),
                ],
              )
              : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No meal data yet.',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 12),
          if (hasData) _insightBox(_mealTypeInsight, AppColors.accentYellow),
        ],
      ),
    );
  }

  PieChartSectionData _pieSection(int value, Color color) =>
      PieChartSectionData(
        value: value.toDouble(),
        color: color,
        radius: 20,
        showTitle: false,
      );

  Widget _pieRow(Color color, String label, int count, String pct) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.brandBrown,
            ),
          ),
        ),
        Text(
          '$count  ',
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: AppColors.textMedium,
          ),
        ),
        Text(
          pct,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.brandBrown,
          ),
        ),
      ],
    );
  }

  // ── unhealthy meals ───────────────────────────────────────
  Widget _buildUnhealthyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSage,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'WATCH OUT FOR THESE',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sageGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '>500 kcal',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'High-calorie meals from your history',
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: AppColors.white.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 12),
          _unhealthyMeals.isEmpty
              ? Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No high-calorie meals recorded!',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              )
              : Column(
                children:
                    _unhealthyMeals.map((m) => _unhealthyRowDark(m)).toList(),
              ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accentYellow.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accentYellow.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.accentYellow,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _unhealthyInsight,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unhealthyRowDark(Map<String, dynamic> m) {
    final label =
        (m['food_label'] ?? 'Unknown')
            .toString()
            .replaceAll('_', ' ')
            .toUpperCase();
    final cal = m['calorie_max'] ?? 0;
    final cat = m['calorie_category'] ?? '';
    String dateStr = '';
    if (m['meal_date'] != null) {
      try {
        final dt = DateTime.parse(m['meal_date']);
        dateStr = '${dt.day}/${dt.month}';
      } catch (_) {}
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sageGreen.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.sageGreen.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.accentYellow,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  cat,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: AppColors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$cal kcal',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentYellow,
                ),
              ),
              Text(
                dateStr,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: AppColors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── insight box (reusable) ────────────────────────────────
  Widget _insightBox(String text, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: accentColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── shared card ───────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }

  Widget _cardTitle(String t) {
    return Text(
      t,
      style: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.brandBrown,
        letterSpacing: 0.8,
      ),
    );
  }

  // ── bottom nav ────────────────────────────────────────────
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
          _navIcon(Icons.home_outlined, 0),
          _navIcon(Icons.menu_book_outlined, 1),
          _addButton(),
          _navIcon(Icons.bar_chart_rounded, 3, selected: true),
          _navIcon(Icons.person_outline, 4),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, int index, {bool selected = false}) {
    return GestureDetector(
      onTap: () {
        if (index == 0)
          Navigator.pop(context);
        else if (index == 1)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RecordsScreen()),
          );
        else if (index == 4)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
      },
      child: Icon(
        icon,
        color: selected ? AppColors.white : AppColors.white.withOpacity(0.5),
        size: 28,
      ),
    );
  }

  Widget _addButton() {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UploadScreen(mealType: 'lunch'),
            ),
          ),
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
