package com.luka.finanzas.ui.dashboard

import android.graphics.Color
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import androidx.recyclerview.widget.LinearLayoutManager
import com.luka.finanzas.R
import com.luka.finanzas.databinding.FragmentDashboardBinding
import com.luka.finanzas.ui.transactions.TransactionAdapter
import java.util.Calendar

class DashboardFragment : Fragment() {

    private var _binding: FragmentDashboardBinding? = null
    private val binding get() = _binding!!
    private val viewModel: DashboardViewModel by viewModels()
    private lateinit var recentAdapter: TransactionAdapter

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?,
                              savedInstanceState: Bundle?): View {
        _binding = FragmentDashboardBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        super.onViewCreated(view, savedInstanceState)

        recentAdapter = TransactionAdapter(emptyList())
        binding.rvRecentTransactions.layoutManager = LinearLayoutManager(requireContext())
        binding.rvRecentTransactions.adapter = recentAdapter

        setupObservers()
    }

    override fun onResume() {
        super.onResume()
        loadData()
    }

    private fun setupObservers() {
        viewModel.totalIncome.observe(viewLifecycleOwner) {
            val formatted = "S/. %.2f".format(it)
            binding.tvTotalIncome.text = formatted
            binding.tvTotalIncomeCard.text = formatted
        }
        viewModel.totalExpense.observe(viewLifecycleOwner) {
            binding.tvTotalExpense.text = "S/. %.2f".format(it)
            binding.tvTotalPayments.text = "S/. 0.00" // Placeholder for now
        }
        viewModel.balance.observe(viewLifecycleOwner) {
            binding.tvBalance.text = "S/. %.2f".format(it)
        }
        viewModel.recentTransactions.observe(viewLifecycleOwner) { list ->
            recentAdapter.updateData(list)
        }
    }

    private fun loadData() {
        val cal = Calendar.getInstance()
        viewModel.loadDashboard(cal.get(Calendar.MONTH) + 1, cal.get(Calendar.YEAR))
    }

    // PieChart removed from Dashboard

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}