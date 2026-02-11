
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/models/category_model.dart';
import '../screens/card_detail_screen.dart';
import 'quick_add_dialog.dart';

class ExpenseCard extends StatefulWidget {
  final CategoryModel category;

  const ExpenseCard({super.key, required this.category});

  @override
  State<ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<ExpenseCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Removed unused _scaleAnimation

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.1,
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CardDetailScreen(category: widget.category),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 - _controller.value;
    final total = widget.category.expenses.fold(0.0, (sum, item) => sum + item.amount);
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 0);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Transform.scale(
        scale: scale,
        child: Hero(
          tag: 'card_${widget.category.id}',
          child: Card(
            color: Color(widget.category.backgroundColor),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(right: 32.0),
                    child: Text(
                      widget.category.name,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(widget.category.textColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Body (Recent 3 expenses)
                  ...widget.category.expenses.take(3).map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            e.note.isEmpty ? 'Expense' : e.note,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: Color(widget.category.textColor).withValues(alpha: 0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        ),
                        Text(
                          currencyFormat.format(e.amount),
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(widget.category.textColor),
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (widget.category.expenses.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '+ ${widget.category.expenses.length - 3} more',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Color(widget.category.textColor).withValues(alpha: 0.6),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),
                  // Footer
                  Divider(color: Color(widget.category.textColor).withValues(alpha: 0.2)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(widget.category.textColor),
                        ),
                      ),
                      Text(
                        currencyFormat.format(total),
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(widget.category.textColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(Icons.add, color: Color(widget.category.textColor)),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: QuickAddDialog(category: widget.category)
                    ),
                  );
                },
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}
