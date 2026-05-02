import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/glass_card.dart';
import '../cubit/auth_cubit.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() =>
      _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  int _selectedRole = -1;

  static const _roles = [
    _RoleOption(
      icon: Icons.elderly,
      iconBg: Color(0xFFEF4444),
      title: 'Patient',
      subtitle: 'I am the person being monitored',
    ),
    _RoleOption(
      icon: Icons.groups,
      iconBg: Color(0xFF3B82F6),
      title: AppStrings.familyMember,
      subtitle: AppStrings.familyDesc,
    ),
    _RoleOption(
      icon: Icons.medical_services,
      iconBg: AppColors.accent,
      title: AppStrings.caregiver,
      subtitle: AppStrings.caregiverDesc,
    ),
    _RoleOption(
      icon: Icons.health_and_safety,
      iconBg: Color(0xFFA855F7),
      title: AppStrings.medicalPro,
      subtitle: AppStrings.medicalProDesc,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          if (state.isPatient) {
            context.go('/patient');
          } else {
            context.go('/dashboard');
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.splashGradient,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  Text(
                    AppStrings.whoAreYou,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium,
                  ),

                  const SizedBox(height: 24),

                  Column(
                    children: List.generate(
                      _roles.length,
                      (i) {
                        final role = _roles[i];
                        final selected =
                            _selectedRole == i;

                        return Padding(
                          padding:
                              const EdgeInsets.only(
                                  bottom: 12),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() =>
                                    _selectedRole =
                                        i),
                            child: GlassCard(
                              borderColor: selected
                                  ? AppColors.accent
                                  : AppColors
                                      .glassBorder,
                              padding:
                                  const EdgeInsets
                                      .all(18),
                              child: Row(
                                children: [
                                  Icon(role.icon,
                                      color:
                                          role.iconBg),
                                  const SizedBox(
                                      width: 16),
                                  Expanded(
                                    child: Text(
                                      role.title,
                                      style:
                                          const TextStyle(
                                        color: Colors
                                            .white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Password',
                    ),
                  ),

                  const SizedBox(height: 24),

                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state.status ==
                                AuthStatus.loading
                            ? null
                            : () {
                                final roleName =
                                    _selectedRole >=
                                            0
                                        ? _roles[
                                                _selectedRole]
                                            .title
                                        : 'Family Member';

                                context
                                    .read<AuthCubit>()
                                    .signUp(
                                      email:
                                          _emailController
                                              .text,
                                      password:
                                          _passwordController
                                              .text,
                                      role: roleName,
                                    );
                              },
                        child: state.status ==
                                AuthStatus.loading
                            ? const CircularProgressIndicator(
                                color:
                                    Colors.white)
                            : const Text(
                                'Create Account'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOption {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;

  const _RoleOption({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });
}