import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String uid;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.uid,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '',
      color: data['color'] ?? '#000000',
      uid: data['uid'] ?? '',
    );
  }
}
