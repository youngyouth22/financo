import 'dart:ui';

import 'package:financo/common/app_colors.dart';
import 'package:flutter/material.dart';

class ColoredStackGradient extends StatelessWidget {
  const ColoredStackGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
      child: Opacity(
        opacity: 0.20,
        child: Stack(
          children: [
            Align(
              alignment: AlignmentGeometry.centerRight,
              child: Container(
                height: 200,
                margin: const EdgeInsets.only(top: 200),
                width: MediaQuery.of(context).size.width * 0.4,
                decoration: BoxDecoration(
                  color: AppColors.primary20,
                  borderRadius: BorderRadius.circular(2000),
                ),
              ),
            ),
            Align(
              alignment: AlignmentGeometry.centerLeft,
              child: Container(
                height: 150,
                margin: const EdgeInsets.only(top: 100),
                width: MediaQuery.of(context).size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentS,
                ),
              ),
            ),
            Align(
              alignment: AlignmentGeometry.centerRight,
              child: Container(
                height: 200,
                margin: const EdgeInsets.only(top: 100),
                width: MediaQuery.of(context).size.width * 0.7,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2000),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Stack(
//             children: [
//               const Align(
//                 alignment: Alignment.centerRight,
//                 child: ColoredStackGradient(),
//               ),
//               // Background image with gradient overlay
//               Transform.scale(
//                 scale: 3.4,
//                 child: ShaderMask(
//                   shaderCallback: (Rect bounds) {
//                     return LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [
//                         Colors.black.withValues(alpha: 1.0),
//                         Colors.black.withValues(alpha: 0.0),
//                       ],
//                     ).createShader(bounds);
//                   },
//                   blendMode: BlendMode.dstIn,
//                   child: ConstrainedBox(
//                     constraints: const BoxConstraints(maxHeight: 350),
//                     child: SvgPicture.asset(
//                       ImageResources.grilledSvg,
//                       colorFilter: ColorFilter.mode(
//                         AppColors.white,
//                         BlendMode.srcIn,
//                       ),
//                       fit: BoxFit.fitWidth,
//                     ),
//                   ),
//                 ),
//               ),
//               Transform.translate(
//                 offset: const Offset(0, -20),
//                 child: Opacity(
//                   opacity: 0.7,
//                   child: Image.asset(ImageResources.star, fit: BoxFit.fitWidth),
//                 ),
//               ),
//               ImageFiltered(
//                 imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
//                 child: Transform(
//                   alignment: Alignment.topRight,
//                   transform: Matrix4.identity()
//                     ..translateByDouble(100.0, -100, 0.0, 1.0)
//                     ..rotateZ(-0.6),

//                   child: Container(
//                     width: MediaQuery.of(context).size.width * 0.7,
//                     height: 250,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           Colors.white.withValues(alpha: 0.0),
//                           Colors.white.withValues(alpha: 0.04),
//                           Colors.white.withValues(alpha: 0.2),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               SafeArea(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       // App logo or icon
//                       const Icon(
//                         Icons.account_balance_wallet,
//                         size: 100,
//                         color: Colors.blue,
//                       ),
//                       const SizedBox(height: 32),

//                       // App title
//                       const Text(
//                         'Financo',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 36,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 8),

//                       // App subtitle
//                       const Text(
//                         'Manage your wealth with ease',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(fontSize: 16, color: Colors.grey),
//                       ),
//                       const SizedBox(height: 64),

//                       // Google Sign-In button
//                       ElevatedButton.icon(
//                         onPressed: state is AuthLoading
//                             ? null
//                             : () {
//                                 context.read<AuthBloc>().add(
//                                   const AuthGoogleSignInRequested(),
//                                 );
//                               },
//                         icon: Image.asset(
//                           'assets/icons/google_logo.png',
//                           height: 24,
//                           width: 24,
//                           errorBuilder: (context, error, stackTrace) {
//                             // Fallback to icon if image not found
//                             return const Icon(Icons.login, size: 24);
//                           },
//                         ),
//                         label: const Text(
//                           'Sign in with Google',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 24),

//                       // Terms and privacy notice
//                       const Text(
//                         'By signing in, you agree to our Terms of Service and Privacy Policy',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(fontSize: 12, color: Colors.grey),
//                       ),

//                       // Show error state if needed
//                       if (state is AuthError) ...[
//                         const SizedBox(height: 24),
//                         Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: Colors.red.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(
//                               color: Colors.red.withOpacity(0.3),
//                             ),
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(
//                                 Icons.error_outline,
//                                 color: Colors.red,
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Text(
//                                   state.message,
//                                   style: const TextStyle(
//                                     color: Colors.red,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           )