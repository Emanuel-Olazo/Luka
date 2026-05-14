package com.luka.finanzas.ui.dashboard

import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.luka.finanzas.model.Transaction
import com.luka.finanzas.repository.FirebaseRepository
import kotlinx.coroutines.launch
import java.util.Calendar

class DashboardViewModel : ViewModel() {
    private val repo = FirebaseRepository()

    val totalIncome = MutableLiveData<Double>()
    val totalExpense = MutableLiveData<Double>()
    val balance = MutableLiveData<Double>()
    val categoryExpenses = MutableLiveData<Map<String, Double>>()
    val recentTransactions = MutableLiveData<List<Transaction>>()

    fun loadDashboard(month: Int, year: Int) {
        viewModelScope.launch {
            val transactions = repo.getTransactions()

            val filtered = transactions.filter {
                val cal = Calendar.getInstance()
                cal.time = it.date.toDate()
                val txMonth = cal.get(Calendar.MONTH) + 1
                val txYear = cal.get(Calendar.YEAR)
                txMonth == month && txYear == year
            }

            val income = filtered.filter { it.type == "income" }.sumOf { it.amount }
            val expense = filtered.filter { it.type == "expense" }.sumOf { it.amount }

            totalIncome.postValue(income)
            totalExpense.postValue(expense)
            balance.postValue(income - expense)

            val byCategory = filtered
                .filter { it.type == "expense" }
                .groupBy { it.category }
                .mapValues { entry -> entry.value.sumOf { it.amount } }

            categoryExpenses.postValue(byCategory)
            recentTransactions.postValue(filtered.take(5))
        }
    }
}