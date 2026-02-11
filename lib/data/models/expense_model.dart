
import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 1)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String note;

  @HiveField(4)
  final DateTime date;

  ExpenseModel({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.note,
    required this.date,
  });
}
