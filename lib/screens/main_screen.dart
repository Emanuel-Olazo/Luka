import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/login_screen.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'budget_screen.dart';
import 'savings_screen.dart';
import 'categories_screen.dart';
import 'auth/profile_screen.dart';
import '../services/firestore_service.dart';
import '../models/transaction.dart' as app_models;
import '../models/category.dart';
import '../models/savings_goal.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      DashboardScreen(onSeeAllTransactions: () => _onItemTapped(1)),
      const TransactionsScreen(),
      const BudgetScreen(),
      const SavingsScreen(),
    ];
    _firestoreService.ensureDefaultCategories();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('¿Qué deseas registrar?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.green.shade50, child: const Icon(Icons.arrow_upward, color: Colors.green)),
                title: const Text('Ingreso'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showTransactionForm(context, false);
                },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.red.shade50, child: const Icon(Icons.arrow_downward, color: Colors.red)),
                title: const Text('Gasto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showTransactionForm(context, true);
                },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.sync, color: Colors.blue)),
                title: const Text('Transferir a Alcancía'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showTransferForm(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  void _showTransactionForm(BuildContext context, bool isExpense) {
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
                      Text(isExpense ? 'Nuevo Gasto' : 'Nuevo Ingreso', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isExpense ? Colors.red : Colors.green), textAlign: TextAlign.center),
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
                          backgroundColor: isExpense ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (amountController.text.isEmpty || selectedCategory == null) return;
                          final double amount = double.tryParse(amountController.text) ?? 0.0;
                          if (amount <= 0) return;
                          final tx = app_models.Transaction(
                            id: '', note: noteController.text, amount: amount, date: DateTime.now(),
                            category: selectedCategory!, isExpense: isExpense, uid: _firestoreService.uid ?? '',
                          );
                          await _firestoreService.addTransaction(tx);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Text(isExpense ? 'Registrar Gasto' : 'Guardar Ingreso'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luka Finanzas'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
        onPressed: () => _showAddOptions(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildTabItem(icon: Icons.home_outlined, label: 'Inicio', index: 0),
            _buildTabItem(icon: Icons.format_list_bulleted, label: 'Historial', index: 1),
            const SizedBox(width: 48), // Space for FAB
            _buildTabItem(icon: Icons.grid_view, label: 'Analítica', index: 2),
            _buildTabItem(icon: Icons.savings_outlined, label: 'Alcancías', index: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
