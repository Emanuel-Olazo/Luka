package com.luka.finanzas.repository

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.luka.finanzas.model.*
import kotlinx.coroutines.tasks.await
import java.util.UUID

class FirebaseRepository {

    private val auth = FirebaseAuth.getInstance()
    private val db = FirebaseFirestore.getInstance()
    private val uid get() = auth.currentUser?.uid ?: ""

    // ─── AUTH ───────────────────────────────────────────────
    suspend fun register(email: String, password: String, name: String): Result<Unit> {
        return try {
            val result = auth.createUserWithEmailAndPassword(email, password).await()
            val user = mapOf("name" to name, "email" to email, "uid" to result.user!!.uid)
            db.collection("users").document(result.user!!.uid).set(user).await()
            Result.success(Unit)
        } catch (e: Exception) { Result.failure(e) }
    }

    suspend fun login(email: String, password: String): Result<Unit> {
        return try {
            auth.signInWithEmailAndPassword(email, password).await()
            Result.success(Unit)
        } catch (e: Exception) { Result.failure(e) }
    }

    fun logout() = auth.signOut()
    fun isLoggedIn() = auth.currentUser != null

    // ─── TRANSACTIONS ────────────────────────────────────────
    suspend fun addTransaction(transaction: Transaction): Result<Unit> {
        return try {
            val doc = db.collection("transactions").document()
            db.collection("transactions").document(doc.id)
                .set(transaction.copy(id = doc.id, uid = uid)).await()
            Result.success(Unit)
        } catch (e: Exception) { Result.failure(e) }
    }

    suspend fun getTransactions(): List<Transaction> {
        return try {
            db.collection("transactions")
                .whereEqualTo("uid", uid)
                .get().await()
                .toObjects(Transaction::class.java)
                .sortedByDescending { it.date }
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun deleteTransaction(id: String): Result<Unit> {
        return try {
            db.collection("transactions").document(id).delete().await()
            Result.success(Unit)
        } catch (e: Exception) { Result.failure(e) }
    }

    // ─── CATEGORIES ──────────────────────────────────────────
    suspend fun getCategories(): List<Category> {
        return try {
            db.collection("categories")
                .whereEqualTo("uid", uid)
                .get().await()
                .toObjects(Category::class.java)
        } catch (e: Exception) { emptyList() }
    }

    suspend fun addCategory(category: Category): Result<Unit> {
        return try {
            val doc = db.collection("categories").document()
            db.collection("categories").document(doc.id)
                .set(category.copy(id = doc.id, uid = uid)).await()
            Result.success(Unit)
        } catch (e: Exception) { Result.failure(e) }
    }

    suspend fun seedDefaultCategories() {
        val existing = getCategories()
        if (existing.isNotEmpty()) return
        val defaults = listOf(
            Category(name = "Alimentación",   icon = "🍔", color = "#FF5722"),
            Category(name = "Transporte",     icon = "🚌", color = "#2196F3"),
            Category(name = "Entretenimiento",icon = "🎬", color = "#9C27B0"),
            Category(name = "Salud",          icon = "💊", color = "#4CAF50"),
            Category(name = "Educación",      icon = "📚", color = "#FF9800"),
            Category(name = "Ropa",           icon = "👕", color = "#00BCD4"),
            Category(name = "Hogar",          icon = "🏠", color = "#795548"),
            Category(name = "Otros",          icon = "📦", color = "#607D8B")
        )
        defaults.forEach { addCategory(it) }
    }

    // ─── BUDGETS ─────────────────────────────────────────────
    suspend fun setBudget(budget: Budget): Result<Unit> {
        return try {
            // Buscar si ya existe un presupuesto para esa categoría/mes/año
            val existing = db.collection("budgets")
                .whereEqualTo("uid", uid)
                .whereEqualTo("category", budget.category)
                .whereEqualTo("month", budget.month)
                .whereEqualTo("year", budget.year)
                .get().await()

            if (existing.isEmpty) {
                val doc = db.collection("budgets").document()
                db.collection("budgets").document(doc.id)
                    .set(budget.copy(id = doc.id, uid = uid)).await()
            } else {
                existing.documents[0].reference
                    .update("limitAmount", budget.limitAmount).await()
            }
            Result.success(Unit)
        } catch (e: Exception) { Result.failure(e) }
    }

    suspend fun getBudgets(month: Int, year: Int): List<Budget> {
        return try {
            db.collection("budgets")
                .whereEqualTo("uid", uid)
                .whereEqualTo("month", month)
                .whereEqualTo("year", year)
                .get().await()
                .toObjects(Budget::class.java)
        } catch (e: Exception) { emptyList() }
    }

    // ─── SAVINGS GOALS ───────────────────────────────────────
    suspend fun createSavingsGoal(goal: SavingsGoal): Result<String> {
        return try {
            val doc = db.collection("savings_goals").document()
            val inviteCode = UUID.randomUUID().toString().take(8).uppercase()
            val newGoal = goal.copy(
                id = doc.id,
                members = listOf(uid),
                inviteCode = inviteCode,
                createdBy = uid
            )
            db.collection("savings_goals").document(doc.id).set(newGoal).await()
            Result.success(doc.id)
        } catch (e: Exception) { Result.failure(e) }
    }

    suspend fun getSavingsGoals(): List<SavingsGoal> {
        return try {
            db.collection("savings_goals")
                .whereArrayContains("members", uid)
                .get().await()
                .toObjects(SavingsGoal::class.java)
        } catch (e: Exception) { emptyList() }
    }

    suspend fun joinSavingsGoal(inviteCode: String): Result<Unit> {
        return try {
            val snapshot = db.collection("savings_goals")
                .whereEqualTo("inviteCode", inviteCode)
                .get().await()
            if (snapshot.isEmpty) return Result.failure(Exception("Código inválido"))
            val doc = snapshot.documents[0]
            val members = (doc.get("members") as? List<*>)?.toMutableList() ?: mutableListOf()
            if (!members.contains(uid)) {
                members.add(uid)
                doc.reference.update("members", members).await()
            }
            Result.success(Unit)
        } catch (e: Exception) { Result.failure(e) }
    }

    suspend fun addContribution(goalId: String, amount: Double, note: String): Result<Unit> {
        return try {
            // Agregar aporte
            val doc = db.collection("goal_contributions").document()
            val contribution = GoalContribution(
                id = doc.id, goalId = goalId, uid = uid,
                amount = amount, note = note
            )
            db.collection("goal_contributions").document(doc.id).set(contribution).await()

            // Actualizar monto ahorrado en la meta
            val goalRef = db.collection("savings_goals").document(goalId)
            db.runTransaction { transaction ->
                val snapshot = transaction.get(goalRef)
                val current = snapshot.getDouble("savedAmount") ?: 0.0
                transaction.update(goalRef, "savedAmount", current + amount)
            }.await()

            Result.success(Unit)
        } catch (e: Exception) { Result.failure(e) }
    }

    suspend fun getContributions(goalId: String): List<GoalContribution> {
        return try {
            db.collection("goal_contributions")
                .whereEqualTo("goalId", goalId)
                .orderBy("date", Query.Direction.DESCENDING)
                .get().await()
                .toObjects(GoalContribution::class.java)
        } catch (e: Exception) { emptyList() }
    }
}