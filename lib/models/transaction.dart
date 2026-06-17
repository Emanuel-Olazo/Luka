import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String id;
  final String note;
  final double amount;
  final DateTime date;
  final String category;
  final bool isExpense;
  final String uid;

  Transaction({
    required this.id,
    required this.note,
    required this.amount,
    required this.date,
    required this.category,
    this.isExpense = true,
    required this.uid,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      note: data['note'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] ?? '',
      isExpense: data['type'] == 'expense',
      uid: data['uid'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'note': note,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'type': isExpense ? 'expense' : 'income',
      'uid': uid,
    };
  }
}
