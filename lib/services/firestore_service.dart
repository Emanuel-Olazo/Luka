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

  Future<void> transferToSavingsGoal(SavingsGoal goal, double amount) async {
    if (uid == null) return;
    
    // Validate available balance before transaction
    final txSnapshot = await _db.collection('transactions').where('uid', isEqualTo: uid).get();
    double balance = 0;
    for (var doc in txSnapshot.docs) {
      final data = doc.data();
      final txAmount = (data['amount'] ?? 0).toDouble();
      if (data['isExpense'] == true) {
        balance -= txAmount;
      } else {
        balance += txAmount;
      }
    }
    
    if (balance < amount) {
      throw 'Saldo insuficiente para realizar este aporte.';
    }

    final goalRef = _db.collection('savings_goals').doc(goal.id);
    final txRef = _db.collection('transactions').doc();
    final contribRef = goalRef.collection('contributions').doc();

    await _db.runTransaction((transaction) async {
      // Leer el documento actual dentro de la transacción
      final goalSnapshot = await transaction.get(goalRef);
      if (!goalSnapshot.exists) throw 'La alcancía ya no existe.';
      
      final goalData = goalSnapshot.data()!;
      final currentSaved = (goalData['savedAmount'] ?? 0).toDouble();
      final target = (goalData['targetAmount'] ?? 0).toDouble();
      
      if (currentSaved + amount > target) {
        final remaining = target - currentSaved;
        if (remaining <= 0) {
          throw 'La meta ya ha sido alcanzada.';
        } else {
          throw 'El aporte supera la meta. Puedes aportar máximo S/. ${remaining.toStringAsFixed(2)}';
        }
      }

      final tx = app_models.Transaction(
        id: txRef.id,
        note: 'Transferencia a ${goal.title}',
        amount: amount,
        date: DateTime.now(),
        category: 'Ahorro',
        isExpense: true,
        uid: uid!,
      );
      
      transaction.set(txRef, tx.toMap());
      
      transaction.set(contribRef, {
        'uid': uid,
        'amount': amount,
        'date': FieldValue.serverTimestamp(),
      });

      transaction.update(goalRef, {
        'savedAmount': currentSaved + amount,
      });
    });
  }

  Future<void> joinSavingsGoal(String inviteCode) async {
    if (uid == null) return;
    
    final querySnapshot = await _db
        .collection('savings_goals')
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw 'Código de invitación no encontrado.';
    }

    final docRef = querySnapshot.docs.first.reference;

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw 'La alcancía ya no existe.';
      
      final data = snapshot.data()!;
      List<String> members = List<String>.from(data['members'] ?? []);
      
      if (members.contains(uid)) {
        throw 'Ya eres miembro de esta alcancía.';
      }
      
      if (members.length >= 4) {
        throw 'Esta alcancía ya ha alcanzado el límite de 4 miembros.';
      }
      
      members.add(uid!);
      
      transaction.update(docRef, {
        'members': members,
        'isShared': true,
      });
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
