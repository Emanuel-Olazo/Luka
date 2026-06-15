package com.luka.finanzas.ui.budget

import android.animation.ObjectAnimator
import android.graphics.Color
import android.view.LayoutInflater
import android.view.ViewGroup
import android.view.animation.DecelerateInterpolator
import androidx.recyclerview.widget.RecyclerView
import com.luka.finanzas.databinding.ItemBudgetBinding

class BudgetAdapter(
    private var items: List<BudgetItem>
) : RecyclerView.Adapter<BudgetAdapter.ViewHolder>() {

    inner class ViewHolder(val binding: ItemBudgetBinding) :
        RecyclerView.ViewHolder(binding.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemBudgetBinding.inflate(
            LayoutInflater.from(parent.context), parent, false
        )
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val item = items[position]
        holder.binding.apply {
            tvBudgetCategory.text = item.category
            tvBudgetAmounts.text = "S/. %.0f / S/. %.0f".format(item.spent, item.limit)

            val percent = if (item.limit > 0)
                ((item.spent / item.limit) * 100).toInt().coerceAtMost(100)
            else 0

            // Animate progress bar
            ObjectAnimator.ofInt(progressBudget, "progress", 0, percent).apply {
                duration = 800
                interpolator = DecelerateInterpolator()
                start()
            }

            when {
                percent >= 100 -> {
                    progressBudget.progressTintList =
                        android.content.res.ColorStateList.valueOf(Color.parseColor("#F44336"))
                    tvBudgetStatus.text = "¡Límite alcanzado!"
                    tvBudgetStatus.setTextColor(Color.parseColor("#F44336"))
                }
                percent >= 80 -> {
                    progressBudget.progressTintList =
                        android.content.res.ColorStateList.valueOf(Color.parseColor("#FF9800"))
                    tvBudgetStatus.text = "Cerca del límite ($percent%)"
                    tvBudgetStatus.setTextColor(Color.parseColor("#FF9800"))
                }
                else -> {
                    progressBudget.progressTintList =
                        android.content.res.ColorStateList.valueOf(Color.parseColor("#4CAF50"))
                    tvBudgetStatus.text = "Dentro del presupuesto ($percent%)"
                    tvBudgetStatus.setTextColor(Color.parseColor("#4CAF50"))
                }
            }
        }
    }

    override fun getItemCount() = items.size

    fun updateData(newItems: List<BudgetItem>) {
        items = newItems
        notifyDataSetChanged()
    }
}