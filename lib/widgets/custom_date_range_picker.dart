import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class CustomDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  final ValueChanged<DateTimeRange> onApply;

  const CustomDateRangePicker({
    super.key,
    this.initialRange,
    required this.onApply,
  });

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSelectingStart = true;

  final List<Map<String, dynamic>> _presets = [
    {'label': 'This Month', 'type': 'month'},
    {'label': 'Last Month', 'type': 'last_month'},
    {'label': 'This Year', 'type': 'year'},
    {'label': 'Last Year', 'type': 'last_year'},
  ];

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to this month start if null
    _startDate = widget.initialRange?.start ?? DateTime(now.year, now.month);
    // Default to this month end if null, ensuring we capture the full day? 
    // Actually internal state track as Month/Year (1st of month)
    // When applying we convert to full range.
    _endDate = widget.initialRange?.end ?? DateTime(now.year, now.month);
  }

  void _applyPreset(Map<String, dynamic> preset) {
    final now = DateTime.now();
    setState(() {
      if (preset['type'] == 'month') {
        _startDate = DateTime(now.year, now.month);
        _endDate = DateTime(now.year, now.month);
      } else if (preset['type'] == 'last_month') {
        final lastMonth = DateTime(now.year, now.month - 1);
        _startDate = lastMonth;
        _endDate = lastMonth;
      } else if (preset['type'] == 'year') {
        _startDate = DateTime(now.year, 1);
        _endDate = DateTime(now.year, 12);
      } else if (preset['type'] == 'last_year') {
        _startDate = DateTime(now.year - 1, 1);
        _endDate = DateTime(now.year - 1, 12);
      }
    });
  }

  // Helper to ensure we pick first day of month for internal state
  void _updateDate(int year, int month) {
    final newDate = DateTime(year, month);
    setState(() {
      if (_isSelectingStart) {
        _startDate = newDate;
        // Independent: Do not auto-adjust end date
      } else {
        _endDate = newDate;
        // Independent: Do not auto-adjust start date
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayFormat = DateFormat('MMMM yyyy');

    // Determine current selection based on toggle
    final currentSelection = _isSelectingStart ? _startDate : _endDate;

    return Container(
      height: 500,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Title
          Text(
            'Select Month Range',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),

          const SizedBox(height: 16),

          // Presets
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = _presets[index];
                return ActionChip(
                  label: Text(preset['label']),
                  labelStyle: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _applyPreset(preset),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Start/End Toggles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildDateToggle(
                    title: 'From Month',
                    date: _startDate,
                    isActive: _isSelectingStart,
                    onTap: () => setState(() => _isSelectingStart = true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateToggle(
                    title: 'To Month',
                    date: _endDate,
                    isActive: !_isSelectingStart,
                    onTap: () => setState(() => _isSelectingStart = false),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Custom Wheel Picker (Month | Year)
          Expanded(
            child: Row(
              children: [
                // Month Picker
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: currentSelection.month - 1,
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      _updateDate(currentSelection.year, index + 1);
                    },
                    children: _months.map((m) => Center(
                      child: Text(
                        m, 
                        style: GoogleFonts.nunito(fontSize: 18, color: AppTheme.textColor),
                      ),
                    )).toList(),
                  ),
                ),
                // Year Picker
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: currentSelection.year - 2000, // Assuming 2000 start
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      _updateDate(2000 + index, currentSelection.month);
                    },
                    children: List.generate(50, (index) => Center(
                      child: Text(
                        '${2000 + index}',
                         style: GoogleFonts.nunito(fontSize: 18, color: AppTheme.textColor),
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ),

          // Footer Action
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    // Logic:
                    // Start is 1st of Start Month (00:00:00)
                    // End is Last Day of End Month (23:59:59)
                    final start = DateTime(_startDate.year, _startDate.month, 1);
                    final end = DateTime(_endDate.year, _endDate.month + 1, 0, 23, 59, 59);
                    
                    widget.onApply(DateTimeRange(start: start, end: end));
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Apply Filter (${displayFormat.format(_startDate)} - ${displayFormat.format(_endDate)})',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateToggle({
    required String title,
    required DateTime date,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('MMMM yyyy');
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.2),
            width: isActive ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppTheme.secretGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(date),
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
