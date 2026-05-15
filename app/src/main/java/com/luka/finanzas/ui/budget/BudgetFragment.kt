package com.luka.finanzas.ui.budget

import android.os.Bundle
import android.view.*
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.recyclerview.widget.LinearLayoutManager
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
            binding.etBudgetCategory.text?.clear()
            binding.etBudgetLimit.text?.clear()
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