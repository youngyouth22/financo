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

/// Page for adding recurring reminders to assets
///
/// Features:
/// - Asset selection
/// - Reminder title
/// - Recurrence pattern (RRULE)
/// - Next event date picker
/// - Amount expected (optional)
/// - Form validation
/// - BLoC integration
class AddAssetReminderPage extends StatefulWidget {
  final String? assetId;
  final String? assetName;

  const AddAssetReminderPage({
    super.key,
    this.assetId,
    this.assetName,
  });

  @override
  State<AddAssetReminderPage> createState() => _AddAssetReminderPageState();
}

class _AddAssetReminderPageState extends State<AddAssetReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedAssetId;
  String? _selectedAssetName;
  String _selectedFrequency = 'MONTHLY';
  int _interval = 1;
  DateTime _nextEventDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;

  final List<Map<String, dynamic>> _frequencies = [
    {'value': 'DAILY', 'label': 'Daily', 'icon': Icons.today_rounded},
    {'value': 'WEEKLY', 'label': 'Weekly', 'icon': Icons.calendar_view_week_rounded},
    {'value': 'MONTHLY', 'label': 'Monthly', 'icon': Icons.calendar_month_rounded},
    {'value': 'YEARLY', 'label': 'Yearly', 'icon': Icons.calendar_today_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _selectedAssetId = widget.assetId;
    _selectedAssetName = widget.assetName;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _generateRRule() {
    // Generate RRULE expression based on frequency and interval
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
    final rruleString = _generateRRule();
    try {
      final rrule = RecurrenceRule.fromString(rruleString);
      
      // Generate human-readable description
      String description = '';
      if (_interval == 1) {
        switch (_selectedFrequency) {
          case 'DAILY':
            description = 'Every day';
            break;
          case 'WEEKLY':
            final weekday = DateFormat('EEEE').format(_nextEventDate);
            description = 'Every $weekday';
            break;
          case 'MONTHLY':
            description = 'Every month on day ${_nextEventDate.day}';
            break;
          case 'YEARLY':
            final date = DateFormat('MMMM d').format(_nextEventDate);
            description = 'Every year on $date';
            break;
        }
      } else {
        switch (_selectedFrequency) {
          case 'DAILY':
            description = 'Every $_interval days';
            break;
          case 'WEEKLY':
            final weekday = DateFormat('EEEE').format(_nextEventDate);
            description = 'Every $_interval weeks on $weekday';
            break;
          case 'MONTHLY':
            description = 'Every $_interval months on day ${_nextEventDate.day}';
            break;
          case 'YEARLY':
            final date = DateFormat('MMMM d').format(_nextEventDate);
            description = 'Every $_interval years on $date';
            break;
        }
      }
      return description;
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

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedAssetId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select an asset'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final rruleExpression = _generateRRule();
      final amount = _amountController.text.trim().isEmpty
          ? null
          : double.tryParse(_amountController.text.replaceAll(',', ''));

      context.read<FinanceBloc>().add(
            AddAssetReminderEvent(
              assetId: _selectedAssetId!,
              title: _titleController.text.trim(),
              rruleExpression: rruleExpression,
              nextEventDate: _nextEventDate,
              amountExpected: amount,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FinanceBloc>(),
      child: BlocListener<FinanceBloc, FinanceState>(
        listener: (context, state) {
          if (state is FinanceLoading) {
            setState(() => _isLoading = true);
          } else if (state is AssetReminderAdded) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✓ Reminder added successfully!'),
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
              'Add Reminder',
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
                  // Asset Selection (if not pre-selected)
                  if (_selectedAssetId == null) ...[
                    Text(
                      'Select Asset',
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: AppColors.gray40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Select an asset to add reminder',
                              style: TextStyle(color: AppColors.gray50, fontSize: 16),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, color: AppColors.gray40, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Text(
                      'Asset',
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedAssetName ?? 'Selected Asset',
                              style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

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
                    controller: _titleController,
                    style: TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g., Monthly Mortgage Payment',
                      hintStyle: TextStyle(color: AppColors.gray50),
                      filled: true,
                      fillColor: AppColors.gray80,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter reminder title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Frequency Selection
                  Text(
                    'Recurrence',
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
                        onTap: () => setState(() => _selectedFrequency = freq['value']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.gray80,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Icon(
                                freq['icon'],
                                color: isSelected ? AppColors.primary : AppColors.gray40,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  freq['label'],
                                  style: TextStyle(
                                    color: isSelected ? AppColors.white : AppColors.gray30,
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

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
                        onPressed: _interval > 1 ? () => setState(() => _interval--) : null,
                        icon: Icon(Icons.remove_circle_outline_rounded, color: _interval > 1 ? AppColors.primary : AppColors.gray60),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.gray80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            '$_interval',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _interval < 99 ? () => setState(() => _interval++) : null,
                        icon: Icon(Icons.add_circle_outline_rounded, color: _interval < 99 ? AppColors.primary : AppColors.gray60),
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
                      decoration: BoxDecoration(
                        color: AppColors.gray80,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(_nextEventDate),
                              style: TextStyle(color: AppColors.white, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recurrence Description
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
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

                  // Amount Expected (Optional)
                  Text(
                    'Amount Expected (Optional)',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: AppColors.gray50),
                      prefixText: '\$ ',
                      prefixStyle: TextStyle(color: AppColors.gray40, fontSize: 18),
                      filled: true,
                      fillColor: AppColors.gray80,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
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
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : Text(
                              'Create Reminder',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
