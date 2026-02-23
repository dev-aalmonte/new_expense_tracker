import 'package:new_expense_tracker/providers/transactions_provider.dart';
import 'package:new_expense_tracker/widgets/transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TransactionsPage extends StatelessWidget {
  final DateTime date = DateTime.now();

  TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TransactionsProvider transactionsProvider =
        Provider.of<TransactionsProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Transactions History",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton.filled(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Delete all data"),
                      content: const Text(
                        "Are you sure you want to delete all data? This action is unreversible",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Delete All Data
                            transactionsProvider.deleteData();
                            Navigator.pop(context);
                          },
                          child: const Text("Delete Data"),
                        ),
                      ],
                    );
                  },
                ),
                style: IconButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: transactionsProvider.transactionsByWeekYear.length,
              itemBuilder: (context, index) {
                String key = transactionsProvider.transactionsByWeekYear.keys
                    .elementAt(index);
                return Card(
                  child: TransactionItem(
                    groupTransaction:
                        transactionsProvider.transactionsByWeekYear[key],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
