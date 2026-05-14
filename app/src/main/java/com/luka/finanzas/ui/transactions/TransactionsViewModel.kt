package com.luka.finanzas.ui.transactions

import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.luka.finanzas.model.Category
import com.luka.finanzas.model.Transaction
import com.luka.finanzas.repository.FirebaseRepository
import kotlinx.coroutines.launch

class TransactionsViewModel : ViewModel() {
    private val repo = FirebaseRepository()

    val transactions = MutableLiveData<List<Transaction>>()
    val categories = MutableLiveData<List<Category>>()
    val isLoading = MutableLiveData<Boolean>()
    val error = MutableLiveData<String>()

    fun loadTransactions() {
        viewModelScope.launch {
            isLoading.postValue(true)
            transactions.postValue(repo.getTransactions())
            isLoading.postValue(false)
        }
    }

    fun loadCategories() {
        viewModelScope.launch {
            categories.postValue(repo.getCategories())
        }
    }

    fun addTransaction(transaction: Transaction, onSuccess: () -> Unit) {
        viewModelScope.launch {
            isLoading.postValue(true)
            val result = repo.addTransaction(transaction)
            if (result.isSuccess) {
                loadTransactions()
                onSuccess()
            } else {
                error.postValue(result.exceptionOrNull()?.message ?: "Error al guardar")
            }
            isLoading.postValue(false)
        }
    }

    fun deleteTransaction(id: String) {
        viewModelScope.launch {
            repo.deleteTransaction(id)
            loadTransactions()
        }
    }
}