import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class InsightDetailPage extends StatelessWidget {
  final String title;
  final String detail;
  final Color themeColor;

  const InsightDetailPage({
    super.key,
    required this.title,
    required this.detail,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        forceMaterialTransparency: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: AppTypography.headline3SemiBold.copyWith(
            color: AppColors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Strategic Plan",
                style: AppTypography.headline1Bold.copyWith(
                  color: themeColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              GptMarkdown(
                detail,
                style: AppTypography.headline2Regular.copyWith(
                  color: AppColors.gray20,
                  height: 1.6,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              // Decorative element
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: themeColor.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: themeColor),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "This plan is generated based on your current portfolio data and market trends.",
                        style: TextStyle(color: Colors.white54, fontSize: 13),
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
}
