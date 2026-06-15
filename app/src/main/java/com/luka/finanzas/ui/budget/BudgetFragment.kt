package com.luka.finanzas.ui.budget

import android.os.Bundle
import android.view.*
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.recyclerview.widget.LinearLayoutManager
import com.google.android.material.chip.Chip
import com.luka.finanzas.databinding.FragmentBudgetBinding

class BudgetFragment : Fragment() {

    private var _binding: FragmentBudgetBinding? = null
    private val binding get() = _binding!!
    private val viewModel: BudgetViewModel by viewModels()
    private lateinit var adapter: BudgetAdapter

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?,
                              savedInstanceState: Bundle?): View {
        _binding = FragmentBudgetBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        adapter = BudgetAdapter(emptyList())
        binding.rvBudgets.layoutManager = LinearLayoutManager(requireContext())
        binding.rvBudgets.adapter = adapter

        // Setup Chips
        binding.chipGroupCategories.setOnCheckedStateChangeListener { group, checkedIds ->
            if (checkedIds.isNotEmpty()) {
                val chip = group.findViewById<Chip>(checkedIds.first())
                binding.etBudgetCategory.setText(chip.text)
            }
        }

        binding.btnSaveBudget.setOnClickListener {
            val category = binding.etBudgetCategory.text.toString().trim()
            val limitStr = binding.etBudgetLimit.text.toString()

            if (category.isEmpty() || limitStr.isEmpty()) {
                Toast.makeText(requireContext(), "Completa todos los campos",
                    Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val limit = limitStr.toDoubleOrNull()
            if (limit == null || limit <= 0) {
                Toast.makeText(requireContext(), "Límite inválido",
                    Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            viewModel.saveBudget(category, limit)
            
            // Add as new chip if it doesn't exist
            var exists = false
            for (i in 0 until binding.chipGroupCategories.childCount) {
                val chip = binding.chipGroupCategories.getChildAt(i) as Chip
                if (chip.text.toString().equals(category, ignoreCase = true)) {
                    exists = true
                    break
                }
            }
            if (!exists) {
                val newChip = Chip(requireContext()).apply {
                    text = category
                    isCheckable = true
                    isCloseIconVisible = true
                    setOnCloseIconClickListener {
                        binding.chipGroupCategories.removeView(this)
                    }
                }
                binding.chipGroupCategories.addView(newChip)
            }
            
            binding.etBudgetCategory.text?.clear()
            binding.etBudgetLimit.text?.clear()
            binding.chipGroupCategories.clearCheck()
        }

        viewModel.budgetItems.observe(viewLifecycleOwner) { items ->
            adapter.updateData(items)
        }

        viewModel.error.observe(viewLifecycleOwner) {
            Toast.makeText(requireContext(), it, Toast.LENGTH_SHORT).show()
        }
    }

    override fun onResume() {
        super.onResume()
        viewModel.loadBudgets()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}