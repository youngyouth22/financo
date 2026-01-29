import 'package:financo/common/app_colors.dart';
import 'package:financo/common/app_typography.dart';
import 'package:financo/common/common_widgets/primary_button.dart';
import 'package:financo/di/injection_container.dart';
import 'package:financo/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:financo/features/finance/presentation/bloc/finance_event.dart';
import 'package:financo/features/finance/presentation/bloc/finance_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Page for adding a crypto wallet via Moralis
///
/// Features:
/// - Wallet address input with validation
/// - Wallet name customization
/// - Automatic Moralis stream registration
/// - Modern UI matching app design
class AddCryptoWalletPage extends StatefulWidget {
  const AddCryptoWalletPage({super.key});

  @override
  State<AddCryptoWalletPage> createState() => _AddCryptoWalletPageState();
}

class _AddCryptoWalletPageState extends State<AddCryptoWalletPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<FinanceBloc>(),
      child: BlocListener<FinanceBloc, FinanceState>(
        listener: (context, state) {
          if (state is CryptoWalletAdded) {
            // Success - go back
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Crypto wallet added successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is FinanceError) {
            // Error
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
              'Add Crypto Wallet',
              style: AppTypography.headline4Bold.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
          body: SafeArea(
            child: Builder(
              builder: (innerContext) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info card
                        _buildInfoCard(),

                        const SizedBox(height: 32),

                        // Wallet name field
                        Text(
                          'Wallet Name',
                          style: AppTypography.headline3SemiBold.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildNameField(),

                        const SizedBox(height: 24),

                        // Wallet address field
                        Text(
                          'Wallet Address',
                          style: AppTypography.headline3SemiBold.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAddressField(),

                        const SizedBox(height: 32),

                        // Supported chains info
                        _buildSupportedChains(),

                        const SizedBox(height: 32),

                        // Add button
                        _buildAddButton(innerContext),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Build add button with proper context
  Widget _buildAddButton(BuildContext context) {
    return PrimaryButton(
      text: _isLoading ? 'Adding...' : 'Add Wallet',
      onClick: () => _handleAddWallet(context),
      isLoading: _isLoading,
    );
  }

  /// Build info card
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your wallet will be monitored in real-time via Moralis Streams',
              style: AppTypography.headline2Regular.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build name field
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: AppTypography.headline3Regular.copyWith(color: AppColors.white),
      decoration: InputDecoration(
        hintText: 'e.g., My Ethereum Wallet',
        hintStyle: AppTypography.headline3Regular.copyWith(
          color: AppColors.gray50,
        ),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gray70),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gray70),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        prefixIcon: Icon(Icons.label_outline, color: AppColors.gray50),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a wallet name';
        }
        return null;
      },
    );
  }

  /// Build address field
  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      style: AppTypography.headline3Regular.copyWith(
        color: AppColors.white,
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        hintText: '0x...',
        hintStyle: AppTypography.headline3Regular.copyWith(
          color: AppColors.gray50,
        ),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gray70),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gray70),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        prefixIcon: Icon(
          Icons.account_balance_wallet_outlined,
          color: AppColors.gray50,
        ),
        suffixIcon: IconButton(
          onPressed: () async {
            final data = await Clipboard.getData('text/plain');
            if (data != null && data.text != null) {
              _addressController.text = data.text!;
            }
          },
          icon: Icon(Icons.content_paste, color: AppColors.primary),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a wallet address';
        }
        if (!value.startsWith('0x') || value.length != 42) {
          return 'Invalid Ethereum address format';
        }
        return null;
      },
    );
  }

  /// Build supported chains info
  Widget _buildSupportedChains() {
    final chains = [
      {'name': 'Ethereum', 'icon': '⟠'},
      {'name': 'Polygon', 'icon': '⬡'},
      {'name': 'BSC', 'icon': '🔶'},
      {'name': 'Avalanche', 'icon': '🔺'},
      {'name': 'Arbitrum', 'icon': '🔵'},
      {'name': 'Optimism', 'icon': '🔴'},
      {'name': 'Base', 'icon': '🔷'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supported Chains',
          style: AppTypography.headline3SemiBold.copyWith(
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chains.map((chain) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gray70),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(chain['icon']!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    chain['name']!,
                    style: AppTypography.headline1SemiBold.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Handle add wallet
  void _handleAddWallet(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final address = _addressController.text.trim().toLowerCase();

      // Add crypto wallet via BLoC
      context.read<FinanceBloc>().add(
        AddCryptoWalletEvent(address),
      );
    }
  }
}
