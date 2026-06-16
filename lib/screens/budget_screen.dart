import 'package:flutter/material.dart';
import '../models/budget.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // Datos Falsos (Mock Data) para demostrar el diseño
  final List<Budget> _mockBudgets = [
    Budget(id: '1', categoryId: 'Alimentación', amount: 500, spentAmount: 350, month: DateTime.now().month, year: DateTime.now().year),
    Budget(id: '2', categoryId: 'Transporte', amount: 150, spentAmount: 140, month: DateTime.now().month, year: DateTime.now().year),
    Budget(id: '3', categoryId: 'Entretenimiento', amount: 200, spentAmount: 50, month: DateTime.now().month, year: DateTime.now().year),
    Budget(id: '4', categoryId: 'Servicios', amount: 300, spentAmount: 300, month: DateTime.now().month, year: DateTime.now().year),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: _mockBudgets.length,
        itemBuilder: (context, index) {
          final budget = _mockBudgets[index];
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
                        budget.categoryId,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${budget.spentAmount.toStringAsFixed(0)} / \$${budget.amount.toStringAsFixed(0)}',
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

