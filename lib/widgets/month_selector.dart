
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.primaryColor,     
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(selectedMonthProvider.notifier).state = DateTime(
                selectedMonth.year,
                selectedMonth.month - 1,
              );
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(selectedMonth),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(selectedMonthProvider.notifier).state = DateTime(
                selectedMonth.year,
                selectedMonth.month + 1,
              );
            },
          ),
        ],
      ),
    );
  }
}
