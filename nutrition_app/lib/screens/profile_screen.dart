import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'upload_screen.dart';
import 'splash_screen.dart';
import 'analytics_screen.dart';
import 'record_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = '';
  String _email = '';
  int _totalMealsLogged = 0;
  int _totalCalories = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _username = ApiService.username.isNotEmpty ? ApiService.username : 'User';
    _email = ApiService.email.isNotEmpty ? ApiService.email : 'user@example.com';
    _loadProfileStats();
  }

  Future<void> _loadProfileStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final summary = await ApiService.fetchAnalyticsSummary();
      final weekly  = await ApiService.fetchAnalyticsWeekly(); // now a List

      double sumCalories = 0;
      for (final log in weekly) {
        sumCalories += (log['total_calorie_max'] as num?)?.toDouble() ?? 0.0;
      }

      if (!mounted) return;
      setState(() {
        _totalMealsLogged = summary['total_meals'] ?? 0;
        _totalCalories    = sumCalories.toInt();
        _isLoading        = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Error loading profile stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientTop,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.brandBrown))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBackButton(),
                          const SizedBox(height: 12),
                          _buildProfileCard(),
                          const SizedBox(height: 16),
                          _buildStatsCard(),
                          const SizedBox(height: 16),
                          _buildSettingsCard(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            ),
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  // ── back button ───────────────────────────────────────────
  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.brandBrown, width: 1.5),
        ),
        child: const Icon(Icons.arrow_back,
            color: AppColors.brandBrown, size: 18),
      ),
    );
  }

  // ── profile card ──────────────────────────────────────────
  Widget _buildProfileCard() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 50),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.gradientMiddle.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoField('USERNAME:', _username),
              const SizedBox(height: 12),
              _buildInfoField('EMAIL:', _email),
              const SizedBox(height: 12),
              _buildInfoField('PASSWORD:', '••••••••••••'),
            ],
          ),
        ),
        Positioned(
          top: 0,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gradientTop,
              border: Border.all(color: AppColors.white, width: 4),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: ClipOval(
              child: Container(
                color: AppColors.gradientMiddle,
                child: const Icon(Icons.person,
                    size: 60, color: AppColors.brandBrown),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.brandBrown,
              letterSpacing: 0.8,
            )),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Center(
            child: Text(value,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                )),
          ),
        ),
      ],
    );
  }

  // ── stats card ────────────────────────────────────────────
  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gradientMiddle.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoField('TOTAL MEALS LOGGED:', '$_totalMealsLogged'),
          const SizedBox(height: 12),
          _buildInfoField(
              'TOTAL CALORIES THIS WEEK:', _formatNumber(_totalCalories)),
        ],
      ),
    );
  }

  String _formatNumber(int n) => n
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ── settings card ─────────────────────────────────────────
  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gradientMiddle.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings,
                  color: AppColors.terracotta, size: 20),
              const SizedBox(width: 8),
              Text('SETTINGS',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandBrown,
                    letterSpacing: 1,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
              label: 'CHANGE PASSWORD',
              onTap: _showChangePasswordDialog),
          const Divider(color: AppColors.textLight, height: 1),
          _buildSettingsItem(
              label: 'UPDATE EMAIL', onTap: _showUpdateEmailDialog),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 180,
              height: 42,
              child: ElevatedButton(
                onPressed: _showLogoutDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                ),
                child: Text('LOG OUT',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
      {required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandBrown,
                  letterSpacing: 0.5,
                )),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.brandBrown, size: 14),
          ],
        ),
      ),
    );
  }

  // ── change password dialog ────────────────────────────────
  void _showChangePasswordDialog() {
    final currentCtrl  = TextEditingController();
    final newCtrl      = TextEditingController();
    final confirmCtrl  = TextEditingController();
    final formKey      = GlobalKey<FormState>();
    bool obscureCurrent = true, obscureNew = true, obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, set) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.gradientTop,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.lock_outline_rounded,
                        color: AppColors.terracotta, size: 24),
                    const SizedBox(width: 8),
                    Text('Change Password',
                        style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandBrown)),
                  ]),
                  const SizedBox(height: 16),
                  _dialogField(
                    label: 'Current Password',
                    ctrl: currentCtrl,
                    obscure: obscureCurrent,
                    onToggle: () =>
                        set(() => obscureCurrent = !obscureCurrent),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Enter current password'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    label: 'New Password',
                    ctrl: newCtrl,
                    obscure: obscureNew,
                    onToggle: () => set(() => obscureNew = !obscureNew),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter new password';
                      if (v.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    label: 'Confirm New Password',
                    ctrl: confirmCtrl,
                    obscure: obscureConfirm,
                    onToggle: () =>
                        set(() => obscureConfirm = !obscureConfirm),
                    validator: (v) => v != newCtrl.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel',
                              style: GoogleFonts.montserrat(
                                  color: AppColors.textMedium,
                                  fontWeight: FontWeight.w600))),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Password updated successfully!'),
                                backgroundColor: AppColors.sageGreen,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sageGreen,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Save',
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── update email dialog ───────────────────────────────────
  void _showUpdateEmailDialog() {
    final emailCtrl = TextEditingController(text: _email);
    final pwdCtrl   = TextEditingController();
    final formKey   = GlobalKey<FormState>();
    bool obscure    = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, set) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.gradientTop,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.email_outlined,
                        color: AppColors.terracotta, size: 24),
                    const SizedBox(width: 8),
                    Text('Update Email',
                        style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandBrown)),
                  ]),
                  const SizedBox(height: 16),
                  _dialogField(
                    label: 'New Email',
                    ctrl: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter an email';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    label: 'Current Password',
                    ctrl: pwdCtrl,
                    obscure: obscure,
                    onToggle: () => set(() => obscure = !obscure),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter password' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel',
                              style: GoogleFonts.montserrat(
                                  color: AppColors.textMedium,
                                  fontWeight: FontWeight.w600))),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            setState(() => _email = emailCtrl.text);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Email updated successfully!'),
                                backgroundColor: AppColors.sageGreen,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sageGreen,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Update',
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── shared dialog field ───────────────────────────────────
  Widget _dialogField({
    required String label,
    required TextEditingController ctrl,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.brandBrown)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            suffixIcon: onToggle != null
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMedium,
                      size: 18,
                    ),
                    onPressed: onToggle,
                  )
                : null,
            errorStyle: GoogleFonts.montserrat(
                fontSize: 11,
                color: AppColors.terracotta,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ── logout dialog ─────────────────────────────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.gradientTop,
        title: Row(children: [
          const Icon(Icons.logout_rounded,
              color: AppColors.terracotta, size: 24),
          const SizedBox(width: 8),
          Text('Log Out',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandBrown)),
        ]),
        content: Text('Are you sure you want to log out?',
            style: GoogleFonts.montserrat(
                fontSize: 14, color: AppColors.textMedium)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMedium))),
          TextButton(
            onPressed: () async {
              await ApiService.clearSession(); // ← clears token properly
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const SplashScreen()),
                (route) => false,
              );
            },
            child: Text('Log Out',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    color: AppColors.terracotta)),
          ),
        ],
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
          _navIcon(Icons.bar_chart_rounded, 3),
          _navIcon(Icons.person, 4, selected: true),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, int index, {bool selected = false}) {
    return GestureDetector(
      onTap: () {
        if (index == 0) Navigator.pop(context);
        if (index == 1) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const RecordsScreen()));
        }
        if (index == 3) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
        }
      },
      child: Icon(icon,
          color: selected
              ? AppColors.accentYellow
              : AppColors.white.withOpacity(0.5),
          size: 28),
    );
  }

  Widget _addButton() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => const UploadScreen(mealType: 'lunch'))),
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
                offset: const Offset(0, 3)),
          ],
        ),
        child: const Icon(Icons.add,
            color: AppColors.brandBrown, size: 28),
      ),
    );
  }
}