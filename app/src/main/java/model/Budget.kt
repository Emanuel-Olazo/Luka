package com.luka.finanzas.model

data class Budget(
    val id: String = "",
    val uid: String = "",
    val category: String = "",
    val limitAmount: Double = 0.0,
    val month: Int = 0,
    val year: Int = 0
)