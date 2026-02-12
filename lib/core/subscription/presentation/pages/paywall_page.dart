import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:financo/core/services/toast_service.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaywallView(
        onPurchaseCompleted: (customerInfo, storeTransaction) {
          debugPrint(
            'Purchase completed: ${storeTransaction.productIdentifier}',
          );
          if (context.mounted) {
            ToastService.showSuccess(
              context,
              'Abonnement activé ! Profitez des fonctionnalités premium.',
            );
            context.go('/');
          }
        },
        onRestoreCompleted: (customerInfo) {
          if (context.mounted) {
            ToastService.showSuccess(context, 'Achats restaurés avec succès.');
            context.go('/');
          }
        },
        onDismiss: () {
          if (context.canPop()) {
            Navigator.pop(context);
          } else {
            context.go('/');
          }
        },
      ),
    );
  }
}
