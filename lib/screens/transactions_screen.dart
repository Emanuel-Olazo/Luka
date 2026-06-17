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

  void _showTransactionForm(BuildContext context, [app_models.Transaction? existingTx]) {
    final noteController = TextEditingController(text: existingTx?.note ?? '');
    final amountController = TextEditingController(text: existingTx?.amount.toString() ?? '');
    String selectedCategory = existingTx?.category ?? 'Comida'; // Default
    bool isExpense = existingTx?.isExpense ?? true;

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
                    existingTx == null ? 'Nueva Transacción' : 'Editar Transacción', 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Egreso', style: TextStyle(fontSize: 14)),
                          value: true,
                          groupValue: isExpense,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setModalState(() => isExpense = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Ingreso', style: TextStyle(fontSize: 14)),
                          value: false,
                          groupValue: isExpense,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setModalState(() => isExpense = val!),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Nota (Ej. Supermercado)'),
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
                      if (amountController.text.isEmpty) return;
                      final double amount = double.tryParse(amountController.text) ?? 0.0;
                      if (amount <= 0) return;
                      
                      final tx = app_models.Transaction(
                        id: existingTx?.id ?? '', 
                        note: noteController.text,
                        amount: amount,
                        date: existingTx?.date ?? DateTime.now(),
                        category: selectedCategory,
                        isExpense: isExpense,
                        uid: _firestoreService.uid ?? '',
                      );

                      if (existingTx == null) {
                        await _firestoreService.addTransaction(tx);
                      } else {
                        await _firestoreService.updateTransaction(tx.id, tx.toMap());
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
              
              return Dismissible(
                key: Key(tx.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _firestoreService.deleteTransaction(tx.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transacción eliminada')),
                  );
                },
                child: GestureDetector(
                  onTap: () => _showTransactionForm(context, tx),
                  child: Card(
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${isExpense ? '-' : '+'}\$${tx.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isExpense ? Colors.red : Colors.green,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                            onPressed: () => _showTransactionForm(context, tx),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                            onPressed: () {
                              _firestoreService.deleteTransaction(tx.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Transacción eliminada')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransactionForm(context),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
