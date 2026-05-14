package com.luka.finanzas.ui.dashboard

import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.luka.finanzas.repository.FirebaseRepository
import kotlinx.coroutines.launch

class DashboardViewModel : ViewModel() {
    private val repo = FirebaseRepository()

    val totalIncome = MutableLiveData<Double>()
    val totalExpense = MutableLiveData<Double>()
    val balance = MutableLiveData<Double>()
    val categoryExpenses = MutableLiveData<Map<String, Double>>()

    fun loadDashboard(month: Int, year: Int) {
        viewModelScope.launch {
            val transactions = repo.getTransactions()
            // Filtrar por mes/año actual
            val cal = java.util.Calendar.getInstance()
            val filtered = transactions.filter {
                val date = it.date.toDate()
                cal.time = date
                cal.get(java.util.Calendar.MONTH) + 1 == month &&
                        cal.get(java.util.Calendar.YEAR) == year
            }

            val income = filtered.filter { it.type == "income" }.sumOf { it.amount }
            val expense = filtered.filter { it.type == "expense" }.sumOf { it.amount }

            totalIncome.postValue(income)
            totalExpense.postValue(expense)
            balance.postValue(income - expense)

            // Agrupar gastos por categoría
            val byCategory = filtered
                .filter { it.type == "expense" }
                .groupBy { it.category }
                .mapValues { entry -> entry.value.sumOf { it.amount } }
            categoryExpenses.postValue(byCategory)
        }
    }
}