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

/// Page for adding stocks via Financial Modeling Prep
class AddStockPage extends StatefulWidget {
  const AddStockPage({super.key});

  @override
  State<AddStockPage> createState() => _AddStockPageState();
}

class _AddStockPageState extends State<AddStockPage> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  late FinanceBloc _financeBloc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<FinanceBloc>(),
      child: Builder(
        builder: (context) {
          _financeBloc = BlocProvider.of<FinanceBloc>(context);
          return BlocListener<FinanceBloc, FinanceState>(
            bloc: _financeBloc,
            listener: (context, state) {
              if (state is StockSearchResultsLoaded) {
                setState(() {
                  _searchResults = state.results;
                  _isSearching = false;
                });
              } else if (state is StockAdded) {
                // Success - go back
                Navigator.of(context).pop(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Stock added successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (state is FinanceError) {
                setState(() => _isSearching = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              } else if (state is FinanceLoading) {
                setState(() => _isSearching = true);
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
                  'Add Stock',
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
                      // Info card
                      _buildInfoCard(),
                      const SizedBox(height: 24),

                      // Search field
                      Text(
                        'Search Company',
                        style: AppTypography.headline3SemiBold.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSearchField(),
                      const SizedBox(height: 24),

                      // Results
                      if (_searchResults.isNotEmpty) ...[
                        Text(
                          'Search Results',
                          style: AppTypography.headline3SemiBold.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(child: _buildResultsList()),
                      ] else if (_isSearching) ...[
                        const Center(child: CircularProgressIndicator()),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
              'Search for stocks and ETFs using company names or tickers',
              style: AppTypography.headline2Regular.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build search field
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: AppTypography.headline3Regular.copyWith(color: AppColors.white),
      decoration: InputDecoration(
        hintText: 'e.g., Apple, Tesla, AAPL',
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
        prefixIcon: Icon(Icons.search, color: AppColors.gray50),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchResults = []);
                },
                icon: Icon(Icons.clear, color: AppColors.gray50),
              )
            : null,
      ),
      onChanged: (value) {
        if (value.length >= 2) {
          _performSearch(value);
        } else {
          setState(() => _searchResults = []);
        }
      },
    );
  }

  /// Build results list
  Widget _buildResultsList() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        final symbol = result['symbol'] ?? '';
        final name = result['name'] ?? '';
        final exchange = result['exchangeShortName'] ?? '';

        return GestureDetector(
          onTap: () => _showQuantityBottomSheet(symbol, name),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gray70),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        symbol,
                        style: AppTypography.headline3SemiBold.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: AppTypography.headline2Regular.copyWith(
                          color: AppColors.gray50,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exchange,
                        style: AppTypography.headline1SemiBold.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.gray50,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Perform search
  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() => _isSearching = true);
    _financeBloc.add(SearchStocksEvent(query.trim()));
  }

  /// Show quantity bottom sheet
  void _showQuantityBottomSheet(String symbol, String name) {
    final quantityController = TextEditingController();
    bool isAdding = false;
    final financeBloc = _financeBloc;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return BlocProvider.value(
          value: financeBloc,
          child: StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add $symbol',
                    style: AppTypography.headline4Bold.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: AppTypography.headline2Regular.copyWith(
                      color: AppColors.gray50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quantity',
                    style: AppTypography.headline3SemiBold.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    style: AppTypography.headline3Regular.copyWith(
                      color: AppColors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., 10.5',
                      hintStyle: AppTypography.headline3Regular.copyWith(
                        color: AppColors.gray50,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
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
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: isAdding ? 'Adding...' : 'Add Stock',
                    onClick: () {
                      final quantity = double.tryParse(quantityController.text);
                      if (quantity != null && quantity > 0) {
                        setState(() => isAdding = true);
                        // Add stock via BLoC
                        BlocProvider.of<FinanceBloc>(context).add(
                          AddStockEvent(symbol: symbol, quantity: quantity),
                        );
                        Navigator.of(context).pop(); // Close bottom sheet
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter a valid quantity'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                    isLoading: isAdding,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
