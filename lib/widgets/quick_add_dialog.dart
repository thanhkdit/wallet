import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../data/models/category_model.dart';
import '../data/models/expense_model.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

class QuickAddDialog extends ConsumerStatefulWidget {
  final CategoryModel category;

  const QuickAddDialog({super.key, required this.category});

  @override
  ConsumerState<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends ConsumerState<QuickAddDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final cleanAmountString = _amountController.text.replaceAll('.', '').trim();
      final amount = double.tryParse(cleanAmountString) ?? 0.0;
      final note = _noteController.text.trim();

      final expense = ExpenseModel(
        id: const Uuid().v4(),
        categoryId: widget.category.id,
        amount: amount,
        note: note,
        date: DateTime.now(),
      );

      ref.read(categoriesProvider(widget.category.type).notifier).addExpense(expense);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(widget.category.backgroundColor);
    final categoryTextColor = Color(widget.category.textColor);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 12, 16, keyboardHeight > 0 ? 12 : 24),
      padding: EdgeInsets.only(
        bottom: keyboardHeight + 25,
        top: 12, left: 20, right: 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.secretGrey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_shopping_cart_rounded, size: 18, color: categoryColor),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Thêm vào ${widget.category.name}',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                enableSuggestions: false,
                autocorrect: false,
                maxLines: 3,
                minLines: 1,

                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CurrencyInputFormatter(),
                ],

                style: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w900, color: categoryColor),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(color: categoryColor.withValues(alpha: 0.3)),
                  prefixText: '\$ ',
                  prefixStyle: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold, color: categoryColor),
                  filled: true,
                  fillColor: categoryColor.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập số tiền';
                  final cleanValue = value.replaceAll('.', '').trim();
                  if (double.tryParse(cleanValue) == null) return 'Số tiền không hợp lệ';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _noteController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveExpense(),
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Ghi chú...',
                  prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                  filled: true,
                  fillColor: AppTheme.secretGrey.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _saveExpense,
                  style: FilledButton.styleFrom(
                    backgroundColor: categoryColor,
                    foregroundColor: categoryTextColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Xác nhận',
                    style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');

    double value = double.parse(cleanText);
    String formatted = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0)
        .format(value)
        .replaceAll(',', '.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}