
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../data/models/category_model.dart';
import '../providers/providers.dart';
import '../widgets/quick_add_dialog.dart';

class CardDetailScreen extends ConsumerWidget {
  final CategoryModel category;

  const CardDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the specific category to get updates
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return categoriesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (categories) {
        // Find the updated category
        final updatedCategory = categories.cast<CategoryModel?>().firstWhere(
              (c) => c?.id == category.id,
              orElse: () => null,
            );

        // If category was deleted, pop
        if (updatedCategory == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
             if (context.mounted) Navigator.pop(context);
          });
          return const SizedBox();
        }

        final currentCategory = updatedCategory;
        final currencyFormat = NumberFormat.simpleCurrency();
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
                      return Dismissible(
                        key: Key(expense.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(categoriesProvider.notifier).deleteExpense(expense.id);
                        },
                        child: Card(
                          elevation: 0,
                          color: Theme.of(context).cardColor,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              expense.note.isEmpty ? 'Expense' : expense.note,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(dateFormat.format(expense.date)),
                            trailing: Text(
                              currencyFormat.format(expense.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).primaryColor, // Use theme primary (yellow) or text color
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
      },
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
                      );
                      ref.read(categoriesProvider.notifier).updateCategory(updated);
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
              onPressed: () {
                ref.read(categoriesProvider.notifier).deleteCategory(categoryId);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close screen
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
