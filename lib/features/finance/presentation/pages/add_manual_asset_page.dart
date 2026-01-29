import 'package:country_picker/country_picker.dart';
import 'package:financo/common/app_colors.dart';
import 'package:financo/di/injection_container.dart';
import 'package:financo/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:financo/features/finance/presentation/bloc/finance_event.dart';
import 'package:financo/features/finance/presentation/bloc/finance_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Page for adding manual assets (real estate, commodities, liabilities, etc.)
///
/// Features:
/// - Asset type selection with icons
/// - Amount input with currency formatting
/// - Country picker with flags
/// - Sector/category selection
/// - Form validation
/// - BLoC integration
class AddManualAssetPage extends StatefulWidget {
  const AddManualAssetPage({super.key});

  @override
  State<AddManualAssetPage> createState() => _AddManualAssetPageState();
}

class _AddManualAssetPageState extends State<AddManualAssetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _sectorController = TextEditingController();

  String _selectedType = 'real_estate';
  String _selectedCurrency = 'USD';
  String? _selectedCountry;
  String? _selectedCountryCode;

  bool _isLoading = false;

  final List<Map<String, dynamic>> _assetTypes = [
    {
      'value': 'real_estate',
      'label': 'Real Estate',
      'icon': Icons.home_rounded,
      'description': 'Houses, apartments, land',
    },
    {
      'value': 'commodity',
      'label': 'Commodity',
      'icon': Icons.diamond_rounded,
      'description': 'Gold, silver, oil, etc.',
    },
    {
      'value': 'cash',
      'label': 'Cash',
      'icon': Icons.payments_rounded,
      'description': 'Physical cash, safe deposits',
    },
    {
      'value': 'investment',
      'label': 'Investment',
      'icon': Icons.trending_up_rounded,
      'description': 'Private equity, VC',
    },
    {
      'value': 'liability',
      'label': 'Liability',
      'icon': Icons.credit_card_rounded,
      'description': 'Loans, mortgages, debts',
    },
    {
      'value': 'other',
      'label': 'Other',
      'icon': Icons.category_rounded,
      'description': 'Collectibles, art, vehicles',
    },
  ];

  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CNY',
    'CAD',
    'AUD',
    'CHF',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _sectorController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        backgroundColor: AppColors.background,
        textStyle: TextStyle(color: AppColors.white),
        bottomSheetHeight: 500,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          labelStyle: TextStyle(color: AppColors.gray40),
          hintText: 'Start typing to search',
          hintStyle: TextStyle(color: AppColors.gray50),
          prefixIcon: Icon(Icons.search, color: AppColors.primary),
          filled: true,
          fillColor: AppColors.gray80,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country.name;
          _selectedCountryCode = country.countryCode;
        });
      },
    );
  }

  void _handleSubmit(BuildContext ctx) {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(
        _amountController.text.replaceAll(',', ''),
      );
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: const Text('Please enter a valid amount'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      ctx.read<FinanceBloc>().add(
        AddManualAssetEvent(
          name: _nameController.text.trim(),
          type: _selectedType,
          amount: amount,
          currency: _selectedCurrency,
          sector: _sectorController.text.trim().isEmpty
              ? null
              : _sectorController.text.trim(),
          country: _selectedCountry,
        ),
      );
    }
  }

  String _formatCurrency(String value) {
    if (value.isEmpty) return '';
    final number = double.tryParse(value.replaceAll(',', ''));
    if (number == null) return value;
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FinanceBloc>(),
      child: BlocListener<FinanceBloc, FinanceState>(
        listener: (context, state) {
          if (state is FinanceLoading) {
            setState(() => _isLoading = true);
          } else if (state is ManualAssetAdded) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✓ Asset added successfully!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is FinanceError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Add Manual Asset',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Asset Type Selection
                  Text(
                    'Asset Type',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.5,
                        ),
                    itemCount: _assetTypes.length,
                    itemBuilder: (context, index) {
                      final type = _assetTypes[index];
                      final isSelected = _selectedType == type['value'];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedType = type['value']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.gray80,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                type['icon'],
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.gray40,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  type['label'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.gray30,
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Asset Name
                  Text(
                    'Asset Name',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g., My House, Gold Bars',
                      hintStyle: TextStyle(color: AppColors.gray50),
                      filled: true,
                      fillColor: AppColors.gray80,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter asset name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Amount and Currency
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _amountController,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(color: AppColors.gray50),
                                filled: true,
                                fillColor: AppColors.gray80,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                final amount = double.tryParse(
                                  value.replaceAll(',', ''),
                                );
                                if (amount == null || amount <= 0) {
                                  return 'Invalid amount';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Currency',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.gray80,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: DropdownButton<String>(
                                value: _selectedCurrency,
                                isExpanded: true,
                                underline: const SizedBox(),
                                dropdownColor: AppColors.gray80,
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.gray40,
                                ),
                                items: _currencies.map((currency) {
                                  return DropdownMenuItem(
                                    value: currency,
                                    child: Text(currency),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedCurrency = value!);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Country (Optional)
                  Text(
                    'Country (Optional)',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showCountryPicker,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.gray80,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          if (_selectedCountryCode != null) ...[
                            Text(
                              CountryParser.parseCountryCode(
                                _selectedCountryCode!,
                              ).flagEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              _selectedCountry ?? 'Select country',
                              style: TextStyle(
                                color: _selectedCountry != null
                                    ? AppColors.white
                                    : AppColors.gray50,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.gray40,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sector (Optional)
                  Text(
                    'Sector/Category (Optional)',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _sectorController,
                    style: TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g., Residential, Precious Metals',
                      hintStyle: TextStyle(color: AppColors.gray50),
                      filled: true,
                      fillColor: AppColors.gray80,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Builder(
                      builder: (innerCtx) => ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _handleSubmit(innerCtx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.gray70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Add Asset',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
