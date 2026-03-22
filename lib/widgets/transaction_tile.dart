import 'package:new_expense_tracker/models/category.dart';
import 'package:new_expense_tracker/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:intl/intl.dart';
import 'package:new_expense_tracker/pages/add_transaction_page.dart';
import 'package:new_expense_tracker/providers/transactions_provider.dart';
import 'package:provider/provider.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final bool isLastItem;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.isLastItem = false,
  });

  @override
  Widget build(BuildContext context) {
    late MaterialColor iconColor;
    late IconData icon;

    switch (transaction.type) {
      case TransactionType.deposit:
        icon = Icons.arrow_upward;
        iconColor = Colors.green;
        break;
      case TransactionType.spent:
        icon = Icons.arrow_downward;
        iconColor = Colors.red;
        break;
    }

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (context) => TransactionDialog(
          transaction: transaction,
          icon: icon,
          iconColor: iconColor,
        ),
      ),
      child: Dismissible(
        key: ValueKey(transaction.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (context) => ConfirmationDialog(
              title: "Delete Transaction",
              content: "Are you sure you want to delete this transaction?",
              onConfirm: () {
                Provider.of<TransactionsProvider>(
                  context,
                  listen: false,
                ).deleteTransaction(transaction.id!);
              },
            ),
          );
        },
        child: Column(
          children: [
            ListTile(
              leading: SizedBox(
                height: double.infinity,
                child: Icon(icon, color: iconColor),
              ),
              title: Text(
                toCurrencyString(
                  transaction.amount.toString(),
                  leadingSymbol: CurrencySymbols.DOLLAR_SIGN,
                ),
              ),
              subtitle: Text(DateFormat("M/d/y").format(transaction.date)),
              trailing: transaction.category != null
                  ? Padding(
                      padding: const EdgeInsets.only(
                        left: 10,
                        right: 10,
                        top: 5,
                        bottom: 5,
                      ),
                      child: CategoryLabel(category: transaction.category!),
                    )
                  : null,
            ),
            if (!isLastItem) const Divider(height: 0, indent: 8, endIndent: 24),
          ],
        ),
      ),
    );
  }
}

class CategoryLabel extends StatelessWidget {
  final Category category;
  const CategoryLabel({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: category.color.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(backgroundColor: category.color, radius: 8),
          const SizedBox(width: 12),
          Text(
            category.name,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: .5,
            ),
          ),
        ],
      ),
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text("Confirm"),
        ),
      ],
    );
  }
}

class TransactionDialog extends StatelessWidget {
  final Transaction transaction;
  final IconData icon;
  final MaterialColor iconColor;

  const TransactionDialog({
    super.key,
    required this.transaction,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 8),
          Text(
            toCurrencyString(
              transaction.amount.toString(),
              leadingSymbol: CurrencySymbols.DOLLAR_SIGN,
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(transaction.description ?? "No description"),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog first
                      Navigator.pushNamed(
                        context,
                        AddTransactionPage.route,
                        arguments: transaction,
                      );
                    },
                    child: const Text("Edit"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
