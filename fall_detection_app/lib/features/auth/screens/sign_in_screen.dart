import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../cubit/auth_cubit.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: const Color(0xFFFF4B6E),
            ),
          );
        }
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
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.splashGradient,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  IconButton(
                    icon: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 28),
                    onPressed: () => context.go('/'),
                  ),

                  const SizedBox(height: 32),

                  Center(
                    child: Text(
                      AppStrings.logIn,
                      style:
                          Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      'Welcome back to ${AppStrings.appName}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: AppStrings.emailAddress,
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: AppStrings.password,
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state.status ==
                                  AuthStatus.loading
                              ? null
                              : () {
                                  context
                                      .read<AuthCubit>()
                                      .signIn(
                                        email:
                                            _emailController.text,
                                        password:
                                            _passwordController
                                                .text,
                                      );
                                },
                          child: state.status ==
                                  AuthStatus.loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(AppStrings.logIn),
                                    const SizedBox(width: 8),
                                    const Icon(
                                        Icons.arrow_forward,
                                        size: 18),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          context.go('/sign-up'),
                      child: const Text(
                        "Don't have an account? Create Account",
                        style: TextStyle(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
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