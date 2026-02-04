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
import 'package:rrule/rrule.dart';

/// Page for adding manual assets with optional reminder
///
/// Features:
/// - Asset type selection with icons
/// - Amount input with currency formatting
/// - Country picker with flags
/// - Sector/category selection
/// - Premium checkbox to add reminder
/// - Reminder configuration (RRULE, next event, amount)
/// - Form validation
/// - BLoC integration for 2 separate tables (assets + reminders)
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
  
  // Reminder fields
  final _reminderTitleController = TextEditingController();
  final _reminderAmountController = TextEditingController();

  String _selectedType = 'real_estate';
  String _selectedCurrency = 'USD';
  String? _selectedCountry;
  String? _selectedCountryCode;

  // Reminder state
  bool _addReminder = false;
  String _selectedFrequency = 'MONTHLY';
  int _interval = 1;
  DateTime _nextEventDate = DateTime.now().add(const Duration(days: 1));

  bool _isLoading = false;
  String? _createdAssetId; // Store asset ID after creation

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

  final List<Map<String, dynamic>> _frequencies = [
    {'value': 'DAILY', 'label': 'Daily', 'icon': Icons.today_rounded},
    {'value': 'WEEKLY', 'label': 'Weekly', 'icon': Icons.calendar_view_week_rounded},
    {'value': 'MONTHLY', 'label': 'Monthly', 'icon': Icons.calendar_month_rounded},
    {'value': 'YEARLY', 'label': 'Yearly', 'icon': Icons.calendar_today_rounded},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _sectorController.dispose();
    _reminderTitleController.dispose();
    _reminderAmountController.dispose();
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

  String _generateRRule() {
    switch (_selectedFrequency) {
      case 'DAILY':
        return 'FREQ=DAILY;INTERVAL=$_interval';
      case 'WEEKLY':
        final weekday = _nextEventDate.weekday == 7 ? 'SU' : ['MO', 'TU', 'WE', 'TH', 'FR', 'SA'][_nextEventDate.weekday - 1];
        return 'FREQ=WEEKLY;INTERVAL=$_interval;BYDAY=$weekday';
      case 'MONTHLY':
        return 'FREQ=MONTHLY;INTERVAL=$_interval;BYMONTHDAY=${_nextEventDate.day}';
      case 'YEARLY':
        return 'FREQ=YEARLY;INTERVAL=$_interval;BYMONTH=${_nextEventDate.month};BYMONTHDAY=${_nextEventDate.day}';
      default:
        return 'FREQ=MONTHLY;INTERVAL=1';
    }
  }

  String _getRecurrenceDescription() {
    try {
      if (_interval == 1) {
        switch (_selectedFrequency) {
          case 'DAILY':
            return 'Every day';
          case 'WEEKLY':
            final weekday = DateFormat('EEEE').format(_nextEventDate);
            return 'Every $weekday';
          case 'MONTHLY':
            return 'Every month on day ${_nextEventDate.day}';
          case 'YEARLY':
            final date = DateFormat('MMMM d').format(_nextEventDate);
            return 'Every year on $date';
        }
      } else {
        switch (_selectedFrequency) {
          case 'DAILY':
            return 'Every $_interval days';
          case 'WEEKLY':
            final weekday = DateFormat('EEEE').format(_nextEventDate);
            return 'Every $_interval weeks on $weekday';
          case 'MONTHLY':
            return 'Every $_interval months on day ${_nextEventDate.day}';
          case 'YEARLY':
            final date = DateFormat('MMMM d').format(_nextEventDate);
            return 'Every $_interval years on $date';
        }
      }
      return 'Custom recurrence';
    } catch (e) {
      return 'Custom recurrence';
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextEventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.gray80,
              onSurface: AppColors.white,
            ),
            dialogBackgroundColor: AppColors.gray80,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _nextEventDate) {
      setState(() {
        _nextEventDate = picked;
      });
    }
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

      // Validate reminder fields if checkbox is checked
      if (_addReminder) {
        if (_reminderTitleController.text.trim().isEmpty) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: const Text('Please enter a reminder title'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }

      // Step 1: Add asset first
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

  void _handleAddReminder(BuildContext ctx, String assetId) {
    // Step 2: Add reminder after asset is created
    final rruleExpression = _generateRRule();
    final amount = _reminderAmountController.text.trim().isEmpty
        ? null
        : double.tryParse(_reminderAmountController.text.replaceAll(',', ''));

    ctx.read<FinanceBloc>().add(
      AddAssetReminderEvent(
        assetId: assetId,
        title: _reminderTitleController.text.trim(),
        rruleExpression: rruleExpression,
        nextEventDate: _nextEventDate,
        amountExpected: amount,
      ),
    );
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
            // Asset created successfully
            if (_addReminder) {
              // If reminder checkbox is checked, add reminder now
              _createdAssetId = state.assetId;
              _handleAddReminder(context, state.assetId);
            } else {
              // No reminder, just show success and close
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✓ Asset added successfully!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context, true);
            }
          } else if (state is AssetReminderAdded) {
            // Reminder added successfully after asset
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✓ Asset and reminder added successfully!'),
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
                      hintText: 'e.g., Downtown Apartment, Gold Bars',
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
                        return 'Please enter an asset name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Amount and Currency
                  Text(
                    'Value',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Currency Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.gray80,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            dropdownColor: AppColors.gray80,
                            icon: Icon(Icons.arrow_drop_down, color: AppColors.gray40),
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            items: _currencies.map((currency) {
                              return DropdownMenuItem(
                                value: currency,
                                child: Text(currency),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedCurrency = value);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Amount Input
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
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
                          onChanged: (value) {
                            // Format currency on change
                            final formatted = _formatCurrency(value);
                            if (formatted != value) {
                              _amountController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                  offset: formatted.length,
                                ),
                              );
                            }
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            final amount = double.tryParse(value.replaceAll(',', ''));
                            if (amount == null || amount <= 0) {
                              return 'Invalid amount';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Country Selection
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.gray80,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.public_rounded, color: AppColors.gray40),
                          const SizedBox(width: 12),
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
                          if (_selectedCountryCode != null) ...[
                            Text(
                              _selectedCountryCode!,
                              style: TextStyle(
                                color: AppColors.gray40,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: AppColors.gray40, size: 16),
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

                  // Premium Checkbox for Reminder
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.accent.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _addReminder
                            ? AppColors.primary.withOpacity(0.5)
                            : AppColors.gray70.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Custom Premium Checkbox
                        GestureDetector(
                          onTap: () {
                            setState(() => _addReminder = !_addReminder);
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: _addReminder
                                  ? LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.accent,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: _addReminder ? null : AppColors.gray70,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _addReminder
                                    ? Colors.transparent
                                    : AppColors.gray50,
                                width: 2,
                              ),
                            ),
                            child: _addReminder
                                ? Icon(
                                    Icons.check_rounded,
                                    color: AppColors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.notifications_active_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add Recurring Reminder',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Get notified for payments, recalls, or amortization',
                                style: TextStyle(
                                  color: AppColors.gray40,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reminder Form (Conditional)
                  if (_addReminder) ...[
                    const SizedBox(height: 24),
                    
                    // Reminder Section Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Reminder Configuration',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reminder Title
                    Text(
                      'Reminder Title',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reminderTitleController,
                      style: TextStyle(color: AppColors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g., Monthly Rent Payment, Loan Recall',
                        hintStyle: TextStyle(color: AppColors.gray50),
                        filled: true,
                        fillColor: AppColors.gray80,
                        prefixIcon: Icon(Icons.title_rounded, color: AppColors.primary),
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
                    const SizedBox(height: 20),

                    // Frequency Selection
                    Text(
                      'Recurrence Pattern',
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: _frequencies.length,
                      itemBuilder: (context, index) {
                        final freq = _frequencies[index];
                        final isSelected = _selectedFrequency == freq['value'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedFrequency = freq['value']),
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
                                  freq['icon'],
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.gray40,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    freq['label'],
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
                    const SizedBox(height: 20),

                    // Interval
                    Text(
                      'Repeat Every',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _interval > 1
                              ? () => setState(() => _interval--)
                              : null,
                          icon: Icon(
                            Icons.remove_circle_outline_rounded,
                            color: _interval > 1
                                ? AppColors.primary
                                : AppColors.gray60,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.gray80,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_interval ${_selectedFrequency.toLowerCase().replaceAll('ly', '')}(s)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _interval++),
                          icon: Icon(
                            Icons.add_circle_outline_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Next Event Date
                    Text(
                      'Next Event Date',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray80,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                DateFormat('EEEE, MMMM d, yyyy')
                                    .format(_nextEventDate),
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                color: AppColors.gray40, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recurrence Description
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.repeat_rounded, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getRecurrenceDescription(),
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Expected Amount (Optional)
                    Text(
                      'Expected Amount (Optional)',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reminderAmountController,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(color: AppColors.gray50),
                        filled: true,
                        fillColor: AppColors.gray80,
                        prefixIcon: Icon(Icons.attach_money_rounded,
                            color: AppColors.primary),
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
                  ],

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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_rounded, color: AppColors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    _addReminder
                                        ? 'Add Asset & Reminder'
                                        : 'Add Asset',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
