import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../services/firestore_service.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showSavingsGoalForm(BuildContext context, [SavingsGoal? existingGoal]) {
    final titleController = TextEditingController(text: existingGoal?.title ?? '');
    final targetController = TextEditingController(text: existingGoal?.targetAmount.toStringAsFixed(0) ?? '');
    final savedController = TextEditingController(text: existingGoal?.savedAmount.toStringAsFixed(0) ?? '0');
    bool isShared = existingGoal?.isShared ?? false;

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
                    existingGoal == null ? 'Nueva Alcancía' : 'Editar Alcancía', 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Nombre (Ej. Viaje a Cancún)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: targetController,
                    decoration: const InputDecoration(labelText: 'Meta de Ahorro', prefixText: 'S/ '),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: savedController,
                    decoration: const InputDecoration(labelText: 'Ya ahorrado', prefixText: 'S/ '),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Alcancía Compartida'),
                    subtitle: const Text('Ahorra junto con amigos o familiares'),
                    value: isShared,
                    onChanged: (val) => setModalState(() => isShared = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (titleController.text.isEmpty || targetController.text.isEmpty) return;
                      final double target = double.tryParse(targetController.text) ?? 0.0;
                      final double saved = double.tryParse(savedController.text) ?? 0.0;
                      if (target <= 0) return;
                      
                      final goal = SavingsGoal(
                        id: existingGoal?.id ?? '', 
                        title: titleController.text,
                        targetAmount: target,
                        savedAmount: saved,
                        createdBy: _firestoreService.uid ?? '',
                        inviteCode: existingGoal?.inviteCode ?? DateTime.now().millisecondsSinceEpoch.toString().substring(5),
                        isShared: isShared,
                        members: [_firestoreService.uid ?? ''],
                      );

                      if (existingGoal == null) {
                        await _firestoreService.addSavingsGoal(goal);
                      } else {
                        await _firestoreService.updateSavingsGoal(goal.id, goal.toMap());
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
      body: StreamBuilder<List<SavingsGoal>>(
        stream: _firestoreService.getSavingsGoals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final goals = snapshot.data ?? [];

          if (goals.isEmpty) {
            return const Center(child: Text('No tienes alcancías creadas.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              
              return Dismissible(
                key: Key(goal.id),
                background: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _firestoreService.deleteSavingsGoal(goal.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alcancía eliminada')),
                  );
                },
                child: GestureDetector(
                  onTap: () => _showSavingsGoalForm(context, goal),
                  child: Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: goal.isShared 
                          ? BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5), width: 2) 
                          : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    goal.isShared ? Icons.group : Icons.person,
                                    color: goal.isShared ? Theme.of(context).primaryColor : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    goal.title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              if (goal.isShared)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Compartida',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'S/ ${goal.savedAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              Text(
                                'Meta: S/ ${goal.targetAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: goal.progress > 1.0 ? 1.0 : goal.progress,
                            backgroundColor: Colors.grey.shade200,
                            color: Theme.of(context).primaryColor,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(6),
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
        onPressed: () => _showSavingsGoalForm(context),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
