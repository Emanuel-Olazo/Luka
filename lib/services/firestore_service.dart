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

  // --- CRUD Transactions ---
  Future<void> addTransaction(app_models.Transaction tx) async {
    await _db.collection('transactions').add(tx.toMap());
  }

  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    await _db.collection('transactions').doc(id).update(data);
  }

  Future<void> deleteTransaction(String id) async {
    await _db.collection('transactions').doc(id).delete();
  }

  // --- CRUD Budgets ---
  Future<void> addBudget(Budget budget) async {
    await _db.collection('budgets').add(budget.toMap());
  }

  Future<void> updateBudget(String id, Map<String, dynamic> data) async {
    await _db.collection('budgets').doc(id).update(data);
  }

  Future<void> deleteBudget(String id) async {
    await _db.collection('budgets').doc(id).delete();
  }

  // --- CRUD Savings Goals ---
  Future<void> addSavingsGoal(SavingsGoal goal) async {
    await _db.collection('savings_goals').add(goal.toMap());
  }

  Future<void> updateSavingsGoal(String id, Map<String, dynamic> data) async {
    await _db.collection('savings_goals').doc(id).update(data);
  }

  Future<void> deleteSavingsGoal(String id) async {
    await _db.collection('savings_goals').doc(id).delete();
  }
}
