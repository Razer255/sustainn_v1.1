import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/mock_data.dart';
import '../../routes/app_router.dart';

class ProfileTab extends StatelessWidget {
  final dynamic user; // UserModel
  final VoidCallback? onProfileUpdated;

  const ProfileTab({super.key, required this.user, this.onProfileUpdated});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.phone,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Account Details'),
                _buildListTile(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  onTap: () async {
                    await Navigator.pushNamed(context, AppRouter.personalInformation);
                    onProfileUpdated?.call();
                  },
                ),
                _buildListTile(
                  icon: Icons.location_on_outlined,
                  title: 'Farm Address',
                  subtitle: (user.region as String).isNotEmpty ? user.region : 'Not provided',
                  onTap: () async {
                    await Navigator.pushNamed(context, AppRouter.personalInformation);
                    onProfileUpdated?.call();
                  },
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Preferences'),
                _buildListTile(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: context.locale.languageCode == 'hi' ? 'हिंदी' : 'English',
                  onTap: () => _showLanguagePicker(context),
                ),
                _buildListTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {},
                ),
                _buildListTile(
                  icon: Icons.security,
                  title: 'Privacy & Security',
                  subtitle: 'Change password',
                  onTap: () => Navigator.pushNamed(context, AppRouter.changePassword),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Support & About'),
                _buildListTile(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  subtitle: 'Report a problem',
                  onTap: () => Navigator.pushNamed(context, AppRouter.reportProblem),
                ),
                _buildListTile(
                  icon: Icons.info_outline,
                  title: 'About Sustainn App',
                  subtitle: 'Version 1.0.0',
                  onTap: () {},
                ),

                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      debugPrint('[ProfileTab] Logout button pressed');
                      try {
                        final authService = Provider.of<AuthService>(context, listen: false);
                        authService.signOut();
                        debugPrint('[ProfileTab] Signed out from AuthService');
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRouter.login,
                          (route) => false,
                        );
                        debugPrint('[ProfileTab] Navigation to login triggered');
                      } catch (e, stack) {
                        debugPrint('[ProfileTab] Logout error: $e\n$stack');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Log out failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                  ),
                ),
                const SizedBox(height: 100), // Bottom padding for nav bar
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose your language',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _buildLanguageOption(sheetContext, const Locale('en'), 'English', 'English'),
                const SizedBox(height: 8),
                _buildLanguageOption(sheetContext, const Locale('hi'), 'हिंदी', 'Hindi'),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, Locale locale, String title, String subtitle) {
    final isSelected = context.locale == locale;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await context.setLocale(locale);
        Navigator.pop(context);

        try {
          await ApiService().updateUser(MockData.currentUser.id, {'language': locale.languageCode});
          MockData.currentUser = MockData.currentUser.copyWith(language: locale.languageCode);
          onProfileUpdated?.call();
        } catch (_) {
          // Locale already switched locally via easy_localization; syncing
          // the preference to the backend is best-effort only.
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border.withOpacity(0.3)),
      ),
      color: AppColors.cardBackground,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
