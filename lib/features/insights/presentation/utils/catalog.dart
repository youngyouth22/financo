import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:financo/features/insights/presentation/widgets/insight_card.dart';

/// The Catalog defines the widgets the AI is allowed to use.
/// Following the official GenUI documentation with Data Binding.
final financeAiCatalog = Catalog([insightcatalog]);

final insightcatalog = CatalogItem(
  name: 'InsightCard',
  dataSchema: S.object(
    properties: {
      'type': S.string(
        description: 'Category: warning, action, or success.',
        enumValues: ['warning', 'action', 'success'],
      ),
      'icon': S.string(
        description: 'Material icon name (e.g. flag_rounded).',
        enumValues: [
          'flag_rounded',
          'lightbulb_rounded',
          'trending_up_rounded',
          'security_rounded',
          'account_balance_wallet',
          'check_circle',
        ],
      ),
      'title': S.string(description: 'The headline of the insight.'),
      'description': S.string(description: 'The detailed strategy text.'),
      'actionLabel': S.string(description: 'Optional button text.'),
    },
    required: ['type', 'icon', 'title', 'description'],
  ),
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    // Data Binding: We subscribe to the values sent by the AI
    // They can be either "literalString" or a "path" in the model
    final type = data['type'] as String?;
    final icon = data['icon'] as String?;
    final title = data['title'] as String?;
    final description = data['description'] as String?;
    final actionLabel = data['actionLabel'] as String?;
    // final typeNotifier = context.dataContext.subscribeToString(
    //   data['type'] as Map<String, Object?>?,
    // );
    // final iconNotifier = context.dataContext.subscribeToString(
    //   data['icon'] as Map<String, Object?>?,
    // );
    // final titleNotifier = context.dataContext.subscribeToString(
    //   data['title'] as Map<String, Object?>?,
    // );
    // final descNotifier = context.dataContext.subscribeToString(
    //   data['description'] as Map<String, Object?>?,
    // );
    // final actionLabelNotifier = context.dataContext.subscribeToString(
    //   data['actionLabel'] as Map<String, Object?>?,
    // );

    // We use ValueListenableBuilder to react to data changes
    return InsightCard(
      type: _parseInsightType(type),
      icon: _parseIconData(icon),
      title: title?? 'Insight',
      description: description ?? '',
      actionLabel: actionLabel,
      // Submits the interaction back to the AI context
      onActionPressed: () {
        // => context.submit()
      },
    );
  },
);

// ============================================================================
// HELPERS
// ============================================================================

InsightType _parseInsightType(String? type) {
  switch (type?.toLowerCase()) {
    case 'warning':
      return InsightType.warning;
    case 'action':
      return InsightType.action;
    case 'success':
      return InsightType.success;
    default:
      return InsightType.action;
  }
}

IconData _parseIconData(String? iconName) {
  switch (iconName?.toLowerCase()) {
    case 'flag_rounded':
      return Icons.flag_rounded;
    case 'lightbulb_rounded':
      return Icons.lightbulb_rounded;
    case 'trending_up_rounded':
      return Icons.trending_up_rounded;
    case 'security_rounded':
      return Icons.security_rounded;
    case 'account_balance_wallet':
      return Icons.account_balance_wallet;
    case 'check_circle':
      return Icons.check_circle_rounded;
    default:
      return Icons.insights_rounded;
  }
}
