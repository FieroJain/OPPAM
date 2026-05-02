import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/cubit/auth_cubit.dart';

/// System settings screen.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(context),
              _buildProfileCard(),
              _buildSectionTitle(AppStrings.general),
              _buildGeneralSection(context),
              _buildSectionTitle(AppStrings.preferencesData),
              _buildPreferencesSection(),
              const SizedBox(height: 24),
              _buildLogout(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Text(
              AppStrings.systemSettings,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              AppStrings.help,
              style: TextStyle(
                color: AppColors.blueFg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.cardDark,
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.blueFg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.cardDark,
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Robert Fox',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Caregiver | Primary Account',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'System Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildGeneralSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _SettingsTile(
              icon: Icons.person,
              title: AppStrings.profileInfo,
              subtitle: AppStrings.profileInfoDesc,
              onTap: () {},
            ),
            const Divider(height: 1, color: AppColors.glassBorder, indent: 56),
            _SettingsTile(
              icon: Icons.location_on,
              title: AppStrings.geofenceConfig,
              subtitle: AppStrings.geofenceConfigDesc,
              onTap: () {},
            ),
            const Divider(height: 1, color: AppColors.glassBorder, indent: 56),
            _SettingsTile(
              icon: Icons.watch,
              title: AppStrings.connectedDevices,
              subtitle: AppStrings.connectedDevicesDesc,
              onTap: () {},
            ),
            const Divider(height: 1, color: AppColors.glassBorder, indent: 56),
            _SettingsTile(
              icon: Icons.contacts,
              title: AppStrings.emergencyContacts,
              subtitle: 'Manage your care circle',
              onTap: () => context.push('/contacts'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.glassDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.dark_mode,
                        color: AppColors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.darkMode,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Switch(
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                    activeColor: AppColors.primaryLight,
                    activeTrackColor: AppColors.primaryLight,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.glassBorder, indent: 56),
            _SettingsTile(
              icon: Icons.shield,
              title: AppStrings.privacySecurity,
              onTap: () {},
            ),
            const Divider(height: 1, color: AppColors.glassBorder, indent: 56),
            _SettingsTile(
              icon: Icons.download,
              title: AppStrings.exportHealth,
              subtitle: AppStrings.exportHealthDesc,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogout(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          context.read<AuthCubit>().signOut();
          context.go('/');
        },
        child: Text(
          AppStrings.logOut,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.danger,
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.glassDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
