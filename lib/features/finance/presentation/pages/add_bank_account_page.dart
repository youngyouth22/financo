import 'dart:async';

import 'package:flutter/services.dart';

import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/common_widgets/primary_button.dart';
import 'package:financo/core/services/toast_service.dart';
import 'package:financo/di/injection_container.dart';
import 'package:financo/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:financo/features/finance/presentation/bloc/finance_event.dart';
import 'package:financo/features/finance/presentation/bloc/finance_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plaid_flutter/plaid_flutter.dart';

/// Page for adding bank accounts via Plaid using real SDK
class AddBankAccountPage extends StatefulWidget {
  const AddBankAccountPage({super.key});

  @override
  State<AddBankAccountPage> createState() => _AddBankAccountPageState();
}

class _AddBankAccountPageState extends State<AddBankAccountPage> {
  late FinanceBloc _financeBloc;
  bool _isLoading = false;
  String? _linkToken;
  StreamSubscription<LinkSuccess>? _successSubscription;
  StreamSubscription<LinkExit>? _exitSubscription;

  @override
  void initState() {
    super.initState();
    _financeBloc = sl<FinanceBloc>();
  }

  @override
  dispose() {
    _successSubscription?.cancel();
    _exitSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _financeBloc,
      child: BlocListener<FinanceBloc, FinanceState>(
        listener: (context, state) {
          if (state is PlaidLinkTokenLoaded) {
            setState(() {
              _linkToken = state.tokenData['link_token'];
            });
            // Une fois le token reçu, on ouvre automatiquement Plaid
            _openPlaidLink();
          } else if (state is PlaidTokenExchanged) {
            setState(() => _isLoading = false);
            // Succès final : on ferme la page et on prévient l'utilisateur
            Navigator.of(context).pop(true);
            ToastService.showSuccess(
              context,
              'Bank account connected and synced successfully',
            );
          } else if (state is FinanceError) {
            setState(() => _isLoading = false);
            ToastService.showError(context, state.message);
          } else if (state is FinanceLoading) {
            setState(() => _isLoading = true);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back, color: AppColors.white),
            ),
            title: Text(
              'Connect Bank Account',
              style: AppTypography.headline4Bold.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSandboxCredentials(),
                  const SizedBox(height: 24),
                  _buildInfoCard(),
                  const Spacer(),
                  PrimaryButton(
                    text: 'Connect with Plaid',
                    onClick: _getLinkToken,
                    isLoading: _isLoading,
                    icon: Icon(Icons.link, color: AppColors.white),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSandboxCredentials() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.science_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sandbox Environment',
                style: AppTypography.headline3Bold.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Use these credentials to test the integration:',
            style: AppTypography.bodySmallRegular.copyWith(
              color: AppColors.gray40,
            ),
          ),
          const SizedBox(height: 16),
          _buildCredentialRow('Username', 'user_good'),
          const SizedBox(height: 8),
          _buildCredentialRow('Password', 'mypassword'),
          const SizedBox(height: 8),
          _buildCredentialRow('MFA Pin', '1234'),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmallMedium.copyWith(
              color: AppColors.gray40,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: AppTypography.bodySmallBold.copyWith(
                  color: AppColors.white,
                  fontFamily: 'Courier',
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ToastService.showSuccess(context, '$label copied');
                },
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray80,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray70),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, color: AppColors.success, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank-Grade Security',
                  style: AppTypography.headline4Bold.copyWith(
                    color: AppColors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your credentials are encrypted and never stored on our servers.',
                  style: AppTypography.bodySmallRegular.copyWith(
                    color: AppColors.gray40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Étape 1 : Demander le link_token à notre backend Supabase
  void _getLinkToken() {
    _financeBloc.add(const GetPlaidLinkTokenEvent());
  }

  /// Étape 2 : Ouvrir l'interface native Plaid
  Future<void> _openPlaidLink() async {
    try {
      if (_linkToken == null) return;

      // 1. On crée la configuration
      LinkTokenConfiguration configuration = LinkTokenConfiguration(
        token: _linkToken!,
      );

      // 2. On annule les anciens abonnements s'ils existent
      _successSubscription?.cancel();
      _exitSubscription?.cancel();

      // 3. On écoute le Stream de SUCCÈS
      _successSubscription = PlaidLink.onSuccess.listen((LinkSuccess event) {
        debugPrint("Plaid Success: Exchanging public token...");
        // Le publicToken se trouve dans l'objet 'event'
        _financeBloc.add(ExchangePlaidTokenEvent(event.publicToken));
      });

      // 4. On écoute le Stream de SORTIE (User a fermé la fenêtre)
      _exitSubscription = PlaidLink.onExit.listen((LinkExit event) {
        debugPrint("User exited Plaid");
        if (mounted) setState(() => _isLoading = false);
      });

      // 5. On ouvre le portail Plaid
      // Note : Dans les versions récentes, 'configuration' est le premier paramètre positionnel
      // ou nommé selon la sous-version. Si 'configuration:' ne marche pas, retire le nom.
      await PlaidLink.create(configuration: configuration);
      PlaidLink.open();
    } catch (e) {
      debugPrint("Error opening Plaid Link: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ToastService.showError(context, 'Error opening Plaid: $e');
      }
    }
  }
}
