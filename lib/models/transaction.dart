import 'package:new_expense_tracker/models/account.dart';
import 'package:flutter/material.dart';

enum TransactionType { deposit, spent }

enum Categories {
  bill,
  gaming,
  food,
  insurance,
  investment,
  maintenance;

  static Categories? fromName(String name) {
    for (Categories category in Categories.values) {
      if (category.name == name) return category;
    }
    return null;
  }

  static ColorSwatch<int>? categoryColors(Categories category) {
    var categoryColors = {
      Categories.bill: Colors.orangeAccent,
      Categories.gaming: Colors.yellowAccent,
      Categories.food: Colors.redAccent,
      Categories.insurance: Colors.blueAccent,
      Categories.investment: Colors.cyanAccent,
      Categories.maintenance: Colors.blueGrey,
    };

    return categoryColors[category];
  }

  static Color? categoryTextColors(Categories category) {
    var categoryTextColors = {
      Categories.bill: Colors.black87,
      Categories.gaming: Colors.black87,
      Categories.food: Colors.black87,
      Categories.insurance: Colors.black87,
      Categories.investment: Colors.black87,
      Categories.maintenance: Colors.white,
    };

    return categoryTextColors[category];
  }
}

extension ParseToString on Categories {
  String toShortString() {
    String categoryString = toString().split('.').last;
    String firstLetterUpper = categoryString[0].toUpperCase();
    categoryString = categoryString.replaceRange(0, 1, firstLetterUpper);
    return categoryString;
  }
}

class Transaction {
  late int? id;
  final Account account;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final Categories? category;
  final String? description;

  Transaction({
    this.id,
    required this.account,
    required this.type,
    required this.amount,
    required this.date,
    this.category,
    this.description,
  });
}
