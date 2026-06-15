package com.luka.finanzas.ui.savings

import android.animation.ObjectAnimator
import android.view.LayoutInflater
import android.view.ViewGroup
import android.view.animation.DecelerateInterpolator
import androidx.recyclerview.widget.RecyclerView
import com.luka.finanzas.databinding.ItemSavingsGoalBinding
import com.luka.finanzas.model.SavingsGoal
import java.text.NumberFormat
import java.util.Locale

class SavingsGoalAdapter(
    private val onAddFundsClick: (SavingsGoal) -> Unit
) : RecyclerView.Adapter<SavingsGoalAdapter.SavingsGoalViewHolder>() {

    private var goals: List<SavingsGoal> = emptyList()

    fun submitList(newGoals: List<SavingsGoal>) {
        goals = newGoals
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): SavingsGoalViewHolder {
        val binding = ItemSavingsGoalBinding.inflate(
            LayoutInflater.from(parent.context), parent, false
        )
        return SavingsGoalViewHolder(binding)
    }

    override fun onBindViewHolder(holder: SavingsGoalViewHolder, position: Int) {
        holder.bind(goals[position])
    }

    override fun getItemCount(): Int = goals.size

    inner class SavingsGoalViewHolder(private val binding: ItemSavingsGoalBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(goal: SavingsGoal) {
            binding.tvTitle.text = goal.title
            binding.tvInviteCode.text = "Código de invitación: ${goal.inviteCode}"
            
            val format = NumberFormat.getCurrencyInstance(Locale("es", "PE"))
            val savedFormatted = format.format(goal.savedAmount)
            val targetFormatted = format.format(goal.targetAmount)
            
            binding.tvProgress.text = "$savedFormatted / $targetFormatted"
            
            val progressPercentage = if (goal.targetAmount > 0) {
                ((goal.savedAmount / goal.targetAmount) * 100).toInt()
            } else 0
            
            // Animate progress bar
            ObjectAnimator.ofInt(binding.progressBar, "progress", 0, progressPercentage).apply {
                duration = 800
                interpolator = DecelerateInterpolator()
                start()
            }
            
            binding.btnAddFunds.setOnClickListener {
                onAddFundsClick(goal)
            }
        }
    }
}
