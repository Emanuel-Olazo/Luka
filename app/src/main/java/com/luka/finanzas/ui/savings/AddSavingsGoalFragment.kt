package com.luka.finanzas.ui.savings

import android.os.Bundle
import android.view.*
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import com.luka.finanzas.databinding.FragmentAddSavingsGoalBinding
import com.luka.finanzas.model.SavingsGoal

class AddSavingsGoalFragment : Fragment() {

    private var _binding: FragmentAddSavingsGoalBinding? = null
    private val binding get() = _binding!!
    private val viewModel: SavingsViewModel by viewModels()

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?,
                              savedInstanceState: Bundle?): View {
        _binding = FragmentAddSavingsGoalBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.btnCreateGoal.setOnClickListener {
            val title = binding.etGoalTitle.text.toString().trim()
            val targetStr = binding.etGoalTarget.text.toString()

            if (title.isEmpty() || targetStr.isEmpty()) {
                Toast.makeText(requireContext(), "Completa todos los campos", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val target = targetStr.toDoubleOrNull()
            if (target == null || target <= 0) {
                Toast.makeText(requireContext(), "Meta inválida", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val goal = SavingsGoal(title = title, targetAmount = target)
            viewModel.createGoal(goal)
        }

        viewModel.success.observe(viewLifecycleOwner) {
            Toast.makeText(requireContext(), it, Toast.LENGTH_SHORT).show()
            findNavController().popBackStack()
        }

        viewModel.error.observe(viewLifecycleOwner) {
            Toast.makeText(requireContext(), it, Toast.LENGTH_SHORT).show()
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}