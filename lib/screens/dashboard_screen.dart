import 'package:flutter/material.dart';
import '../models/transaction.dart' as app_models;
import '../models/savings_goal.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<app_models.Transaction>>(
        stream: _firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data ?? [];
          
          double totalBalance = 0;
          for (var tx in transactions) {
            if (tx.isExpense) {
              totalBalance -= tx.amount;
            } else {
              totalBalance += tx.amount;
            }
          }

          final recentTx = transactions.take(3).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saldo Total Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).primaryColor, Colors.teal.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo Total',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'S/ ${totalBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botones de Acción Rápida
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(context, Icons.arrow_downward, 'Ingresar', Colors.green),
                    _buildActionButton(context, Icons.arrow_upward, 'Gasto', Colors.red),
                    _buildActionButton(context, Icons.sync, 'Transferir', Colors.blue),
                  ],
                ),
                
                const SizedBox(height: 32),
                const Text(
                  'Transacciones Recientes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                if (recentTx.isEmpty)
                  const Text('No hay transacciones recientes.')
                else
                  ...recentTx.map((tx) => _buildRecentTransactionTile(
                        context,
                        tx.note.isNotEmpty ? tx.note : tx.category,
                        '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                        tx.amount,
                        tx.isExpense,
                      )),
              ],
            ),
          );
        },
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
                            
                            await _firestoreService.transferToSavingsGoal(selectedGoal!, amount);
                            if (ctx.mounted) Navigator.pop(ctx);
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

  Widget _buildRecentTransactionTile(BuildContext context, String title, String date, double amount, bool isExpense) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpense ? Colors.red.shade100 : Colors.green.shade100,
          child: Icon(
            isExpense ? Icons.shopping_bag : Icons.attach_money,
            color: isExpense ? Colors.red : Colors.green,
            size: 20,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(date),
        trailing: Text(
          '${isExpense ? '-' : '+'}S/ ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isExpense ? Colors.red : Colors.green,
          ),
        ),
      ),
    );
  }
}
