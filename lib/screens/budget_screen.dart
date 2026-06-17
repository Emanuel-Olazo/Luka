import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/transaction.dart' as app_models;
import '../services/firestore_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String _getMonthName(int month) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return month >= 1 && month <= 12 ? months[month - 1] : '';
  }

  void _showBudgetForm(BuildContext context, [Budget? existingBudget]) {
    final limitController = TextEditingController(text: existingBudget?.limitAmount.toString() ?? '');
    String selectedCategory = existingBudget?.category ?? 'Comida'; // Default
    final categories = ['Comida', 'Transporte', 'Servicios', 'Entretenimiento', 'Sueldo', 'Otros'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existingBudget == null ? 'Nuevo Presupuesto' : 'Editar Presupuesto', 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: limitController,
                    decoration: const InputDecoration(labelText: 'Límite Mensual', prefixText: '\$ '),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setModalState(() => selectedCategory = val!),
                    decoration: const InputDecoration(labelText: 'Categoría'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (limitController.text.isEmpty) return;
                      final double limit = double.tryParse(limitController.text) ?? 0.0;
                      if (limit <= 0) return;
                      
                      final budget = Budget(
                        id: existingBudget?.id ?? '', 
                        category: selectedCategory,
                        limitAmount: limit,
                        month: DateTime.now().month,
                        year: DateTime.now().year,
                        uid: _firestoreService.uid ?? '',
                      );

                      if (existingBudget == null) {
                        await _firestoreService.addBudget(budget);
                      } else {
                        await _firestoreService.updateBudget(budget.id, budget.toMap());
                      }
                      
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Guardar'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Budget>>(
        stream: _firestoreService.getBudgets(),
        builder: (context, budgetSnapshot) {
          if (budgetSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (budgetSnapshot.hasError) {
            return Center(child: Text('Error: ${budgetSnapshot.error}'));
          }

          final budgets = budgetSnapshot.data ?? [];

          if (budgets.isEmpty) {
            return const Center(child: Text('No hay presupuestos configurados.'));
          }

          return StreamBuilder<List<app_models.Transaction>>(
            stream: _firestoreService.getTransactions(),
            builder: (context, txSnapshot) {
              if (txSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
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

              return ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  final budget = budgets[index];
                  // Calcular el color de la barra dependiendo del progreso
                  Color progressColor = Colors.green;
                  if (budget.progress > 0.9) {
                    progressColor = Colors.red;
                  } else if (budget.progress > 0.7) {
                    progressColor = Colors.orange;
                  }

                  return Dismissible(
                    key: Key(budget.id),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      _firestoreService.deleteBudget(budget.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Presupuesto eliminado')),
                      );
                    },
                    child: GestureDetector(
                      onTap: () => _showBudgetForm(context, budget),
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${budget.category} (${_getMonthName(budget.month)} ${budget.year})',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '\$${budget.spentAmount.toStringAsFixed(0)} / \$${budget.limitAmount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: budget.progress > 1.0 ? Colors.red : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: budget.progress > 1.0 ? 1.0 : budget.progress,
                                backgroundColor: Colors.grey.shade200,
                                color: progressColor,
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Quedan: \$${budget.remaining.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBudgetForm(context),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_chart),
      ),
    );
  }
}
