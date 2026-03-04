
import 'package:flutter/material.dart';
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
    // Watch the specific category to get updates
    final categoriesAsync = ref.watch(categoriesProvider(widget.category.type));
    
    // Proactively update _currentCategory if found
    categoriesAsync.whenData((categories) {
       final found = categories.cast<CategoryModel?>().firstWhere(
           (c) => c?.id == widget.category.id, 
           orElse: () => null,
       );
       if (found != null && mounted) {
           // We found the category in the updated list, so update our local state
           // Use setState is safer although technically build executes immediately after this
           // But since we are inside build, we shouldn't call setState.
           // Just updating the field is enough for this build pass? 
           // No, we cannot update state during build directly without risk.
           // Actually, since we are inside build(), we can just use a local variable
           // But we want to persist the OLD value if the new one is missing.
           // So:
           // If found -> _currentCategory = found;
           // If NOT found -> keep _currentCategory (stale/ghost);
           _currentCategory = found;
       }
    });

    final currentCategory = _currentCategory;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: Color(currentCategory.backgroundColor),
      appBar: AppBar(
        backgroundColor: Color(currentCategory.backgroundColor),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(currentCategory.textColor)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Color(currentCategory.textColor)),
            onPressed: () => _editCategory(context, ref, currentCategory),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Color(currentCategory.textColor)),
            onPressed: () => _confirmDelete(context, ref, currentCategory.id),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Hero(
              tag: 'card_${currentCategory.id}',
              child: Material( // Hero needs Material to avoid text style issues during flight
                color: Colors.transparent,
                child: Text(
                  currentCategory.name,
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(currentCategory.textColor),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: currentCategory.expenses.length + 1, // +1 for spacer or header
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Expense History',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  final expense = currentCategory.expenses[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Slidable(
                        key: Key(expense.id),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: 0.35, // Reduced width for 2 buttons
                          children: [
                            SlidableAction(
                              onPressed: (context) => _showEditExpenseDialog(context, ref, expense),
                              backgroundColor: Colors.teal.shade300, // Pastel Teal
                              foregroundColor: Colors.white,
                              icon: Icons.edit_rounded,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                            ),
                            SlidableAction(
                              onPressed: (context) => _confirmDeleteExpense(context, ref, expense.id),
                              backgroundColor: Colors.redAccent.shade100, // Pastel Coral/Red
                              foregroundColor: Colors.white,
                              icon: Icons.delete_rounded,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                            ),
                          ],
                        ),
                        child: Card(
                          elevation: 0,
                          color: Theme.of(context).cardColor,
                          margin: EdgeInsets.zero, // Margin handled by parent Padding for clean slide
                          child: ListTile(
                            title: Text(
                              expense.note.isEmpty ? 'Expense' : expense.note,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(dateFormat.format(expense.date)),
                            trailing: Text(
                              CurrencyFormatter.format(expense.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).primaryColor, 
                              ),
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
              builder: (context) => Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: QuickAddDialog(category: currentCategory)
              ),
            );
        },
        label: Text(
          'Add Expense',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        icon: const Icon(Icons.add),
        backgroundColor: Color(currentCategory.textColor),
        foregroundColor: Color(currentCategory.backgroundColor),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), // Pill shape
      ),
    );
  }

  void _editCategory(BuildContext context, WidgetRef ref, CategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    
    // Reverse engineer the base color
    Color currentCategoryColor = Color(category.backgroundColor);
    Color selectedBaseColor = AppTheme.baseColors[0];
    
    // Try to find matching base color
    for (var base in AppTheme.baseColors) {
      if (AppTheme.isSameBaseColor(base, currentCategoryColor)) {
        selectedBaseColor = base;
        break;
      }
      // Check shades
      final shades = AppTheme.getShades(base);
      if (shades.any((s) => s.toARGB32() == currentCategoryColor.toARGB32())) {
        selectedBaseColor = base;
        break;
      }
    }
    
    // If not found (legacy color?), stick with default or maybe the first base
    
    Color selectedColor = currentCategoryColor;
    Color textColor = Color(category.textColor);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: AlertDialog(
                title: const Text('Edit Category'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      style: GoogleFonts.nunito(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Category Name',
                        labelStyle: GoogleFonts.nunito(color: AppTheme.secretGrey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.secretGrey.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Base Colors
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: AppTheme.baseColors.map((baseColor) {
                                final isBaseSelected = AppTheme.isSameBaseColor(selectedBaseColor, baseColor);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedBaseColor = baseColor;
                                      final shades = AppTheme.getShades(baseColor);
                                      selectedColor = shades[4]; // Default mid-tone
                                      textColor = AppTheme.getContrastTextColor(selectedColor);
                                    });
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: baseColor,
                                      shape: BoxShape.circle,
                                      border: isBaseSelected 
                                        ? Border.all(color: AppTheme.textColor, width: 2.5)
                                        : Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
                                        boxShadow: [
                                          if (isBaseSelected)
                                            BoxShadow(
                                              color: baseColor.withValues(alpha: 0.4),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3)
                                            )
                                        ]
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 20),

                            // Separator
                            Row(
                              children: [
                                Expanded(child: Divider(color: AppTheme.secretGrey.withValues(alpha: 0.1))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Icon(Icons.palette_outlined, size: 16, color: AppTheme.secretGrey.withValues(alpha: 0.5)),
                                ),
                                Expanded(child: Divider(color: AppTheme.secretGrey.withValues(alpha: 0.1))),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Shades
                            Wrap(
                               spacing: 12,
                               runSpacing: 12,
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
                                     width: 40,
                                     height: 40,
                                     decoration: BoxDecoration(
                                       color: shadeColor,
                                       shape: BoxShape.circle,
                                       border: isSelected 
                                         ? Border.all(color: AppTheme.textColor, width: 2.5) 
                                         : Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
                                     ),
                                     child: isSelected 
                                       ? Icon(Icons.check, size: 20, color: textColor)
                                       : null,
                                   ),
                                 );
                               }).toList(),
                            ),

                            const SizedBox(height: 24),
                            
                            // Preview
                            Container(
                              width: double.maxFinite,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: selectedColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                nameController.text.isEmpty ? 'Category Name' : nameController.text,
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: GoogleFonts.nunito(color: AppTheme.secretGrey)),
                  ),
                  FilledButton(
                    onPressed: () {
                      final updated = category.copyWith(
                        name: nameController.text,
                        backgroundColor: selectedColor.toARGB32(),
                        textColor: textColor.toARGB32(),
                        type: category.type, // Ensure type is preserved
                      );
                      ref.read(categoriesProvider(category.type).notifier).updateCategory(updated);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String categoryId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category?'),
          content: const Text('All expenses in this category will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                // Delete: Await full deletion process
                await ref.read(categoriesProvider(widget.category.type).notifier).deleteCategory(categoryId);
                
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  if (context.mounted) {
                     Navigator.pop(context); // Close screen
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  void _confirmDeleteExpense(BuildContext context, WidgetRef ref, String expenseId) {
     showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Expense?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                ref.read(categoriesProvider(widget.category.type).notifier).deleteExpense(expenseId);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showEditExpenseDialog(BuildContext context, WidgetRef ref, ExpenseModel expense) {
    // Basic clean up of non-numeric chars for the input field, though user might want to see them?
    // Let's just strip ' đ' and dots if we want raw number editing, or keep it simple.
    // For now, let's just use the raw amount from the model.
    final amountController = TextEditingController(text: expense.amount.toInt().toString());
    final noteController = TextEditingController(text: expense.note);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  suffixText: 'đ',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                 final newAmount = double.tryParse(amountController.text) ?? expense.amount;
                 final newNote = noteController.text;
                 
                 final updatedExpense = ExpenseModel(
                   id: expense.id,
                   amount: newAmount,
                   note: newNote,
                   date: expense.date,
                   categoryId: expense.categoryId,
                   bankSource: expense.bankSource
                 );
                 
                 ref.read(categoriesProvider(widget.category.type).notifier).updateExpense(updatedExpense);
                 Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
