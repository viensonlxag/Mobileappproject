import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseTransaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String type;
  final String category;

  ExpenseTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
  });

  factory ExpenseTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseTransaction(
      id: doc.id,
      title: data['title'] as String,
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] as String,
      category: data['category'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'type': type,
    'category': category,
  };
}