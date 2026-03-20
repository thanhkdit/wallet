import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/google_drive_service.dart';
import '../data/models/category_model.dart';
import '../data/models/expense_model.dart';
import '../providers/providers.dart'; // To access hive boxes/repositories if needed
import 'package:hive_flutter/hive_flutter.dart';

enum SyncState { idle, syncing, conflict, success, error }

class SyncStateData {
  final SyncState state;
  final String? errorMessage;

  const SyncStateData({this.state = SyncState.idle, this.errorMessage});

  SyncStateData copyWith({SyncState? state, String? errorMessage}) {
    return SyncStateData(
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncStateData> {
  final Ref ref;
  final GoogleDriveService _driveService;
  SyncNotifier(this.ref, this._driveService) : super(const SyncStateData()) {
    _driveService.isSignedInNotifier.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    final isSignedIn = _driveService.isSignedInNotifier.value;
    if (isSignedIn) {
      state = state.copyWith(state: SyncState.idle); // User signed in, reset state
    } else {
      state = const SyncStateData(state: SyncState.idle); // User signed out, reset state
    }
  }

  /// Checks if a weekly auto-sync should run, and triggers it if so.
  Future<void> attemptWeeklyAutoSync() async {
    final settingsBox = Hive.box('settings');
    final autoSyncEnabled = settingsBox.get('autoSyncEnabled', defaultValue: false) as bool;
    if (!autoSyncEnabled) return;

    // Only auto-sync if the user is already signed in
    if (!_driveService.isSignedIn) return;

    final lastSyncMillis = settingsBox.get('lastAutoSyncTime', defaultValue: 0) as int;
    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    final now = DateTime.now();

    // Check if 2 minutes have passed since the last sync (for testing)
    if (now.difference(lastSyncTime).inMinutes >= 2) {
      await handleSync();
      // Save the timestamp after a successful sync attempt
      if (state.state == SyncState.success || state.state == SyncState.conflict) {
        await settingsBox.put('lastAutoSyncTime', now.millisecondsSinceEpoch);
      }
    }
  }

  @override
  void dispose() {
    _driveService.isSignedInNotifier.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  Future<void> signIn() async {
    try {
      final success = await _driveService.signIn();
      if (success) {
        state = state.copyWith(state: SyncState.idle); // trigger rebuild to show profile
      }
    } catch (e) {
      state = state.copyWith(state: SyncState.error, errorMessage: e.toString());
    }
  }
  
  Future<void> signOut() async {
    await _driveService.signOut();
    state = state.copyWith(state: SyncState.idle);
  }

  Future<void> handleSync() async {
    if (!_driveService.isSignedIn) {
      await signIn();
      if (!_driveService.isSignedIn) return;
    }

    if (_driveService.driveApi == null) {
      final success = await _driveService.authorize();
      if (!success) {
        state = state.copyWith(state: SyncState.error, errorMessage: 'Drive access not authorized');
        return;
      }
    }
    

    state = state.copyWith(state: SyncState.syncing);

    try {
      // Fetch remote data
      final remoteDataString = await _driveService.downloadData();
      
      final localDataJson = await exportLocalData();

      if (remoteDataString != null && remoteDataString.isNotEmpty) {
        // Here we could implement more complex hashing to check differences,
        // but for now we immediately prompt for conflict resolution if remote exists
        state = state.copyWith(state: SyncState.conflict);
        return; // Wait for user decision
      } else {
        // No remote data, just upload local
        await _driveService.uploadData(localDataJson);
        // Save the last auto-sync timestamp on success
        final settingsBox = Hive.box('settings');
        await settingsBox.put('lastAutoSyncTime', DateTime.now().millisecondsSinceEpoch);
        state = state.copyWith(state: SyncState.success);
      }
    } catch (e) {
      state = state.copyWith(state: SyncState.error, errorMessage: e.toString());
    }
  }

  Future<void> resolveConflict({required bool overwriteLocal}) async {
    state = state.copyWith(state: SyncState.syncing);
    try {
      if (overwriteLocal) {
        // Download and overwrite local DB
        final remoteDataString = await _driveService.downloadData();
        if (remoteDataString != null) {
          await _importLocalData(remoteDataString);
        }
      } else {
        final localDataJson = await exportLocalData();
        await _driveService.uploadData(localDataJson);
      }
      state = state.copyWith(state: SyncState.success);
    } catch (e) {
      state = state.copyWith(state: SyncState.error, errorMessage: e.toString());
    }
  }

  Future<String> exportLocalData() async {
    final categoriesBox = Hive.box<CategoryModel>('categories');
    final expensesBox = Hive.box<ExpenseModel>('expenses');

    final Map<String, dynamic> exportMap = {
      'categories': categoriesBox.values.map((c) => {
        'id': c.id,
        'name': c.name,
        'backgroundColor': c.backgroundColor,
        'textColor': c.textColor,
        'sortOrder': c.sortOrder,
        'type': c.type.index,
      }).toList(),
      'expenses': expensesBox.values.map((e) => {
        'id': e.id,
        'categoryId': e.categoryId,
        'amount': e.amount,
        'note': e.note,
        'date': e.date.toIso8601String(),
        'bankSource': e.bankSource,
      }).toList(),
    };
    return jsonEncode(exportMap);
  }

  Future<void> _importLocalData(String jsonString) async {
    try {
      final Map<String, dynamic> importMap = jsonDecode(jsonString);
      final List<dynamic> categoriesList = importMap['categories'] ?? [];
      final List<dynamic> expensesList = importMap['expenses'] ?? [];
      
      final newCategories = categoriesList.map((cData) {
        return CategoryModel(
          id: cData['id'],
          name: cData['name'],
          backgroundColor: cData['backgroundColor'],
          textColor: cData['textColor'],
          sortOrder: cData['sortOrder'],
          type: CategoryType.values[cData['type']],
        );
      }).toList();

      final newExpenses = expensesList.map((eData) {
        return ExpenseModel(
          id: eData['id'],
          categoryId: eData['categoryId'],
          amount: eData['amount'],
          note: eData['note'],
          date: DateTime.parse(eData['date']),
          bankSource: eData['bankSource'],
        );
      }).toList();

      final categoriesBox = Hive.box<CategoryModel>('categories');
      final expensesBox = Hive.box<ExpenseModel>('expenses');
      
      await categoriesBox.clear();
      await categoriesBox.addAll(newCategories);
      
      await expensesBox.clear();
      await expensesBox.addAll(newExpenses);
      
      // Invalidate the provider so the UI updates with the new data
      ref.invalidate(categoriesProvider);
      ref.invalidate(balanceProvider);
      
    } catch (e) {
      throw Exception("Failed to import remote data: $e");
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncStateData>((ref) {
  return SyncNotifier(ref, GoogleDriveService());
});

final autoSyncProvider = StateNotifierProvider<AutoSyncNotifier, bool>((ref) {
  return AutoSyncNotifier();
});

class AutoSyncNotifier extends StateNotifier<bool> {
  AutoSyncNotifier() : super(false) {
    _loadFromHive();
  }

  void _loadFromHive() {
    final settingsBox = Hive.box('settings');
    state = settingsBox.get('autoSyncEnabled', defaultValue: false) as bool;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final settingsBox = Hive.box('settings');
    await settingsBox.put('autoSyncEnabled', value);
  }
}
