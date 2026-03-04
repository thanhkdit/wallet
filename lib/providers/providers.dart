
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category_model.dart';
import '../data/models/expense_model.dart';
import '../data/services/database_service.dart';


final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

enum DateFilterMode { month, year, custom }

class DateFilterState {
  final DateFilterMode mode;
  final DateTime selectedDate; // For month/year
  final DateTimeRange? customRange; // For custom range

  DateFilterState({
    required this.mode,
    required this.selectedDate,
    this.customRange,
  });

  DateFilterState copyWith({
    DateFilterMode? mode,
    DateTime? selectedDate,
    DateTimeRange? customRange,
  }) {
    return DateFilterState(
      mode: mode ?? this.mode,
      selectedDate: selectedDate ?? this.selectedDate,
      customRange: customRange ?? this.customRange,
    );
  }
}

final dateFilterProvider = StateProvider<DateFilterState>((ref) {
  final now = DateTime.now();
  return DateFilterState(
    mode: DateFilterMode.month, 
    selectedDate: DateTime(now.year, now.month),
  );
});

// Backward compatibility for MonthSelector if needed, or we just update MonthSelector
final selectedMonthProvider = Provider<DateTime>((ref) {
  return ref.watch(dateFilterProvider).selectedDate;
});



final columnCountProvider = StateProvider<int>((ref) => 2);

final categoriesProvider = StateNotifierProvider.family<CategoriesNotifier, AsyncValue<List<CategoryModel>>, CategoryType>((ref, type) {
  final dbService = ref.watch(databaseServiceProvider);
  final filterState = ref.watch(dateFilterProvider);
  return CategoriesNotifier(dbService, filterState, type);
});

class CategoriesNotifier extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final DatabaseService _dbService;
  final DateFilterState _filterState;
  final CategoryType _type;

  CategoriesNotifier(this._dbService, this._filterState, this._type) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      late List<CategoryModel> categories;
      
      switch (_filterState.mode) {
        case DateFilterMode.month:
          categories = _dbService.getCategoriesWithExpenses(_filterState.selectedDate, type: _type);
          break;
        case DateFilterMode.year:
          final start = DateTime(_filterState.selectedDate.year, 1, 1);
          final end = DateTime(_filterState.selectedDate.year, 12, 31, 23, 59, 59);
          categories = _dbService.getCategoriesWithExpensesInRange(start, end, type: _type);
          break;
        case DateFilterMode.custom:
          if (_filterState.customRange != null) {
            final start = _filterState.customRange!.start;
            final end = _filterState.customRange!.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
            categories = _dbService.getCategoriesWithExpensesInRange(start, end, type: _type);
          } else {
             // Fallback
             categories = [];
          }
          break;
      }
      
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

  Future<void> updateExpense(ExpenseModel expense) async {
    await _dbService.updateExpense(expense);
    await loadCategories();
  }
}

// Balance Provider
final balanceProvider = Provider<({double income, double expense, double balance})>((ref) {
  final incomeCategories = ref.watch(categoriesProvider(CategoryType.income)).asData?.value ?? [];
  final expenseCategories = ref.watch(categoriesProvider(CategoryType.expense)).asData?.value ?? [];

  final totalIncome = incomeCategories.fold<double>(
      0, (sum, cat) => sum + cat.expenses.fold(0, (s, e) => s + e.amount));

  final totalExpense = expenseCategories.fold<double>(
      0, (sum, cat) => sum + cat.expenses.fold(0, (s, e) => s + e.amount));

  return (
    income: totalIncome,
    expense: totalExpense,
    balance: totalIncome - totalExpense,
  );
});
