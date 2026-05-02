import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// Cinematic splash screen with concentric rings and product hero.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
              // ── Concentric Rings + Watch ──────────────────────
              _buildHeroSection(),
              const SizedBox(height: 48),
              // ── Title ─────────────────────────────────────────
              Text(
                AppStrings.splashTitle,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
              Text(
                AppStrings.splashBold,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2),
              const SizedBox(height: 16),
              Text(
                AppStrings.splashSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
              const SizedBox(height: 48),
              // ── Get Started Button ────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/sign-up'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cardDark.withValues(alpha: 0.8),
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.getStarted,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 600.ms).slideY(begin: 0.3),
              const SizedBox(height: 20),
              // ── Log In Link ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${AppStrings.alreadyHaveAccount}  ',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/sign-in'),
                    child: const Text(
                      AppStrings.logIn,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8)),
          // Middle ring
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),
          // Watch image placeholder
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A2A4A), Color(0xFF0A1525)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.watch,
                size: 80,
                color: Color(0xFFD4A574),
              ),
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
        ],
      ),
    );
  }
}
