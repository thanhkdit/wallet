
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

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, AsyncValue<List<CategoryModel>>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final filterState = ref.watch(dateFilterProvider);
  return CategoriesNotifier(dbService, filterState);
});

class CategoriesNotifier extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final DatabaseService _dbService;
  final DateFilterState _filterState;

  CategoriesNotifier(this._dbService, this._filterState) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      late List<CategoryModel> categories;
      
      switch (_filterState.mode) {
        case DateFilterMode.month:
          categories = _dbService.getCategoriesWithExpenses(_filterState.selectedDate);
          break;
        case DateFilterMode.year:
          final start = DateTime(_filterState.selectedDate.year, 1, 1);
          final end = DateTime(_filterState.selectedDate.year, 12, 31, 23, 59, 59);
          categories = _dbService.getCategoriesWithExpensesInRange(start, end);
          break;
        case DateFilterMode.custom:
          if (_filterState.customRange != null) {
            final start = _filterState.customRange!.start;
            final end = _filterState.customRange!.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
            categories = _dbService.getCategoriesWithExpensesInRange(start, end);
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
}
