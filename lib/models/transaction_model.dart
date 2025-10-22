import 'package:flutter/material.dart';

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String name;
  final String category;
  final double amount;
  final DateTime date;
  final TransactionType type;

  Transaction({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
    );
  }

  Transaction copyWith({
    String? id,
    String? name,
    String? category,
    double? amount,
    DateTime? date,
    TransactionType? type,
  }) {
    return Transaction(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
    );
  }

  IconData get icon {
    switch (category) {
      case 'Food':
        return Icons.fastfood_outlined;
      case 'Subscription':
        return Icons.movie_outlined;
      case 'Utilities':
        return Icons.lightbulb_outline;
      case 'Income':
        return Icons.attach_money;
      default:
        return Icons.swap_horiz_outlined;
    }
  }
}
