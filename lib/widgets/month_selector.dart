
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import 'custom_date_range_picker.dart';

class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(dateFilterProvider);
    final dateFormat = DateFormat('MMMM yyyy');
    final yearFormat = DateFormat('yyyy');
    final rangeFormat = DateFormat('MMM d');

    String getHeaderText() {
      switch (filterState.mode) {
        case DateFilterMode.month:
          return dateFormat.format(filterState.selectedDate);
        case DateFilterMode.year:
          return 'Year ${yearFormat.format(filterState.selectedDate)}';
        case DateFilterMode.custom:
          if (filterState.customRange != null) {
            final start = filterState.customRange!.start;
            final end = filterState.customRange!.end;
            return '${rangeFormat.format(start)} - ${rangeFormat.format(end)}';
          }
          return 'Select Range';
      }
    }

    void showFilterOptions() {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                  title: const Text('Specific Month'),
                  onTap: () async {
                    Navigator.pop(context);
                    // Show Year-Month picker (using showDatePicker with day=1?)
                    // Or simpler: stick to current MonthSelector arrows, but here we just set mode
                    ref.read(dateFilterProvider.notifier).update((state) => state.copyWith(mode: DateFilterMode.month));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  title: const Text('Specific Year'),
                  onTap: () async {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Select Year"),
                          content: SizedBox( // Need to size the dialog for year picker
                            width: 300,
                            height: 300,
                            child: YearPicker(
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              selectedDate: filterState.selectedDate,
                              onChanged: (DateTime dateTime) {
                                ref.read(dateFilterProvider.notifier).update((state) => state.copyWith(
                                  mode: DateFilterMode.year,
                                  selectedDate: dateTime,
                                ));
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.date_range, color: AppTheme.primaryColor),
                  title: const Text('Custom Range'),
                  onTap: () { // Removed async as showModalBottomSheet is voidish here or we handle it in onApply
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CustomDateRangePicker(
                        initialRange: filterState.customRange,
                        onApply: (range) {
                          ref.read(dateFilterProvider.notifier).update((state) => state.copyWith(
                            mode: DateFilterMode.custom,
                            customRange: range,
                          ));
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTap: showFilterOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (filterState.mode == DateFilterMode.month)
             IconButton(
                icon: const Icon(Icons.chevron_left, color: AppTheme.textColor),
                onPressed: () {
                  ref.read(dateFilterProvider.notifier).update((state) {
                    final newDate = DateTime(state.selectedDate.year, state.selectedDate.month - 1);
                    return state.copyWith(selectedDate: newDate);
                  });
                },
              ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Text(
                    getHeaderText(),
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: AppTheme.textColor),
                ],
              ),
            ),

            if (filterState.mode == DateFilterMode.month)
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppTheme.textColor),
                onPressed: () {
                  ref.read(dateFilterProvider.notifier).update((state) {
                    final newDate = DateTime(state.selectedDate.year, state.selectedDate.month + 1);
                    return state.copyWith(selectedDate: newDate);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}
