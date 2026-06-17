import 'package:flutter/material.dart';
import '../models/transaction.dart' as app_models;
import '../models/category.dart';
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
    String? selectedCategory = existingTx?.category;
    bool isExpense = existingTx?.isExpense ?? true;

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
            } else if (categories.isNotEmpty && !categories.contains(selectedCategory)) {
              categories.add(selectedCategory!);
            }

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
                        decoration: const InputDecoration(labelText: 'Monto', prefixText: 'S/ '),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: noteController,
                        decoration: const InputDecoration(labelText: 'Nota (Ej. Supermercado)'),
                      ),
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
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (amountController.text.isEmpty || selectedCategory == null) return;
                          final double amount = double.tryParse(amountController.text) ?? 0.0;
                          if (amount <= 0) return;
                          
                          final tx = app_models.Transaction(
                            id: existingTx?.id ?? '', 
                            note: noteController.text,
                            amount: amount,
                            date: existingTx?.date ?? DateTime.now(),
                            category: selectedCategory!,
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
          }
        );
      },
    );
  }

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
            const Text('Historial', style: TextStyle(color: Color(0xFF1D2335), fontSize: 24, fontWeight: FontWeight.bold)),
            Text('MOVIMIENTOS EN ESTE MES', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
      ),
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
            padding: const EdgeInsets.all(16.0),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isExpense = tx.isExpense;
              final title = tx.category;
              final subtitle = tx.note.isNotEmpty ? '${tx.note} · ${tx.date.day}/${tx.date.month}/${tx.date.year}' : '${tx.date.day}/${tx.date.month}/${tx.date.year}';
              
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isExpense ? '-' : '+'}S/. ${tx.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: isExpense ? Colors.black87 : Colors.green.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _showTransactionForm(context, tx),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(Icons.edit_outlined, size: 16, color: Colors.blue.shade300),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  _firestoreService.deleteTransaction(tx.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Transacción eliminada')),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade300),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
