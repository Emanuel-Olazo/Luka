class Budget {
  final String id;
  final String categoryId;
  final double amount;
  final double spentAmount;
  final int month;
  final int year;

  Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    this.spentAmount = 0.0,
    required this.month,
    required this.year,
  });

  double get remaining => amount - spentAmount;
  double get progress => amount > 0 ? spentAmount / amount : 0;
}
