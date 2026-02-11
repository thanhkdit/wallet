
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class ColumnToggle extends ConsumerWidget {
  const ColumnToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCount = ref.watch(columnCountProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Columns: '),
          ...List.generate(4, (index) {
            final count = index + 1;
            final isSelected = count == currentCount;
            return GestureDetector(
              onTap: () => ref.read(columnCountProvider.notifier).state = count,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                  border: isSelected ? null : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).colorScheme.onSecondary : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
