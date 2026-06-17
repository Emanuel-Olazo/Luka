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

                  return Card(
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
                                budget.category,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  );
                },
              );
            }
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configurar nuevo presupuesto (Próximamente)')),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_chart),
      ),
    );
  }
}
