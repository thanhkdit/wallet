
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../data/models/category_model.dart';
import '../widgets/expense_card.dart';
import '../widgets/column_toggle.dart';
import '../widgets/month_selector.dart';
import '../theme/app_theme.dart';

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
        Color selectedBaseColor = AppTheme.baseColors[0]; // Light Yellow
        // Default to the base color itself (which is index 0 of shades usually if logic aligns, 
        // but our getShades generates new ones. Let's pick a nice middle-light shade or just the base itself if it's in the list.
        // Actually, let's pick the 2nd or 3rd shade which is usually the "nice" color.
        Color selectedColor = AppTheme.baseColors[0]; 
        Color textColor = AppTheme.getContrastTextColor(selectedColor);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children to fill dialog width
                children: [
                  TextField(
                    controller: controller,
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
                  const SizedBox(height: 24),
                  // Aesthetic Color Picker (Wrap Layout)
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
                            // Auto-select a nice mid-tone (index 4 out of 10)
                            final shades = AppTheme.getShades(baseColor);
                            selectedColor = shades[4]; 
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

                  // Modern Separator
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

                  // Shades (Wrap Layout)
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
                      controller.text.isEmpty ? 'Category Name' : controller.text,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor, // Fixed color
                      ),
                      textAlign: TextAlign.center,
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
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Add', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
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
              const Text('Grid Layout', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const ColumnToggle(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: GoogleFonts.nunito(color: AppTheme.textColor)),
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

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48), // Spacer to center title (approximate)
                        Text(
                          'Thành tiêu tiền',
                          style: GoogleFonts.nunito(
                            fontSize: 28, // Large
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textColor,
                          ),
                        ),
                        IconButton(
                          onPressed: _showSettingsDialog,
                          icon: const Icon(Icons.settings, color: AppTheme.textColor, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const MonthSelector(),
                    // ColumnToggle moved to Settings Dialog
                  ],
                ),
              ),
              
              const SizedBox(height: 16),

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
                            Icon(Icons.note_add, size: 64, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'No categories yet.',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: _addNewCategory,
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Category'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Calculate total spent
                    // Handle potential null expenses at runtime even if type says non-nullable
                    final totalSpent = categories.fold<double>(
                        0, (sum, cat) => sum + ((cat.expenses as List<dynamic>?) ?? []).fold<double>(0, (s, e) => s + (e as dynamic).amount));
                    
                    // Thousands separator formatter
                    // Assuming 'vi' locale or custom pattern for dots
                    // but using a standard pattern with comma for now, user asked format "41.000.000"
                    // which is Vietnamese/German style. I will use a custom pattern.
                    // Thousands separator formatter (Safe version)
                    // Using en_US (reliable) and replacing commas with dots to match user preference "41.000.000"
                    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0);
                    String formatCurrency(double amount) {
                      return currencyFormat.format(amount).replaceAll(',', '.');
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Spent:', 
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.secretGrey,
                                ),
                              ),
                              Text(
                                // Manually formatting if needed or using correct locale
                                '\$${formatCurrency(totalSpent)}',
                                style: GoogleFonts.nunito(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: MasonryGridView.count(
                            crossAxisCount: columnCount,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // Bottom padding for FAB
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              return LongPressDraggable<CategoryModel>(
                                data: category,
                                feedback: SizedBox(
                                  width: (MediaQuery.of(context).size.width / columnCount) - 16,
                                  child: Opacity(
                                    opacity: 0.85,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewCategory,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

// Quick helper for NumberFormat until intl import is fixed in this scope if needed
// Actually we need to import intl
// Added import 'package:intl/intl.dart' as java.text is not valid dart

