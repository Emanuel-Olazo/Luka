package com.luka.finanzas.ui.savings

import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.luka.finanzas.model.SavingsGoal
import com.luka.finanzas.repository.FirebaseRepository
import kotlinx.coroutines.launch

class SavingsViewModel : ViewModel() {
    private val repo = FirebaseRepository()

    val goals = MutableLiveData<List<SavingsGoal>>()
    val isLoading = MutableLiveData<Boolean>()
    val error = MutableLiveData<String>()
    val success = MutableLiveData<String>()

    fun loadGoals() {
        viewModelScope.launch {
            isLoading.postValue(true)
            goals.postValue(repo.getSavingsGoals())
            isLoading.postValue(false)
        }
    }

    fun createGoal(goal: SavingsGoal) {
        viewModelScope.launch {
            isLoading.postValue(true)
            val result = repo.createSavingsGoal(goal)
            if (result.isSuccess) {
                success.postValue("Alcancía creada")
                loadGoals()
            } else {
                error.postValue(result.exceptionOrNull()?.message ?: "Error al crear")
            }
            isLoading.postValue(false)
        }
    }

    fun joinGoal(inviteCode: String) {
        viewModelScope.launch {
            isLoading.postValue(true)
            val result = repo.joinSavingsGoal(inviteCode)
            if (result.isSuccess) {
                success.postValue("¡Te uniste a la alcancía!")
                loadGoals()
            } else {
                error.postValue(result.exceptionOrNull()?.message ?: "Código inválido")
            }
            isLoading.postValue(false)
        }
    }

    fun addContribution(goalId: String, amount: Double, note: String) {
        viewModelScope.launch {
            isLoading.postValue(true)
            val result = repo.addContribution(goalId, amount, note)
            if (result.isSuccess) {
                success.postValue("Aporte registrado")
                loadGoals()
            } else {
                error.postValue(result.exceptionOrNull()?.message ?: "Error al aportar")
            }
            isLoading.postValue(false)
        }
    }
}