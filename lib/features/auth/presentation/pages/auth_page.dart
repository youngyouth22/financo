import 'dart:ui';

import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_spacing.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/common_widgets/primary_button.dart';
import 'package:financo/common/image_resources.dart';
import 'package:financo/di/injection_container.dart';
import 'package:financo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:financo/features/auth/presentation/bloc/auth_event.dart';
import 'package:financo/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

/// Authentication page for user login.
///
/// This page provides Google Sign-In functionality and handles
/// authentication state changes through the AuthBloc.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.gray,
        systemNavigationBarColor: AppColors.gray,
      ),
      child: Scaffold(
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            // Show error message if authentication fails
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          builder: (context, state) {
          
            // Main authentication UI
            return Stack(
              children: [
                Transform.scale(
                  scale: 3.4,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 1.0),
                          Colors.black.withValues(alpha: 0.0),
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 350),
                      child: SvgPicture.asset(
                        ImageResources.grilledSvg,
                        colorFilter: ColorFilter.mode(
                          AppColors.white,
                          BlendMode.srcIn,
                        ),
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Opacity(
                    opacity: 0.7,
                    child: Image.asset(
                      ImageResources.star,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Transform(
                    alignment: Alignment.topRight,
                    transform: Matrix4.identity()
                      ..translateByDouble(100.0, -100, 0.0, 1.0)
                      ..rotateZ(-0.6),

                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: 250,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.04),
                            Colors.white.withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: AppSpacing.twenty,
                      children: [
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color.fromARGB(255, 247, 192, 184),
                                AppColors.accent,
                              ],
                            ).createShader(bounds);
                          },
                          child: SvgPicture.asset(
                            ImageResources.financoLogo,
                            height: 40,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        Text(
                          'Welcome to Financo',
                          style: AppTypography.headline6Bold.copyWith(
                            color: AppColors.white,
                            height: 1.3,
                            letterSpacing: 1,
                          ),
                        ),
                        RichText(
                          textAlign: TextAlign.center,

                          text: TextSpan(
                            text: 'By clicking , you agree to our',
                            style: AppTypography.headline2Medium.copyWith(
                              color: AppColors.white,
                              height: 1.6,
                            ),
                            children: [
                              TextSpan(
                                text: ' Terms of Service ',
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Handle tap on Privacy Policy
                                  },
                                style: AppTypography.headline2Medium.copyWith(
                                  color: const Color(0xFF4D81E7),
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: ' Privacy Policy',
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Handle tap on Privacy Policy
                                  },
                                style: AppTypography.headline2Medium.copyWith(
                                  color: const Color(0xFF4D81E7),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox.shrink(),

                        PrimaryButton(
                          text: 'Continue with Google',
                          icon: SvgPicture.asset(
                            ImageResources.googleIcon,
                            colorFilter: ColorFilter.mode(
                              AppColors.gray,
                              BlendMode.srcIn,
                            ),
                            height: 24,
                          ),
                          border: Border.all(color: AppColors.white),
                          color: AppColors.white,
                          textColor: AppColors.gray,
                          loading: state is AuthLoading,
                          onClick: () {
                            sl<AuthBloc>().add(
                              const AuthGoogleSignInRequested(),
                            );
                          },
                        ),
                        PrimaryButton(
                          text: 'Continue with Apple',
                          icon: SvgPicture.asset(
                            ImageResources.appleIcon,
                            colorFilter: ColorFilter.mode(
                              AppColors.white,
                              BlendMode.srcIn,
                            ),
                            height: 24,
                          ),
                          border: const Border(
                            top: BorderSide(
                              color: Color.fromARGB(255, 18, 18, 18),
                              width: 2,
                            ),
                            left: BorderSide(
                              color: Color.fromARGB(255, 18, 18, 18),
                              width: 1,
                            ),
                            right: BorderSide(
                              color: Color.fromARGB(255, 18, 18, 18),
                              width: 1,
                            ),
                          ),
                          gradient: const LinearGradient(
                            begin: AlignmentGeometry.topCenter,
                            end: AlignmentGeometry.bottomCenter,
                            colors: [
                              Colors.black,
                              Color.fromARGB(255, 12, 12, 12),
                              Colors.black,
                            ],
                          ),
                          onClick: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
