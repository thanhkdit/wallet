import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncProvider = StateNotifierProvider<SyncNotifier, bool>((ref) => SyncNotifier());

class SyncNotifier extends StateNotifier<bool> {
  SyncNotifier() : super(false);
  void setSyncing(bool val) => state = val;
}
