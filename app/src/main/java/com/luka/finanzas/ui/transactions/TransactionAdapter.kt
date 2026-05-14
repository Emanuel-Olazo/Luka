package com.luka.finanzas.ui.transactions

import android.graphics.Color
import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.luka.finanzas.databinding.ItemTransactionBinding
import com.luka.finanzas.model.Transaction
import java.text.SimpleDateFormat
import java.util.Locale

class TransactionAdapter(
    private var items: List<Transaction>,
    private val onLongClick: (Transaction) -> Unit = {}
) : RecyclerView.Adapter<TransactionAdapter.ViewHolder>() {

    inner class ViewHolder(val binding: ItemTransactionBinding) :
        RecyclerView.ViewHolder(binding.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemTransactionBinding.inflate(
            LayoutInflater.from(parent.context), parent, false
        )
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val tx = items[position]
        val sdf = SimpleDateFormat("dd/MM/yyyy", Locale.getDefault())

        holder.binding.apply {
            tvCategory.text = tx.category
            tvNote.text = if (tx.note.isEmpty()) "Sin nota" else tx.note
            tvDate.text = sdf.format(tx.date.toDate())

            if (tx.type == "income") {
                tvAmount.text = "+S/. %.2f".format(tx.amount)
                tvAmount.setTextColor(Color.parseColor("#4CAF50"))
                tvIcon.text = "💵"
            } else {
                tvAmount.text = "-S/. %.2f".format(tx.amount)
                tvAmount.setTextColor(Color.parseColor("#F44336"))
                tvIcon.text = "💸"
            }

            root.setOnLongClickListener {
                onLongClick(tx)
                true
            }
        }
    }

    override fun getItemCount() = items.size

    fun updateData(newItems: List<Transaction>) {
        items = newItems
        notifyDataSetChanged()
    }
}