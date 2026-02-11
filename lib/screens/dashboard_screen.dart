
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:uuid/uuid.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../providers/providers.dart';
import '../data/models/category_model.dart';
import '../widgets/expense_card.dart';
import '../widgets/column_toggle.dart';
import '../widgets/month_selector.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Removed unused _baseScaleFactor

  void _handleScaleStart(ScaleStartDetails details) {
    // Reset base if needed
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // Basic pinch detection
    if (details.scale != 1.0) {
       final currentCols = ref.read(columnCountProvider);
       // Zoom in (expand items) -> fewer columns
       if (details.scale > 1.2 && currentCols > 1) {
         ref.read(columnCountProvider.notifier).state = currentCols - 1;
       } 
       // Zoom out (shrink items) -> more columns
       else if (details.scale < 0.8 && currentCols < 4) {
         ref.read(columnCountProvider.notifier).state = currentCols + 1;
       }
    }
  }

  void _addNewCategory() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        Color selectedColor = const Color(0xFFE1F5FE); // Default light blue
        Color textColor = Colors.black87;

        return AlertDialog(
          title: const Text('New Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              const SizedBox(height: 16),
              const Text('Pick Color'),
              ColorPicker(
                color: selectedColor,
                onColorChanged: (color) {
                    selectedColor = color;
                    // Simple logic for text color based on brightness
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
                if (controller.text.isNotEmpty) {
                  final newCategory = CategoryModel(
                    id: const Uuid().v4(),
                    name: controller.text,
                    backgroundColor: selectedColor.toARGB32(),
                    textColor: textColor.toARGB32(),
                    sortOrder: 999, // Will be last
                  );
                  ref.read(categoriesProvider.notifier).addCategory(newCategory);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Grid Layout'),
              const SizedBox(height: 16),
              const ColumnToggle(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final columnCount = ref.watch(columnCountProvider);
    // Removed unused month variable

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thành tiêu tiền'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Column(
            children: [
              MonthSelector(),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        child: Column(
          children: [
            // Removed ColumnToggle from here
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (categories) {
                  if (categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.note_add, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No categories yet.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: _addNewCategory,
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Category'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Calculate total spent
                  final totalSpent = categories.fold<double>(
                      0, (sum, cat) => sum + cat.expenses.fold<double>(0, (s, e) => s + e.amount));

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Spent:', 
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Text(
                              '\$${totalSpent.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: MasonryGridView.count(
                          crossAxisCount: columnCount,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          padding: const EdgeInsets.all(8),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return LongPressDraggable<CategoryModel>(
                              data: category,
                              feedback: SizedBox(
                                width: (MediaQuery.of(context).size.width / columnCount) - 16,
                                child: Opacity(
                                  opacity: 0.7,
                                  child: ExpenseCard(category: category),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: ExpenseCard(category: category),
                              ),
                              child: DragTarget<CategoryModel>(
                                onWillAcceptWithDetails: (details) => details.data.id != category.id,
                                onAcceptWithDetails: (details) {
                                  final droppedCategory = details.data;
                                  // Reorder logic: swap sortOrder of droppedCategory and category
                                  // We need to create a new list with updated sortOrders
                                  final newCategories = List<CategoryModel>.from(categories);
                                  
                                  final droppedIndex = newCategories.indexWhere((c) => c.id == droppedCategory.id);
                                  final targetIndex = newCategories.indexWhere((c) => c.id == category.id);
                                  
                                  final temp = newCategories[droppedIndex];
                                  newCategories[droppedIndex] = newCategories[targetIndex];
                                  newCategories[targetIndex] = temp;
                                  
                                  ref.read(categoriesProvider.notifier).reorderCategories(newCategories);
                                },
                                builder: (context, candidateData, rejectedData) {
                                  return ExpenseCard(category: category);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewCategory,
        child: const Icon(Icons.add),
      ),
    );
  }
}
