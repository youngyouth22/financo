import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/common_widgets/primary_button.dart';
import 'package:financo/common/image_resources.dart';
import 'package:financo/core/services/security_service.dart';
import 'package:financo/di/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

void showAddSecurityInSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const AddSecurityInSheet(),
      );
    },
  );
}

class AddSecurityInSheet extends StatefulWidget {
  const AddSecurityInSheet({super.key});

  @override
  State<AddSecurityInSheet> createState() => _AddSecurityInSheetState();
}

class _AddSecurityInSheetState extends State<AddSecurityInSheet> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.gray,
          border: Border(
            top: BorderSide(color: AppColors.gray80.withAlpha(155)),
            left: BorderSide(color: AppColors.gray80.withAlpha(155)),
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12),
            bottom: Radius.circular(12),
          ),
        ),
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              clipBehavior: Clip.hardEdge,
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.black,
                ),
                child: Stack(
                  children: [
                    Transform.scale(
                      scale: 3,
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
                              AppColors.accent,
                              BlendMode.srcIn,
                            ),
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Lottie.asset(
                        ImageResources.securedPin,
                        width: 200,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Text(
                    'Add Security Pin',
                    textAlign: TextAlign.center,
                    style: AppTypography.headline4SemiBold.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For added security, please set up a security pin to protect your account and personal information.',
                    textAlign: TextAlign.center,
                    style: AppTypography.headline2Regular.copyWith(
                      color: AppColors.gray30,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  PrimaryButton(
                    text: 'Set Security Pin',
                    onClick: () async {
                      final securityService = sl<SecurityService>();
                      final result = await securityService.setupSecurity();

                      if (!mounted) return;

                      if (result.success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.message),
                            backgroundColor: Colors.green,
                          ),
                        );
                        context.pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
