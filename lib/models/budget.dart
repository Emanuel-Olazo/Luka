import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final String category;
  final double limitAmount;
  double spentAmount; // Mutable for calculation
  final int month;
  final int year;
  final String uid;

  Budget({
    required this.id,
    required this.category,
    required this.limitAmount,
    this.spentAmount = 0.0,
    required this.month,
    required this.year,
    required this.uid,
  });

  double get remaining => limitAmount - spentAmount;
  double get progress => limitAmount > 0 ? spentAmount / limitAmount : 0;

  factory Budget.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Budget(
      id: doc.id,
      category: data['category'] ?? '',
      limitAmount: (data['limitAmount'] ?? 0.0).toDouble(),
      spentAmount: 0.0, // Will be calculated later
      month: data['month'] ?? 1,
      year: data['year'] ?? 2024,
      uid: data['uid'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'limitAmount': limitAmount,
      'month': month,
      'year': year,
      'uid': uid,
    };
  }
}
