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

  Stream<List<Category>> getCategories() {
    if (uid == null) return Stream.value([]);
    return _db
        .collection('categories')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromFirestore(doc))
            .toList());
  }

  Future<void> ensureDefaultCategories() async {
    if (uid == null) return;
    final snapshot = await _db.collection('categories').where('uid', isEqualTo: uid).limit(1).get();
    if (snapshot.docs.isEmpty) {
      final defaults = ['Comida', 'Transporte', 'Servicios', 'Entretenimiento', 'Sueldo', 'Otros', 'Salud', 'Educación'];
      final batch = _db.batch();
      for (var catName in defaults) {
        final docRef = _db.collection('categories').doc();
        batch.set(docRef, {
          'name': catName,
          'icon': 'category',
          'color': '#000000',
          'uid': uid,
        });
      }
      await batch.commit();
    }
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

  // --- Transfers ---
  Future<void> transferToSavingsGoal(SavingsGoal goal, double amount) async {
    if (uid == null) return;
    
    // 1. Create a negative transaction
    final tx = app_models.Transaction(
      id: '',
      note: 'Transferencia a ${goal.title}',
      amount: amount,
      date: DateTime.now(),
      category: 'Ahorro',
      isExpense: true,
      uid: uid!,
    );
    await addTransaction(tx);

    // 2. Update the savings goal
    await _db.collection('savings_goals').doc(goal.id).update({
      'savedAmount': FieldValue.increment(amount),
    });
  }

  // --- CRUD Categories ---
  Future<void> addCategory(Category category) async {
    await _db.collection('categories').add(category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }
}
