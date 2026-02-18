import 'dart:math';

import 'package:new_expense_tracker/models/transaction.dart';
import 'package:new_expense_tracker/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

class TransactionItem extends StatefulWidget {
  final Map<String, dynamic> groupTransaction;
  const TransactionItem({super.key, required this.groupTransaction});

  @override
  State<TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<TransactionItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final List<Transaction> transactions = [
      ...widget.groupTransaction['transactions'],
    ];
    final double sumAmount = widget.groupTransaction['sumAmount'];

    final firstDayOfWeek = DateFormat('MMMd').format(
      transactions[0].date.subtract(
        Duration(
          days:
              7 - (8 - Jiffy.parseFromDateTime(transactions[0].date).dayOfWeek),
        ),
      ),
    );
    final lastDayOfWeek = DateFormat('MMMd').format(
      transactions[0].date.add(
        Duration(
          days: 7 - Jiffy.parseFromDateTime(transactions[0].date).dayOfWeek,
        ),
      ),
    );

    return Column(
      children: [
        Card(
          color: _expanded
              ? Theme.of(context).colorScheme.surfaceContainerHigh
              : Colors.transparent,
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: ListTile(
              leading: CircleAvatar(
                radius: 25,
                child: Text(DateFormat('y').format(transactions[0].date)),
              ),
              title: Text("$firstDayOfWeek - $lastDayOfWeek"),
              subtitle: Text(
                "Week: ${Jiffy.parseFromDateTime(transactions[0].date).weekOfYear}",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("\$${sumAmount.toStringAsFixed(2)}"),
                  const SizedBox(width: 24),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
          constraints: BoxConstraints(
            minHeight: _expanded ? 70 : 0,
            maxHeight: _expanded ? min(74.0 * transactions.length, 74 * 3) : 0,
          ),
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: Scrollbar(
            thumbVisibility: true,
            trackVisibility: true,
            radius: const Radius.circular(20),
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) => TransactionTile(
                transactionType: transactions[index].type,
                category: transactions[index].category,
                amount: transactions[index].amount,
                date: transactions[index].date,
                isLastItem: index == transactions.length - 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
