import 'package:financo/common/app_colors.dart';
import 'package:financo/common/image_resources.dart';
import 'package:financo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:financo/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Redirection logic is handled by the router
      },
      child: Scaffold(
        backgroundColor: AppColors.gray,
        body: Center(
          child: Hero(
            tag: 'logo',
            child: SvgPicture.asset(
              ImageResources.financoLogo,
              height: 60,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
