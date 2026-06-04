package com.luka.finanzas.ui.savings

import android.os.Bundle
import android.view.*
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.appcompat.app.AlertDialog
import com.luka.finanzas.R
import com.luka.finanzas.databinding.FragmentSavingsBinding

class SavingsFragment : Fragment() {

    private var _binding: FragmentSavingsBinding? = null
    private val binding get() = _binding!!
    private val viewModel: SavingsViewModel by viewModels()

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?,
                              savedInstanceState: Bundle?): View {
        _binding = FragmentSavingsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.rvGoals.layoutManager = LinearLayoutManager(requireContext())

        binding.btnJoin.setOnClickListener {
            val code = binding.etInviteCode.text.toString().trim()
            if (code.isEmpty()) {
                Toast.makeText(requireContext(), "Ingresa un código", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            viewModel.joinGoal(code)
            binding.etInviteCode.text?.clear()
        }

        binding.fabAddGoal.setOnClickListener {
            findNavController().navigate(R.id.action_savings_to_add)
        }

        val adapter = SavingsGoalAdapter { goal ->
            showAddFundsDialog(goal)
        }
        binding.rvGoals.adapter = adapter

        viewModel.goals.observe(viewLifecycleOwner) { goals ->
            adapter.submitList(goals)
        }

        viewModel.success.observe(viewLifecycleOwner) {
            Toast.makeText(requireContext(), it, Toast.LENGTH_SHORT).show()
        }

        viewModel.error.observe(viewLifecycleOwner) {
            Toast.makeText(requireContext(), it, Toast.LENGTH_SHORT).show()
        }

        viewModel.loadGoals()
    }

    private fun showAddFundsDialog(goal: com.luka.finanzas.model.SavingsGoal) {
        val context = requireContext()
        val builder = AlertDialog.Builder(context)
        builder.setTitle("Aportar a ${goal.title}")
        
        val input = android.widget.EditText(context)
        input.inputType = android.text.InputType.TYPE_CLASS_NUMBER or android.text.InputType.TYPE_NUMBER_FLAG_DECIMAL
        input.hint = "Monto a aportar"
        
        val padding = (24 * resources.displayMetrics.density).toInt()
        val container = android.widget.FrameLayout(context)
        container.setPadding(padding, padding / 2, padding, 0)
        container.addView(input)
        
        builder.setView(container)
        
        builder.setPositiveButton("Aportar") { _, _ ->
            val amountStr = input.text.toString()
            val amount = amountStr.toDoubleOrNull()
            if (amount != null && amount > 0) {
                viewModel.addContribution(goal.id, amount, "Aporte")
            } else {
                Toast.makeText(context, "Monto inválido", Toast.LENGTH_SHORT).show()
            }
        }
        builder.setNegativeButton("Cancelar", null)
        builder.show()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}