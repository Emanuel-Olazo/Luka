import 'package:flutter/material.dart';
import '../models/transaction.dart' as app_models;
import '../services/firestore_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
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
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final transactions = snapshot.data ?? [];
          
          if (transactions.isEmpty) {
            return const Center(child: Text('No hay transacciones registradas.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
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
                  title: Text(tx.note.isNotEmpty ? tx.note : tx.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${tx.date.day}/${tx.date.month}/${tx.date.year} - ${tx.category}'),
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
