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
    final rangeFormat = DateFormat('dd/MM');

    String getHeaderText() {
      switch (filterState.mode) {
        case DateFilterMode.month:
          return dateFormat.format(filterState.selectedDate);
        case DateFilterMode.year:
          return 'Năm ${yearFormat.format(filterState.selectedDate)}';
        case DateFilterMode.custom:
          if (filterState.customRange != null) {
            final start = filterState.customRange!.start;
            final end = filterState.customRange!.end;
            return '${rangeFormat.format(start)} - ${rangeFormat.format(end)}';
          }
          return 'Chọn khoảng thời gian';
      }
    }

    Widget _buildFilterOption({
      required IconData icon,
      required String title,
      required String subtitle,
      required bool isSelected,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.secretGrey.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.secretGrey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isSelected ? Colors.white : AppTheme.secretGrey, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.secretGrey),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor),
            ],
          ),
        ),
      );
    }

    void showFilterOptions() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.secretGrey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Chế độ hiển thị',
                  style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 24),
                _buildFilterOption(
                  icon: Icons.calendar_month_rounded,
                  title: 'Xem theo tháng',
                  subtitle: 'Hiển thị dữ liệu trong 1 tháng cụ thể',
                  isSelected: filterState.mode == DateFilterMode.month,
                  onTap: () {
                    ref.read(dateFilterProvider.notifier).update((state) => state.copyWith(mode: DateFilterMode.month));
                    Navigator.pop(context);
                  },
                ),
                _buildFilterOption(
                  icon: Icons.calendar_today_rounded,
                  title: 'Xem theo năm',
                  subtitle: 'Tổng hợp dữ liệu của cả năm',
                  isSelected: filterState.mode == DateFilterMode.year,
                  onTap: () {
                    Navigator.pop(context);

                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        return Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                               const SizedBox(height: 12),

                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Chọn năm",
                                      style: GoogleFonts.nunito(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(
                                height: 250,
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppTheme.primaryColor,
                                      onPrimary: Colors.white,
                                      surface: Colors.transparent,
                                      onSurface: AppTheme.textColor,
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  child: YearPicker(
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                    selectedDate: filterState.selectedDate,
                                    onChanged: (dateTime) {
                                      ref.read(dateFilterProvider.notifier).update((state) => state.copyWith(
                                        mode: DateFilterMode.year,
                                        selectedDate: dateTime,
                                      ));
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                _buildFilterOption(
                  icon: Icons.date_range_rounded,
                  title: 'Khoảng thời gian tự chọn',
                  subtitle: 'Tùy chỉnh ngày bắt đầu và kết thúc',
                  isSelected: filterState.mode == DateFilterMode.custom,
                  onTap: () {
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (filterState.mode == DateFilterMode.month)
          _buildNavButton(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              ref.read(dateFilterProvider.notifier).update((state) {
                return state.copyWith(selectedDate: DateTime(state.selectedDate.year, state.selectedDate.month - 1));
              });
            },
          ),

        const SizedBox(width: 8),

        GestureDetector(
          onTap: showFilterOptions,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filterState.mode == DateFilterMode.month
                      ? Icons.calendar_month_rounded
                      : filterState.mode == DateFilterMode.year
                      ? Icons.calendar_today_rounded
                      : Icons.date_range_rounded,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 10),
                Text(
                  getHeaderText(),
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppTheme.secretGrey),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        if (filterState.mode == DateFilterMode.month)
          _buildNavButton(
            icon: Icons.chevron_right_rounded,
            onTap: () {
              ref.read(dateFilterProvider.notifier).update((state) {
                return state.copyWith(selectedDate: DateTime(state.selectedDate.year, state.selectedDate.month + 1));
              });
            },
          ),
      ],
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.secretGrey.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: AppTheme.textColor, size: 22),
      ),
    );
  }
}