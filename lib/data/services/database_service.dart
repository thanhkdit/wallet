
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category_model.dart';
import '../models/expense_model.dart';

class DatabaseService {
  static const String _categoriesBoxName = 'categories';
  static const String _expensesBoxName = 'expenses';

  late Box<CategoryModel> _categoriesBox;
  late Box<ExpenseModel> _expensesBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(ExpenseModelAdapter());

    _categoriesBox = await Hive.openBox<CategoryModel>(_categoriesBoxName);
    _expensesBox = await Hive.openBox<ExpenseModel>(_expensesBoxName);
  }

  // Categories
  List<CategoryModel> getAllCategories() {
    final categories = _categoriesBox.values.toList();
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return categories;
  }

  Future<void> addCategory(CategoryModel category) async {
    await _categoriesBox.put(category.id, category);
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _categoriesBox.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    await _categoriesBox.delete(id);
    // Also delete associated expenses? Or keep them as orphans?
    // For now, let's keep them (or delete, user choice usually).
    // Let's delete them to be clean.
    final expensesToDelete = _expensesBox.values.where((e) => e.categoryId == id).map((e) => e.id).toList();
    for (var expenseId in expensesToDelete) {
      await _expensesBox.delete(expenseId);
    }
  }
  
  Future<void> reorderCategories(List<CategoryModel> categories) async {
      for (int i = 0; i < categories.length; i++) {
        final cat = categories[i];
        // We use a new object because we can't modify the object in the box directly if it's immutable
        // But Hive objects are mutable if we extend HiveObject.
        // However, we used copyWith in model, suggesting immutability pattern.
        // Let's just put with new sortOrder.
        final newCat = CategoryModel(
            id: cat.id,
            name: cat.name,
            backgroundColor: cat.backgroundColor,
            textColor: cat.textColor,
            sortOrder: i,
            expenses: [] // Expenses are runtime
        );
        await _categoriesBox.put(cat.id, newCat);
      }
  }

  // Expenses
  List<ExpenseModel> getExpensesForMonth(DateTime month) {
    return _expensesBox.values.where((e) {
      return e.date.year == month.year && e.date.month == month.month;
    }).toList();
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _expensesBox.put(expense.id, expense);
  }

  Future<void> deleteExpense(String id) async {
    await _expensesBox.delete(id);
  }

  // Aggregation
  List<CategoryModel> getCategoriesWithExpenses(DateTime month) {
    final categories = getAllCategories();
    final expenses = getExpensesForMonth(month);

    // Map expenses to categories
    Map<String, List<ExpenseModel>> expensesByCategory = {};
    for (var expense in expenses) {
      if (!expensesByCategory.containsKey(expense.categoryId)) {
        expensesByCategory[expense.categoryId] = [];
      }
      expensesByCategory[expense.categoryId]!.add(expense);
    }
    
    // Sort expenses by date desc
    for (var key in expensesByCategory.keys) {
        expensesByCategory[key]!.sort((a, b) => b.date.compareTo(a.date));
    }

    // Populate categories
    return categories.map((cat) {
      // Create a copy with expenses
      return CategoryModel(
        id: cat.id,
        name: cat.name,
        backgroundColor: cat.backgroundColor,
        textColor: cat.textColor,
        sortOrder: cat.sortOrder,
        expenses: expensesByCategory[cat.id] ?? [],
      );
    }).toList();
  }
}
