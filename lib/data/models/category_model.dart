
import 'package:hive/hive.dart';
import 'expense_model.dart';

part 'category_model.g.dart';

@HiveType(typeId: 0)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int backgroundColor;

  @HiveField(3)
  final int textColor;

  @HiveField(4)
  final int sortOrder;

  // Not persisted, populated at runtime
  List<ExpenseModel> expenses = [];

  CategoryModel({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.sortOrder,
    this.expenses = const [],
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    int? backgroundColor,
    int? textColor,
    int? sortOrder,
    List<ExpenseModel>? expenses,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      sortOrder: sortOrder ?? this.sortOrder,
      expenses: expenses ?? this.expenses,
    );
  }
}
