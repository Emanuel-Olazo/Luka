import 'package:flutter/material.dart';
import '../models/transaction.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // Datos Falsos (Mock Data) para demostrar el diseño
  final List<Transaction> _mockTransactions = [
    Transaction(id: '1', title: 'Supermercado', amount: 150.50, date: DateTime.now().subtract(const Duration(days: 1)), categoryId: 'c1', isExpense: true),
    Transaction(id: '2', title: 'Salario', amount: 2500.00, date: DateTime.now().subtract(const Duration(days: 2)), categoryId: 'c2', isExpense: false),
    Transaction(id: '3', title: 'Netflix', amount: 15.99, date: DateTime.now().subtract(const Duration(days: 3)), categoryId: 'c3', isExpense: true),
    Transaction(id: '4', title: 'Gasolina', amount: 40.00, date: DateTime.now().subtract(const Duration(days: 4)), categoryId: 'c4', isExpense: true),
    Transaction(id: '5', title: 'Venta de bicicleta', amount: 300.00, date: DateTime.now().subtract(const Duration(days: 5)), categoryId: 'c5', isExpense: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _mockTransactions.length,
        itemBuilder: (context, index) {
          final tx = _mockTransactions[index];
          final isExpense = tx.isExpense;
          
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isExpense ? Colors.red.shade100 : Colors.green.shade100,
                child: Icon(
                  isExpense ? Icons.shopping_bag : Icons.attach_money,
                  color: isExpense ? Colors.red : Colors.green,
                ),
              ),
              title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${tx.date.day}/${tx.date.month}/${tx.date.year}'),
              trailing: Text(
                '${isExpense ? '-' : '+'}\$${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isExpense ? Colors.red : Colors.green,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agregar nueva transacción (Próximamente)')),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

