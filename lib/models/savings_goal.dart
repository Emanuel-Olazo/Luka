import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  double savedAmount;
  final DateTime? deadline;
  final String createdBy;
  final String inviteCode;
  
  // Soporte para Alcancías Compartidas
  final bool isShared;
  final List<String> members;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0.0,
    this.deadline,
    required this.createdBy,
    required this.inviteCode,
    this.isShared = false,
    this.members = const [],
  });

  double get progress => targetAmount > 0 ? savedAmount / targetAmount : 0;
  double get remaining => targetAmount - savedAmount;

  factory SavingsGoal.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<String> m = List<String>.from(data['members'] ?? []);
    return SavingsGoal(
      id: doc.id,
      title: data['title'] ?? '',
      targetAmount: (data['targetAmount'] ?? 0.0).toDouble(),
      savedAmount: (data['savedAmount'] ?? 0.0).toDouble(),
      deadline: data['deadline'] != null ? (data['deadline'] as Timestamp).toDate() : null,
      createdBy: data['createdBy'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      isShared: m.length > 1,
      members: m,
    );
  }
}
