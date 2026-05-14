package com.luka.finanzas.ui.dashboard

import android.graphics.Color
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.lifecycleScope
import com.github.mikephil.charting.data.PieData
import com.github.mikephil.charting.data.PieDataSet
import com.github.mikephil.charting.data.PieEntry
import com.luka.finanzas.databinding.FragmentDashboardBinding
import kotlinx.coroutines.launch
import java.util.Calendar

class DashboardFragment : Fragment() {

    private var _binding: FragmentDashboardBinding? = null
    private val binding get() = _binding!!
    private val viewModel: DashboardViewModel by viewModels()

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?,
                              savedInstanceState: Bundle?): View {
        _binding = FragmentDashboardBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        loadData()
    }

    private fun loadData() {
        lifecycleScope.launch {
            val cal = Calendar.getInstance()
            viewModel.loadDashboard(cal.get(Calendar.MONTH) + 1, cal.get(Calendar.YEAR))

            viewModel.totalIncome.observe(viewLifecycleOwner) {
                binding.tvTotalIncome.text = "S/. %.2f".format(it)
            }
            viewModel.totalExpense.observe(viewLifecycleOwner) {
                binding.tvTotalExpense.text = "S/. %.2f".format(it)
            }
            viewModel.balance.observe(viewLifecycleOwner) {
                binding.tvBalance.text = "S/. %.2f".format(it)
            }
            viewModel.categoryExpenses.observe(viewLifecycleOwner) { map ->
                setupPieChart(map)
            }
        }
    }

    private fun setupPieChart(data: Map<String, Double>) {
        if (data.isEmpty()) return
        val entries = data.map { PieEntry(it.value.toFloat(), it.key) }
        val colors = listOf(
            Color.parseColor("#FF5722"), Color.parseColor("#2196F3"),
            Color.parseColor("#9C27B0"), Color.parseColor("#4CAF50"),
            Color.parseColor("#FF9800"), Color.parseColor("#00BCD4"),
            Color.parseColor("#795548"), Color.parseColor("#607D8B")
        )
        val dataSet = PieDataSet(entries, "").apply {
            this.colors = colors
            valueTextSize = 12f
            valueTextColor = Color.WHITE
        }
        binding.pieChart.apply {
            this.data = PieData(dataSet)
            description.isEnabled = false
            isDrawHoleEnabled = true
            holeRadius = 40f
            setHoleColor(Color.WHITE)
            legend.isEnabled = true
            animateY(800)
            invalidate()
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}