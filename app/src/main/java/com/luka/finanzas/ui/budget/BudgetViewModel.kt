package com.luka.finanzas.ui.budget

import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.luka.finanzas.model.Budget
import com.luka.finanzas.model.Category
import com.luka.finanzas.model.Transaction
import com.luka.finanzas.repository.FirebaseRepository
import kotlinx.coroutines.launch
import java.util.Calendar

data class BudgetItem(
    val category: String,
    val limit: Double,
    val spent: Double
)

class BudgetViewModel : ViewModel() {
    private val repo = FirebaseRepository()

    val budgetItems = MutableLiveData<List<BudgetItem>>()
    val categories = MutableLiveData<List<Category>>()
    val isLoading = MutableLiveData<Boolean>()
    val error = MutableLiveData<String>()

    fun loadBudgets() {
        viewModelScope.launch {
            isLoading.postValue(true)
            val cal = Calendar.getInstance()
            val month = cal.get(Calendar.MONTH) + 1
            val year = cal.get(Calendar.YEAR)

            val budgets = repo.getBudgets(month, year)
            val transactions = repo.getTransactions()

            // Filtrar gastos del mes actual
            val monthlyExpenses = transactions.filter {
                it.type == "expense" &&
                        cal.apply { time = it.date.toDate() }.get(Calendar.MONTH) + 1 == month &&
                        cal.get(Calendar.YEAR) == year
            }

            // Cruzar presupuesto con gastos reales
            val items = budgets.map { budget ->
                val spent = monthlyExpenses
                    .filter { it.category == budget.category }
                    .sumOf { it.amount }
                BudgetItem(budget.category, budget.limitAmount, spent)
            }

            budgetItems.postValue(items)
            categories.postValue(repo.getCategories())
            isLoading.postValue(false)
        }
    }

    fun saveBudget(category: String, limit: Double) {
        viewModelScope.launch {
            val cal = Calendar.getInstance()
            val budget = Budget(
                category = category,
                limitAmount = limit,
                month = cal.get(Calendar.MONTH) + 1,
                year = cal.get(Calendar.YEAR)
            )
            val result = repo.setBudget(budget)
            if (result.isSuccess) {
                loadBudgets()
            } else {
                error.postValue(result.exceptionOrNull()?.message ?: "Error al guardar")
            }
        }
    }
}