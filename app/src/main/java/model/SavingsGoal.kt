package com.luka.finanzas.model

import com.google.firebase.Timestamp

data class SavingsGoal(
    val id: String = "",
    val title: String = "",
    val targetAmount: Double = 0.0,
    val savedAmount: Double = 0.0,
    val deadline: Timestamp? = null,
    val members: List<String> = emptyList(),
    val inviteCode: String = "",
    val createdBy: String = ""
)