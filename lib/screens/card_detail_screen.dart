import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../data/models/category_model.dart';
import '../data/models/expense_model.dart';
import '../providers/providers.dart';
import '../widgets/quick_add_dialog.dart';

class CardDetailScreen extends ConsumerStatefulWidget {
  final CategoryModel category;

  const CardDetailScreen({super.key, required this.category});

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  late CategoryModel _currentCategory;

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.category;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider(widget.category.type));

    categoriesAsync.whenData((categories) {
      final found = categories.cast<CategoryModel?>().firstWhere(
            (c) => c?.id == widget.category.id,
        orElse: () => null,
      );
      if (found != null && mounted) {
        _currentCategory = found;
      }
    });

    final currentCategory = _currentCategory;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final totalAmount = currentCategory.expenses.fold(0.0, (sum, item) => sum + item.amount);

    final bgColor = Color(currentCategory.backgroundColor);
    final textColor = Color(currentCategory.textColor);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_rounded, color: textColor),
            onPressed: () => _showEditCategorySheet(context, currentCategory),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: textColor),
            onPressed: () => _confirmDelete(context, currentCategory.id),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'card_${currentCategory.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      currentCategory.name,
                      style: GoogleFonts.nunito(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Total: ${CurrencyFormatter.format(totalAmount)}',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    )
                  ]
              ),
              child: currentCategory.expenses.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.secretGrey.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'Empty',
                      style: GoogleFonts.nunito(fontSize: 16, color: AppTheme.secretGrey, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                physics: const BouncingScrollPhysics(),
                itemCount: currentCategory.expenses.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'History',
                        style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textColor),
                      ),
                    );
                  }

                  final expense = currentCategory.expenses[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Slidable(
                      key: Key(expense.id),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.45,
                        children: [
                          const SizedBox(width: 8),
                          SlidableAction(
                            onPressed: (context) => _showEditExpenseSheet(context, expense, currentCategory),
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            foregroundColor: AppTheme.primaryColor,
                            icon: Icons.edit_rounded,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          const SizedBox(width: 8),
                          SlidableAction(
                            onPressed: (context) => _confirmDeleteExpense(context, expense.id),
                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                            foregroundColor: Colors.red,
                            icon: Icons.delete_rounded,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.secretGrey.withValues(alpha: 0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secretGrey.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: bgColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.shopping_bag_rounded, color: bgColor, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      expense.note.isEmpty ? 'Chi tiêu' : expense.note,
                                      style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateFormat.format(expense.date),
                                      style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.secretGrey, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(expense.amount),
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: AppTheme.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => QuickAddDialog(category: currentCategory)
          );
        },
        label: Text(
          'Add new expense',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: textColor,
        foregroundColor: bgColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showEditCategorySheet(BuildContext context, CategoryModel category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditCategorySheet(category: category),
    );
  }

  void _showEditExpenseSheet(BuildContext context, ExpenseModel expense, CategoryModel category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditExpenseSheet(expense: expense, category: category),
    );
  }

  void _confirmDelete(BuildContext context, String categoryId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Xóa danh mục?', style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
          content: Text(
            'Toàn bộ lịch sử chi tiêu trong danh mục này sẽ bị xóa. Bạn có chắc chắn không?',
            style: GoogleFonts.nunito(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.nunito(color: AppTheme.secretGrey, fontWeight: FontWeight.bold)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: () async {
                await ref.read(categoriesProvider(widget.category.type).notifier).deleteCategory(categoryId);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text('Delete', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteExpense(BuildContext context, String expenseId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Xóa giao dịch?', style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
          content: Text('Hành động này không thể hoàn tác.', style: GoogleFonts.nunito(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.nunito(color: AppTheme.secretGrey, fontWeight: FontWeight.bold)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: () {
                ref.read(categoriesProvider(widget.category.type).notifier).deleteExpense(expenseId);
                Navigator.pop(context);
              },
              child: Text('Delete', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

class _EditCategorySheet extends ConsumerStatefulWidget {
  final CategoryModel category;
  const _EditCategorySheet({required this.category});

  @override
  ConsumerState<_EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends ConsumerState<_EditCategorySheet> {
  late TextEditingController _nameController;
  late Color selectedBaseColor;
  late Color selectedColor;
  late Color textColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);

    Color currentCategoryColor = Color(widget.category.backgroundColor);
    selectedBaseColor = AppTheme.baseColors[0];

    for (var base in AppTheme.baseColors) {
      if (AppTheme.isSameBaseColor(base, currentCategoryColor)) {
        selectedBaseColor = base;
        break;
      }
      final shades = AppTheme.getShades(base);
      if (shades.any((s) => s.toARGB32() == currentCategoryColor.toARGB32())) {
        selectedBaseColor = base;
        break;
      }
    }

    selectedColor = currentCategoryColor;
    textColor = Color(widget.category.textColor);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isNotEmpty) {
      final updated = widget.category.copyWith(
        name: _nameController.text.trim(),
        backgroundColor: selectedColor.toARGB32(),
        textColor: textColor.toARGB32(),
        type: widget.category.type,
      );
      ref.read(categoriesProvider(widget.category.type).notifier).updateCategory(updated);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 12, left: 24, right: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.secretGrey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Sửa danh mục', style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            const SizedBox(height: 24),

            // Preview
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                _nameController.text.isEmpty ? 'Tên danh mục' : _nameController.text,
                style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (val) => setState(() {}),
              onSubmitted: (_) => _save(),
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                filled: true, fillColor: AppTheme.secretGrey.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: AppTheme.baseColors.map((baseColor) {
                  final isBaseSelected = AppTheme.isSameBaseColor(selectedBaseColor, baseColor);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedBaseColor = baseColor;
                        selectedColor = AppTheme.getShades(baseColor)[4];
                        textColor = AppTheme.getContrastTextColor(selectedColor);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40, margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: baseColor, shape: BoxShape.circle,
                        border: isBaseSelected ? Border.all(color: AppTheme.textColor, width: 3) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            Wrap(
              spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
              children: AppTheme.getShades(selectedBaseColor).map((shadeColor) {
                final isSelected = selectedColor.toARGB32() == shadeColor.toARGB32();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = shadeColor;
                      textColor = AppTheme.getContrastTextColor(selectedColor);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: shadeColor, shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: AppTheme.textColor, width: 2.5) : null,
                    ),
                    child: isSelected ? Icon(Icons.check, size: 18, color: textColor) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Lưu thay đổi', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditExpenseSheet extends ConsumerStatefulWidget {
  final ExpenseModel expense;
  final CategoryModel category;

  const _EditExpenseSheet({required this.expense, required this.category});

  @override
  ConsumerState<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends ConsumerState<_EditExpenseSheet> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final formattedAmount = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0)
        .format(widget.expense.amount)
        .replaceAll(',', '.');
    _amountController = TextEditingController(text: formattedAmount);
    _noteController = TextEditingController(text: widget.expense.note);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final cleanAmountString = _amountController.text.replaceAll('.', '').trim();
      final newAmount = double.tryParse(cleanAmountString) ?? widget.expense.amount;
      final newNote = _noteController.text.trim();

      final updatedExpense = ExpenseModel(
          id: widget.expense.id,
          amount: newAmount,
          note: newNote,
          date: widget.expense.date,
          categoryId: widget.expense.categoryId,
          bankSource: widget.expense.bankSource
      );

      ref.read(categoriesProvider(widget.category.type).notifier).updateExpense(updatedExpense);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(widget.category.backgroundColor);
    final categoryTextColor = Color(widget.category.textColor);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 12, left: 20, right: 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10)),
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
                  decoration: BoxDecoration(color: AppTheme.secretGrey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
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
                      decoration: BoxDecoration(color: categoryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(Icons.edit_rounded, size: 18, color: categoryColor),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Sửa giao dịch',
                      style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textColor),
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
                  prefixText: '\$ ',
                  prefixStyle: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold, color: categoryColor),
                  filled: true, fillColor: categoryColor.withValues(alpha: 0.05),
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
                onFieldSubmitted: (_) => _save(),
                enableSuggestions: false,
                autocorrect: false,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Ghi chú...',
                  prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                  filled: true, fillColor: AppTheme.secretGrey.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: categoryColor,
                    foregroundColor: categoryTextColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Lưu thay đổi', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800)),
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
    if (newValue.text.isEmpty) return newValue;
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');
    double value = double.parse(cleanText);
    String formatted = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0)
        .format(value).replaceAll(',', '.');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}