package com.luka.finanzas.ui.transactions

import android.os.Bundle
import android.view.*
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import com.google.firebase.Timestamp
import com.luka.finanzas.databinding.FragmentAddTransactionBinding
import com.luka.finanzas.model.Transaction

class AddTransactionFragment : Fragment() {

    private var _binding: FragmentAddTransactionBinding? = null
    private val binding get() = _binding!!
    private val viewModel: TransactionsViewModel by viewModels()

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?,
                              savedInstanceState: Bundle?): View {
        _binding = FragmentAddTransactionBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.btnSave.setOnClickListener {
            val amountStr = binding.etAmount.text.toString()
            val category = binding.etCategory.text.toString().trim()
            val note = binding.etNote.text.toString().trim()
            val type = if (binding.rbIncome.isChecked) "income" else "expense"

            if (amountStr.isEmpty() || category.isEmpty()) {
                Toast.makeText(requireContext(), "Completa monto y categoría", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val amount = amountStr.toDoubleOrNull()
            if (amount == null || amount <= 0) {
                Toast.makeText(requireContext(), "Monto inválido", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val transaction = Transaction(
                type = type,
                amount = amount,
                category = category,
                note = note,
                date = Timestamp.now()
            )

            viewModel.addTransaction(transaction) {
                findNavController().popBackStack()
            }
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