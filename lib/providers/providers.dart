
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category_model.dart';
import '../data/models/expense_model.dart';
import '../data/services/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final columnCountProvider = StateProvider<int>((ref) => 2);

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, AsyncValue<List<CategoryModel>>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final month = ref.watch(selectedMonthProvider);
  return CategoriesNotifier(dbService, month);
});

class CategoriesNotifier extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final DatabaseService _dbService;
  final DateTime _month;

  CategoriesNotifier(this._dbService, this._month) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final categories = _dbService.getCategoriesWithExpenses(_month);
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    await _dbService.addCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _dbService.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _dbService.deleteCategory(id);
    await loadCategories();
  }
  
  Future<void> reorderCategories(List<CategoryModel> categories) async {
      // Optimistic update
      state = AsyncValue.data(categories);
      await _dbService.reorderCategories(categories);
      // No need to reload as we updated optimistically, but safety check:
      // await loadCategories(); 
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _dbService.addExpense(expense);
    await loadCategories();
  }

  Future<void> deleteExpense(String id) async {
    await _dbService.deleteExpense(id);
    await loadCategories();
  }
}
