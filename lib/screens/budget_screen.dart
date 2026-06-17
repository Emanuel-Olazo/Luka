import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/budget.dart';
import '../models/transaction.dart' as app_models;
import '../models/category.dart';
import '../services/firestore_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isBudgetVsReal = true;
  final TextEditingController _limitController = TextEditingController();
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analítica', style: TextStyle(color: Color(0xFF1D2335), fontSize: 24, fontWeight: FontWeight.bold)),
            Text('GRÁFICOS Y PRESUPUESTOS', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Custom Tab Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isBudgetVsReal = true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isBudgetVsReal ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: _isBudgetVsReal
                              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Presupuesto vs Real',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isBudgetVsReal ? Colors.black87 : Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isBudgetVsReal = false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_isBudgetVsReal ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: !_isBudgetVsReal
                              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Distribución',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !_isBudgetVsReal ? Colors.black87 : Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Budget>>(
              stream: _firestoreService.getBudgets(),
              builder: (context, budgetSnapshot) {
                return StreamBuilder<List<app_models.Transaction>>(
                  stream: _firestoreService.getTransactions(),
                  builder: (context, txSnapshot) {
                    final budgets = budgetSnapshot.data ?? [];
                    final transactions = txSnapshot.data ?? [];

                    // Calculate spent amount for each budget
                    for (var budget in budgets) {
                      double spent = 0;
                      for (var tx in transactions) {
                        if (tx.isExpense && tx.category == budget.category && tx.date.month == budget.month && tx.date.year == budget.year) {
                          spent += tx.amount;
                        }
                      }
                      budget.spentAmount = spent;
                    }

                    if (_isBudgetVsReal) {
                      return _buildBudgetVsRealTab(budgets, transactions);
                    } else {
                      return _buildDistributionTab(transactions);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetVsRealTab(List<Budget> budgets, List<app_models.Transaction> transactions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Line Chart Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Presupuesto vs. Real', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('EJECUCIÓN POR CATEGORÍA', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: budgets.isEmpty ? const Center(child: Text('No hay presupuestos para mostrar')) : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1, dashArray: [5, 5])),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < budgets.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(budgets[value.toInt()].category, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 200,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(value.toInt().toString(), style: TextStyle(color: Colors.grey.shade500, fontSize: 10));
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        // Meta (Black line)
                        LineChartBarData(
                          spots: budgets.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.limitAmount)).toList(),
                          isCurved: true,
                          color: Colors.black87,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                        ),
                        // Real (Blue line)
                        LineChartBarData(
                          spots: budgets.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.spentAmount)).toList(),
                          isCurved: true,
                          color: Colors.blue.shade600,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Meta', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 16),
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.blue.shade600, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Real', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Fijar Presupuesto Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fijar Presupuesto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: budgets.map((b) => Chip(
                    label: Text('${b.category} S/. ${b.limitAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.blue.shade50,
                    deleteIcon: Icon(Icons.close, size: 14, color: Colors.blue.shade300),
                    onDeleted: () {
                      _firestoreService.deleteBudget(b.id);
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
                  )).toList(),
                ),
                const SizedBox(height: 24),
                StreamBuilder<List<Category>>(
                  stream: _firestoreService.getCategories(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data?.map((c) => c.name).toList() ?? [];
                    if (categories.isNotEmpty && _selectedCategory == null && !categories.contains(_selectedCategory)) {
                      _selectedCategory = categories.first;
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          hint: const Text('Categoría'),
                          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val),
                        ),
                      ),
                    );
                  }
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                        child: TextField(
                          controller: _limitController,
                          decoration: const InputDecoration(border: InputBorder.none, hintText: 'Límite en S/.'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (_limitController.text.isEmpty || _selectedCategory == null) return;
                        final double limit = double.tryParse(_limitController.text) ?? 0.0;
                        if (limit <= 0) return;
                        
                        final budget = Budget(
                          id: '', 
                          category: _selectedCategory!,
                          limitAmount: limit,
                          month: DateTime.now().month,
                          year: DateTime.now().year,
                          uid: _firestoreService.uid ?? '',
                        );

                        await _firestoreService.addBudget(budget);
                        _limitController.clear();
                        setState(() {});
                      },
                      child: const Text('Fijar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionTab(List<app_models.Transaction> transactions) {
    Map<String, double> expensesByCategory = {};
    for (var tx in transactions) {
      if (tx.isExpense) {
        expensesByCategory[tx.category] = (expensesByCategory[tx.category] ?? 0) + tx.amount;
      }
    }

    final colors = [
      Colors.green.shade600,
      Colors.amber.shade500,
      Colors.blue.shade600,
      Colors.red.shade500,
      Colors.purple.shade500,
      Colors.teal.shade500,
    ];

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    expensesByCategory.forEach((category, amount) {
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length], // Removed unnecessary !
          value: amount,
          title: '', // No titles on the chart itself to match design
          radius: 40,
        ),
      );
      colorIndex++;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Distribución Global', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('ESTRUCTURA FINANCIERA DEL PERÍODO', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 48),
            SizedBox(
              height: 200,
              child: expensesByCategory.isEmpty ? const Center(child: Text('No hay gastos registrados')) : PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 48),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: expensesByCategory.keys.toList().asMap().entries.map((e) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(e.value, style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
