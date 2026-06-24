import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/savings_goal.dart';
import '../services/firestore_service.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showJoinGoalDialog(BuildContext context) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unirse a Alcancía'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(labelText: 'Código de invitación'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isEmpty) return;
              try {
                await _firestoreService.joinSavingsGoal(codeController.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Te has unido a la alcancía!')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }

  void _showSavingsGoalForm(BuildContext context, [SavingsGoal? existingGoal]) {
    final titleController = TextEditingController(text: existingGoal?.title ?? '');
    final targetController = TextEditingController(text: existingGoal?.targetAmount.toStringAsFixed(0) ?? '');
    final savedController = TextEditingController(text: existingGoal?.savedAmount.toStringAsFixed(0) ?? '0');
    bool isShared = existingGoal?.isShared ?? false;
    DateTime? deadline = existingGoal?.deadline;

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
                  ListTile(
                    title: Text(deadline == null ? 'Sin fecha límite' : 'Límite: ${deadline!.day}/${deadline!.month}/${deadline!.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: deadline ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2050),
                      );
                      if (date != null) {
                        setModalState(() => deadline = date);
                      }
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Alcancía Compartida'),
                    subtitle: const Text('Ahorra junto con amigos o familiares'),
                    value: isShared,
                    onChanged: (val) => setModalState(() => isShared = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (isShared && existingGoal != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Código de Invitación:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(existingGoal.inviteCode, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, letterSpacing: 2)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            color: Theme.of(context).primaryColor,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: existingGoal.inviteCode));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado al portapapeles')));
                            },
                          ),
                        ],
                      ),
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
                        deadline: deadline,
                        createdBy: _firestoreService.uid ?? '',
                        inviteCode: existingGoal?.inviteCode ?? DateTime.now().millisecondsSinceEpoch.toString().substring(5),
                        isShared: isShared,
                        members: existingGoal?.members ?? [_firestoreService.uid ?? ''],
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Compartida (${goal.members.length}/4)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SelectableText('Código: ${goal.inviteCode}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                            ],
                          ),
                          if (goal.deadline != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('Límite: ${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}', 
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                          if (goal.progress >= 1.0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  SizedBox(width: 4),
                                  Text('Meta Completada', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'btnJoin',
            onPressed: () => _showJoinGoalDialog(context),
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            icon: const Icon(Icons.group_add),
            label: const Text('Unirse'),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'btnAdd',
            onPressed: () => _showSavingsGoalForm(context),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Nueva Alcancía'),
          ),
        ],
      ),
    );
  }
}
