import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final String type; // 'tool_purchase', 'premium_subscription', etc.
  final String description;
  final String status; // 'completed', 'pending', 'failed'
  final Map<String, dynamic>? metadata;

  TransactionModel({required this.id, required this.userId, required this.amount, required this.date, required this.type, required this.description, required this.status, this.metadata});

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(id: json['id'], userId: json['userId'], amount: json['amount'].toDouble(), date: (json['date'] as Timestamp).toDate(), type: json['type'], description: json['description'], status: json['status'], metadata: json['metadata']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'userId': userId, 'amount': amount, 'date': Timestamp.fromDate(date), 'type': type, 'description': description, 'status': status, 'metadata': metadata};
  }

  TransactionModel copyWith({String? id, String? userId, double? amount, DateTime? date, String? type, String? description, String? status, Map<String, dynamic>? metadata}) {
    return TransactionModel(id: id ?? this.id, userId: userId ?? this.userId, amount: amount ?? this.amount, date: date ?? this.date, type: type ?? this.type, description: description ?? this.description, status: status ?? this.status, metadata: metadata ?? this.metadata);
  }
}
