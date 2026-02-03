import 'dart:async';
import 'dart:math' as math;
import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/features/finance/domain/entities/networth_response.dart';
import 'package:financo/features/insights/presentation/utils/catalog.dart';
import 'package:financo/features/insights/presentation/utils/finance_prompt.dart';
import 'package:financo/features/insights/presentation/bloc/insights_bloc.dart';
import 'package:financo/features/insights/presentation/bloc/insights_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genui/genui.dart';
import 'package:genui_firebase_ai/genui_firebase_ai.dart';

/// Tab 3: Risk & Strategy (The Premium Brain)
/// Uses GenUI to render dynamic financial insights based on real portfolio data.
class RiskStrategyTab extends StatefulWidget {
  const RiskStrategyTab({super.key});

  @override
  State<RiskStrategyTab> createState() => _RiskStrategyTabState();
}

class _RiskStrategyTabState extends State<RiskStrategyTab> {
  late final GenUiConversation _financialConversation;
  bool _aiTriggered = false;

  // --- OFFICIAL GENUI STATE ---
  // List to store active surface IDs received from the AI
  final List<String> _surfaceIds = [];

  @override
  void initState() {
    super.initState();
    _initializeGenUI();
  }

  void _initializeGenUI() {
    // 1. Processor with your widget catalog
    final a2uiMessageProcessor = A2uiMessageProcessor(
      catalogs: [
        CoreCatalogItems.asCatalog().copyWith([insightcatalog]),
      ],
    );

    // 2. Setup the AI generator (Gemini via Firebase)
    final contentGenerator = FirebaseAiContentGenerator(
      catalog: financeAiCatalog,
      systemInstruction: genUiFinancialPrompt,
    );

    // 3. Setup the Conversation Manager with documentation-standard callbacks
    _financialConversation = GenUiConversation(
      contentGenerator: contentGenerator,
      a2uiMessageProcessor: a2uiMessageProcessor,
      // When the AI creates a new UI area
      onSurfaceAdded: (SurfaceAdded update) {
        print("Surface Added: ${update.surfaceId}");
        if (mounted) {
          setState(() {
            if (!_surfaceIds.contains(update.surfaceId)) {
              _surfaceIds.add(update.surfaceId);
            }
          });
        }
      },
      // When the AI updates an existing UI area
      onSurfaceUpdated: (SurfaceUpdated update) {
        if (mounted) {
          setState(() {
            if (!_surfaceIds.contains(update.surfaceId)) {
              _surfaceIds.add(update.surfaceId);
            }
          });
        }
      },
      // When the AI removes a UI area
      onSurfaceDeleted: (SurfaceRemoved update) {
        if (mounted) {
          setState(() {
            _surfaceIds.remove(update.surfaceId);
          });
        }
      },
    );
  }

  /// Silently sends portfolio data to the AI for analysis
  Future<void> _runSilentAiAnalysis(NetworthResponse networth) async {
    if (_aiTriggered || !mounted) return;
    _aiTriggered = true;

    final portfolioData = {
      'total': networth.total.value,
      'diversification': networth.insights.diversificationScore,
      'risk': networth.insights.riskLevel,
      'assets': networth.assets
          .take(10)
          .map((a) => "${a.name} (${a.value} USD)")
          .toList(),
    };

    final prompt =
        "Analyze this portfolio, you should generate UI that displays one new InsightCard : ${portfolioData.toString()}";

    try {
      await _financialConversation.sendRequest(UserMessage.text(prompt));
    } catch (e) {
      debugPrint("GenUI Request Failed: $e");
      if (mounted) setState(() => _aiTriggered = false);
    }
  }

  @override
  void dispose() {
    _financialConversation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InsightsBloc, InsightsState>(
      builder: (context, state) {
        if (state is InsightsLoaded) {
          // Trigger AI once data is ready
          if (!_aiTriggered) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _runSilentAiAnalysis(state.networth);
            });
          }

          final insights = state.networth.insights;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECTION 1: GAUGES (Local Data) ---
                Text(
                  'Portfolio Health ${_surfaceIds.length}',
                  style: AppTypography.headline3SemiBold.copyWith(
                    color: AppColors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                _buildGaugesRow(insights),

                const SizedBox(height: 32),

                // --- SECTION 2: AI INSIGHTS (GenUI Dynamic Surfaces) ---
                _buildAiHeader(),
                const SizedBox(height: 16),

                // Rendering the Surfaces generated by the AI
                if (_surfaceIds.isEmpty)
                  _buildInitialLoader()
                else
                  ..._surfaceIds.map(
                    (id) => GenUiSurface(
                      key: ValueKey(id),
                      host: _financialConversation.host,
                      surfaceId: id,
                    ),
                  ),
              ],
            ),
          );
        }
        return Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        );
      },
    );
  }

  Widget _buildInitialLoader() {
    return ValueListenableBuilder<bool>(
      valueListenable: _financialConversation.isProcessing,
      builder: (context, isProcessing, _) {
        if (!isProcessing) return const SizedBox.shrink();
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  "AI Advisor is generating your strategy...",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // DESIGN WIDGETS (PROPRE ET INCHANGÉ)
  // ===========================================================================

  Widget _buildAiHeader() {
    return Row(
      children: [
        const Icon(
          Icons.psychology_rounded,
          color: Color(0xFF3861FB),
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'AI Strategic Insights',
          style: AppTypography.headline3SemiBold.copyWith(
            color: AppColors.white,
            fontSize: 18,
          ),
        ),
        const Spacer(),
        ValueListenableBuilder<bool>(
          valueListenable: _financialConversation.isProcessing,
          builder: (context, isThinking, _) {
            if (!isThinking) {
              return const Icon(
                Icons.auto_awesome,
                color: Colors.amber,
                size: 16,
              );
            }
            return SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGaugesRow(Insights insights) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildScoreGauge(
          score: insights.diversificationScore,
          title: 'Diversification',
          icon: Icons.pie_chart_rounded,
          color: const Color(0xFF00D16C),
        ),
        _buildScoreGauge(
          score: double.tryParse(insights.riskLevel) ?? 5.0,
          title: 'Risk Level',
          icon: Icons.warning_rounded,
          color: const Color(0xFFFFAA00),
        ),
        _buildScoreGauge(
          score: 8.0,
          title: 'Volatility',
          icon: Icons.show_chart_rounded,
          color: const Color(0xFFFF4D4D),
        ),
      ],
    );
  }

  Widget _buildScoreGauge({
    required double score,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final percentage = (score / 10.0).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(90, 90),
                painter: CircularGaugePainter(
                  percentage: 1.0,
                  color: AppColors.gray80,
                  strokeWidth: 8,
                ),
              ),
              CustomPaint(
                size: const Size(90, 90),
                painter: CircularGaugePainter(
                  percentage: percentage,
                  color: color,
                  strokeWidth: 8,
                ),
              ),
              Text(
                score.toStringAsFixed(1),
                style: AppTypography.headline3Bold.copyWith(
                  color: AppColors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: AppTypography.headline1Regular.copyWith(
            color: AppColors.gray30,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class CircularGaugePainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;
  CircularGaugePainter({
    required this.percentage,
    required this.color,
    required this.strokeWidth,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * percentage, false, paint);
  }

  @override
  bool shouldRepaint(CircularGaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}
