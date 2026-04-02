import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../data/models/category_model.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

class AddCategorySheet extends ConsumerStatefulWidget {
  final CategoryType type;
  const AddCategorySheet({super.key, required this.type});

  @override
  ConsumerState<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<AddCategorySheet> {
  late TextEditingController _controller;
  late Color selectedBaseColor;
  late Color selectedColor;
  late Color textColor;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    selectedBaseColor = AppTheme.baseColors[0];
    selectedColor = AppTheme.getShades(selectedBaseColor)[4];
    textColor = AppTheme.getContrastTextColor(selectedColor);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      final newCategory = CategoryModel(
        id: const Uuid().v4(),
        name: name,
        backgroundColor: selectedColor.toARGB32(),
        textColor: textColor.toARGB32(),
        sortOrder: 999,
        type: widget.type,
      );
      ref.read(categoriesProvider(widget.type).notifier).addCategory(newCategory);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 12, left: 24, right: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.secretGrey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              widget.type == CategoryType.income ? 'Nguồn thu mới' : 'Danh mục chi tiêu',
              style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: selectedColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
                ],
              ),
              child: Text(
                _controller.text.isEmpty ? 'Tên danh mục' : _controller.text,
                style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (val) => setState(() {}),
              onSubmitted: (_) => _handleSave(),
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Ví dụ: Ăn uống, Di chuyển...',
                filled: true,
                fillColor: AppTheme.secretGrey.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: AppTheme.baseColors.map((baseColor) {
                  final isBaseSelected = AppTheme.isSameBaseColor(selectedBaseColor, baseColor);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedBaseColor = baseColor;
                        selectedColor = AppTheme.getShades(baseColor)[4];
                        textColor = AppTheme.getContrastTextColor(selectedColor);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40, margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: baseColor, shape: BoxShape.circle,
                        border: isBaseSelected ? Border.all(color: AppTheme.textColor, width: 3) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
              children: AppTheme.getShades(selectedBaseColor).map((shadeColor) {
                final isSelected = selectedColor.toARGB32() == shadeColor.toARGB32();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = shadeColor;
                      textColor = AppTheme.getContrastTextColor(selectedColor);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: shadeColor, shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: AppTheme.textColor, width: 2.5) : null,
                    ),
                    child: isSelected ? Icon(Icons.check, size: 18, color: textColor) : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _handleSave,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Tạo danh mục ngay', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}