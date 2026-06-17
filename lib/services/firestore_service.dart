import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart' as app_models;
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/category.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  Stream<List<app_models.Transaction>> getTransactions() {
    if (uid == null) return Stream.value([]);
    return _db
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final txs = snapshot.docs
              .map((doc) => app_models.Transaction.fromFirestore(doc))
              .toList();
          txs.sort((a, b) => b.date.compareTo(a.date));
          return txs;
        });
  }

  Stream<List<Budget>> getBudgets() {
    if (uid == null) return Stream.value([]);
    return _db
        .collection('budgets')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Budget.fromFirestore(doc))
            .toList());
  }

  Stream<List<SavingsGoal>> getSavingsGoals() {
    if (uid == null) return Stream.value([]);
    return _db
        .collection('savings_goals')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavingsGoal.fromFirestore(doc))
            .toList());
  }
}
