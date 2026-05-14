package com.luka.finanzas.utils

import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.*

fun Double.toSoles(): String {
    return "S/. %.2f".format(this)
}

fun Date.toFormattedString(): String {
    val sdf = SimpleDateFormat("dd/MM/yyyy", Locale.getDefault())
    return sdf.format(this)
}

fun Date.toMonthYear(): String {
    val sdf = SimpleDateFormat("MMMM yyyy", Locale("es"))
    return sdf.format(this)
}