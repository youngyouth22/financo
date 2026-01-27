import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/common_widgets/primary_button.dart';
import 'package:financo/di/injection_container.dart';
import 'package:financo/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:financo/features/finance/presentation/bloc/finance_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Page for adding a bank account via Plaid
///
/// Features:
/// - Plaid Link integration
/// - Bank account selection
/// - Automatic balance sync
/// - Modern UI matching app design
class AddBankAccountPage extends StatefulWidget {
  const AddBankAccountPage({super.key});

  @override
  State<AddBankAccountPage> createState() => _AddBankAccountPageState();
}

class _AddBankAccountPageState extends State<AddBankAccountPage> {
  bool _isLoading = false;
  String? _linkToken;

  @override
  void initState() {
    super.initState();
    _initializePlaidLink();
  }

  /// Initialize Plaid Link by getting link token from Edge Function
  Future<void> _initializePlaidLink() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'plaid-link',
        body: {'action': 'create_link_token'},
      );

      if (response.data != null && response.data['link_token'] != null) {
        setState(() {
          _linkToken = response.data['link_token'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to get link token');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing Plaid: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<FinanceBloc>(),
      child: BlocListener<FinanceBloc, FinanceState>(
        listener: (context, state) {
          // if (state is AssetAdded) {
          //   Navigator.of(context).pop(true);
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: const Text('Bank account added successfully'),
          //       backgroundColor: AppColors.success,
          //     ),
          //   );
          // } else if (state is FinanceError) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text(state.message),
          //       backgroundColor: AppColors.error,
          //     ),
          //   );
          // }
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
              'Add Bank Account',
              style: AppTypography.headline4Bold.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
          body: SafeArea(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : Builder(
                    builder: (innerContext) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Info card
                            _buildInfoCard(),

                            const SizedBox(height: 32),

                            // Plaid logo and description
                            _buildPlaidInfo(),

                            const SizedBox(height: 32),

                            // Features list
                            _buildFeaturesList(),

                            const SizedBox(height: 32),

                            // Connect button
                            PrimaryButton(
                              text: 'Connect with Plaid',
                              onClick: () {
                                if (_linkToken != null) {
                                  _handleConnectBank(innerContext);
                                }
                              },
                              // icon: Icons.link,
                            ),

                            const SizedBox(height: 16),

                            // Security note
                            _buildSecurityNote(),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  /// Build info card
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentS.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentS.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: AppColors.accentS, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your bank credentials are never stored. Plaid uses bank-level encryption.',
              style: AppTypography.headline2Regular.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Plaid info
  Widget _buildPlaidInfo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.account_balance,
            size: 40,
            color: AppColors.accentS,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Powered by Plaid',
          style: AppTypography.headline4Bold.copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect your bank account securely to track your cash and investments',
          style: AppTypography.headline2Regular.copyWith(
            color: AppColors.gray40,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build features list
  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.sync,
        'title': 'Automatic Sync',
        'description': 'Balance updates automatically',
      },
      {
        'icon': Icons.lock_outline,
        'title': 'Bank-Level Security',
        'description': 'Your data is encrypted end-to-end',
      },
      {
        'icon': Icons.account_balance_wallet,
        'title': 'Multiple Accounts',
        'description': 'Connect checking, savings, and investments',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: AppTypography.headline3SemiBold.copyWith(
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: AppColors.accentS,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: AppTypography.headline3SemiBold.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature['description'] as String,
                        style: AppTypography.headline1Regular.copyWith(
                          color: AppColors.gray40,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build security note
  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.gray50, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Plaid is used by thousands of financial apps and is trusted by millions of users',
              style: AppTypography.headline1Regular.copyWith(
                color: AppColors.gray50,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle connect bank
  Future<void> _handleConnectBank(BuildContext context) async {
    if (_linkToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Link token not available. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // TODO: Implement Plaid Link SDK integration
    // For now, show a dialog explaining the process
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          'Plaid Integration',
          style: AppTypography.headline4Bold.copyWith(color: AppColors.white),
        ),
        content: Text(
          'Plaid Link SDK integration requires native platform setup. '
          'This feature will open Plaid\'s secure interface to connect your bank account.',
          style: AppTypography.headline2Regular.copyWith(
            color: AppColors.gray40,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _simulateBankConnection(context);
            },
            child: Text(
              'Simulate Connection',
              style: TextStyle(color: AppColors.accentS),
            ),
          ),
        ],
      ),
    );
  }

  /// Simulate bank connection for testing
  void _simulateBankConnection(BuildContext context) {
    // Add a simulated bank account
    // context.read<FinanceBloc>().add(
    //   AddAssetEvent(
    //     assetGroup: AssetGroup.cash,
    //     name: 'Chase Checking',
    //     type: AssetType.bank,
    //     // assetGroup: AssetGroup.cash,
    //     provider: AssetProvider.plaid,
    //     assetAddressOrId:
    //         'plaid_account_${DateTime.now().millisecondsSinceEpoch}',
    //     initialBalance: 5000.0,
    //   ),
    // );
  }
}
