import 'package:flutter/material.dart';
import '../models/transaction.dart' as app_models;
import '../models/savings_goal.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onSeeAllTransactions;

  const DashboardScreen({super.key, this.onSeeAllTransactions});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder<List<app_models.Transaction>>(
        stream: _firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data ?? [];
          
          double totalBalance = 0;
          double totalIngresos = 0;
          double totalGastos = 0;
          double totalAhorros = 0;
          
          final now = DateTime.now();

          for (var tx in transactions) {
            // Balance is historical (all time)
            if (tx.isExpense) {
              totalBalance -= tx.amount;
            } else {
              totalBalance += tx.amount;
            }

            // Resumen mensual (mes actual)
            if (tx.date.year == now.year && tx.date.month == now.month) {
              if (tx.category == 'Ahorro') {
                totalAhorros += tx.amount;
              } else if (tx.isExpense) {
                totalGastos += tx.amount;
              } else {
                totalIngresos += tx.amount;
              }
            }
          }

          final recentTx = transactions.take(5).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Dark Blue)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D2335),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'HOLA, OLAZO',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  children: [
                                    Text('S/. ', style: TextStyle(color: Colors.white)),
                                    Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Text('2026', style: TextStyle(color: Colors.white70)),
                          Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
                          SizedBox(width: 12),
                          Text('May', style: TextStyle(color: Colors.white70)),
                          Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'SALDO DISPONIBLE',
                        style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'S/. ${totalBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ingresos: S/. ${totalIngresos.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Resumen del Período
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RESUMEN DEL PERÍODO',
                        style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildSummaryCard('GASTOS', 'S/. ${totalGastos.toStringAsFixed(2)}', Colors.red, Icons.arrow_downward)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSummaryCard('AHORROS', 'S/. ${totalAhorros.toStringAsFixed(2)}', Colors.blue, Icons.savings)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSummaryCard('INGRESOS', 'S/. ${totalIngresos.toStringAsFixed(2)}', Colors.green, Icons.arrow_upward)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Movimientos Recientes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: widget.onSeeAllTransactions,
                            child: Text(
                              'Ver todos >',
                              style: TextStyle(fontSize: 14, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (recentTx.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No hay movimientos recientes.', style: TextStyle(color: Colors.grey)),
                        ))
                      else
                        ...recentTx.map((tx) => _buildRecentTransactionTile(
                              context,
                              tx.category,
                              tx.note.isNotEmpty ? tx.note : tx.category,
                              tx.amount,
                              tx.isExpense,
                            )),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, MaterialColor color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color.shade300, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            amount,
            style: TextStyle(
              color: color.shade400,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showIncomeForm(BuildContext context) {
    final noteController = TextEditingController();
    final amountController = TextEditingController();
    String? selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StreamBuilder<List<Category>>(
          stream: _firestoreService.getCategories(),
          builder: (context, snapshot) {
            final categories = snapshot.data?.map((c) => c.name).toList() ?? [];
            if (categories.isNotEmpty && selectedCategory == null) {
              selectedCategory = categories.first;
            }

            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                    left: 20, right: 20, top: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Nuevo Ingreso', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        decoration: const InputDecoration(labelText: 'Monto', prefixText: 'S/ '),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 10),
                      TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Nota (Opcional)')),
                      const SizedBox(height: 10),
                      if (categories.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Cargando categorías...', style: TextStyle(color: Colors.grey)),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) => setModalState(() => selectedCategory = val),
                          decoration: const InputDecoration(labelText: 'Categoría'),
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (amountController.text.isEmpty || selectedCategory == null) return;
                          final double amount = double.tryParse(amountController.text) ?? 0.0;
                          if (amount <= 0) return;
                          final tx = app_models.Transaction(
                            id: '', note: noteController.text, amount: amount, date: DateTime.now(),
                            category: selectedCategory!, isExpense: false, uid: _firestoreService.uid ?? '',
                          );
                          await _firestoreService.addTransaction(tx);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Guardar Ingreso'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              }
            );
          }
        );
      },
    );
  }

  void _showExpenseForm(BuildContext context) {
    final noteController = TextEditingController();
    final amountController = TextEditingController();
    String? selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StreamBuilder<List<Category>>(
          stream: _firestoreService.getCategories(),
          builder: (context, snapshot) {
            final categories = snapshot.data?.map((c) => c.name).toList() ?? [];
            if (categories.isNotEmpty && selectedCategory == null) {
              selectedCategory = categories.first;
            }

            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                    left: 20, right: 20, top: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Nuevo Gasto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        decoration: const InputDecoration(labelText: 'Monto', prefixText: 'S/ '),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 10),
                      TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Nota (Opcional)')),
                      const SizedBox(height: 10),
                      if (categories.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Cargando categorías...', style: TextStyle(color: Colors.grey)),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) => setModalState(() => selectedCategory = val),
                          decoration: const InputDecoration(labelText: 'Categoría'),
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (amountController.text.isEmpty || selectedCategory == null) return;
                          final double amount = double.tryParse(amountController.text) ?? 0.0;
                          if (amount <= 0) return;
                          final tx = app_models.Transaction(
                            id: '', note: noteController.text, amount: amount, date: DateTime.now(),
                            category: selectedCategory!, isExpense: true, uid: _firestoreService.uid ?? '',
                          );
                          await _firestoreService.addTransaction(tx);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Registrar Gasto'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              }
            );
          }
        );
      },
    );
  }

  void _showTransferForm(BuildContext context) {
    final amountController = TextEditingController();
    SavingsGoal? selectedGoal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StreamBuilder<List<SavingsGoal>>(
          stream: _firestoreService.getSavingsGoals(),
          builder: (context, snapshot) {
            final goals = snapshot.data ?? [];
            if (goals.isNotEmpty && selectedGoal == null) selectedGoal = goals.first;

            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                    left: 20, right: 20, top: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Transferir a Alcancía', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      if (goals.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No tienes alcancías creadas. Crea una en la pestaña "Ahorros" primero.', textAlign: TextAlign.center),
                        )
                      else ...[
                        DropdownButtonFormField<SavingsGoal>(
                          value: selectedGoal,
                          items: goals.map((g) => DropdownMenuItem(value: g, child: Text(g.title))).toList(),
                          onChanged: (val) => setModalState(() => selectedGoal = val),
                          decoration: const InputDecoration(labelText: 'Selecciona una Alcancía'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: amountController,
                          decoration: const InputDecoration(labelText: 'Monto a Transferir', prefixText: 'S/ '),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            if (amountController.text.isEmpty || selectedGoal == null) return;
                            final double amount = double.tryParse(amountController.text) ?? 0.0;
                            if (amount <= 0) return;
                            
                            try {
                              await _firestoreService.transferToSavingsGoal(selectedGoal!, amount);
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          },
                          child: const Text('Completar Transferencia'),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              }
            );
          }
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.1),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: () {
              if (label == 'Ingresar') {
                _showIncomeForm(context);
              } else if (label == 'Gasto') {
                _showExpenseForm(context);
              } else if (label == 'Transferir') {
                _showTransferForm(context);
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildRecentTransactionTile(BuildContext context, String title, String subtitle, double amount, bool isExpense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isExpense ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isExpense ? Icons.arrow_downward : Icons.arrow_upward,
            color: isExpense ? Colors.red.shade300 : Colors.blue.shade300,
            size: 20,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        trailing: Text(
          '${isExpense ? '-' : '+'}S/. ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: isExpense ? Colors.black87 : Colors.green.shade600,
          ),
        ),
      ),
    );
  }
}
