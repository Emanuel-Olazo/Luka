package com.luka.finanzas.ui.savings

import android.os.Bundle
import android.view.*
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import androidx.recyclerview.widget.LinearLayoutManager
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

        viewModel.goals.observe(viewLifecycleOwner) { /* adapter aquí */ }

        viewModel.success.observe(viewLifecycleOwner) {
            Toast.makeText(requireContext(), it, Toast.LENGTH_SHORT).show()
        }

        viewModel.error.observe(viewLifecycleOwner) {
            Toast.makeText(requireContext(), it, Toast.LENGTH_SHORT).show()
        }

        viewModel.loadGoals()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}