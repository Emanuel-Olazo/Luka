package com.luka.finanzas.model

import com.google.firebase.Timestamp

data class Transaction(
    val id: String = "",
    val uid: String = "",
    val type: String = "expense", // "income" o "expense"
    val amount: Double = 0.0,
    val category: String = "",
    val note: String = "",
    val date: Timestamp = Timestamp.now()
)