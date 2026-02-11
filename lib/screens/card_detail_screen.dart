
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
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
            label: const Text('Add Expense'),
            icon: const Icon(Icons.add),
            backgroundColor: Color(currentCategory.textColor), // Contrast
            foregroundColor: Color(currentCategory.backgroundColor),
          ),
        );
      },
    );
  }

  void _editCategory(BuildContext context, WidgetRef ref, CategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    Color selectedColor = Color(category.backgroundColor);
    Color textColor = Color(category.textColor);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              const SizedBox(height: 16),
              const Text('Pick Color'),
              ColorPicker(
                color: selectedColor,
                onColorChanged: (color) {
                    selectedColor = color;
                    textColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark 
                        ? Colors.white 
                        : Colors.black87;
                },
                width: 40,
                height: 40,
                borderRadius: 20,
                spacing: 10,
                runSpacing: 10,
                heading: const SizedBox(),
                subheading: const SizedBox(),
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
                final updated = category.copyWith(
                  name: nameController.text,
                  backgroundColor: selectedColor.toARGB32(),
                  textColor: textColor.toARGB32(),
                );
                ref.read(categoriesProvider.notifier).updateCategory(updated);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
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
