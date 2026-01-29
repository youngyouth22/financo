import 'dart:async';

import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
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
              _isLoading = false;
            });
            // Une fois le token reçu, on ouvre automatiquement Plaid
            _openPlaidLink();
          } else if (state is PlaidTokenExchanged) {
            setState(() => _isLoading = false);
            // Succès final : on ferme la page et on prévient l'utilisateur
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Bank account connected and synced successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is FinanceError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
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
                  _buildInfoCard(),
                  const SizedBox(height: 32),
                  if (_isLoading) ...[
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Communicating with bank servers...',
                        style: AppTypography.headline2Regular.copyWith(
                          color: AppColors.gray50,
                        ),
                      ),
                    ),
                  ] else ...[
                    _buildConnectButton(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha:0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Secure Bank Connection',
                  style: AppTypography.headline3SemiBold.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We use Plaid to securely connect your bank. Your credentials are encrypted and never visible to us.',
            style: AppTypography.headline2Regular.copyWith(
              color: AppColors.gray50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _getLinkToken,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          'Get Started',
          style: AppTypography.headline3SemiBold,
        ),
      ),
    );
  }

  /// Étape 1 : Demander le link_token à notre backend Supabase
  void _getLinkToken() {
    _financeBloc.add(const GetPlaidLinkTokenEvent());
  }

  /// Étape 2 : Ouvrir l'interface native Plaid
  Future<void> _openPlaidLink() async {
    try
    {if (_linkToken == null) return;

    // 1. On crée la configuration
    LinkTokenConfiguration configuration = LinkTokenConfiguration(
      token: _linkToken!,
    );

    // 2. On annule les anciens abonnements s'ils existent
    _successSubscription?.cancel();
    _exitSubscription?.cancel();

    // 3. On écoute le Stream de SUCCÈS
    _successSubscription = PlaidLink.onSuccess.listen((LinkSuccess event) {
      print("Plaid Success: Exchanging public token...");
      // Le publicToken se trouve dans l'objet 'event'
      _financeBloc.add(ExchangePlaidTokenEvent(event.publicToken));
    });

    // 4. On écoute le Stream de SORTIE (User a fermé la fenêtre)
    _exitSubscription = PlaidLink.onExit.listen((LinkExit event) {
      print("User exited Plaid");
      if (mounted) setState(() => _isLoading = false);
    });

    // 5. On ouvre le portail Plaid
    // Note : Dans les versions récentes, 'configuration' est le premier paramètre positionnel
    // ou nommé selon la sous-version. Si 'configuration:' ne marche pas, retire le nom.
    await PlaidLink.create(configuration: configuration);
    PlaidLink.open();}catch (e) {
      print("Error opening Plaid Link: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Plaid: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}