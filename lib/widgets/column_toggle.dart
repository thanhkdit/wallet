import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';

class ColumnToggle extends ConsumerWidget {
  const ColumnToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCount = ref.watch(columnCountProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final count = index + 1;
        final isSelected = count == currentCount;
        return GestureDetector(
          onTap: () => ref.read(columnCountProvider.notifier).state = count,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Text(
              '$count',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textColor.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ),
        );
      }),
    );
  }
}
