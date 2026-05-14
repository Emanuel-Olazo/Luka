package com.luka.finanzas.model

import com.google.firebase.Timestamp

data class GoalContribution(
    val id: String = "",
    val goalId: String = "",
    val uid: String = "",
    val amount: Double = 0.0,
    val note: String = "",
    val date: Timestamp = Timestamp.now()
)