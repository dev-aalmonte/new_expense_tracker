import 'package:new_expense_tracker/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatelessWidget {
  final TransactionType transactionType;
  final double amount;
  final DateTime date;
  final Categories? category;
  final String? description;
  final bool isLastItem;

  const TransactionTile({
    super.key,
    required this.transactionType,
    required this.amount,
    required this.date,
    this.category,
    this.description,
    this.isLastItem = false,
  });

  @override
  Widget build(BuildContext context) {
    late MaterialColor iconColor;
    late IconData icon;

    switch (transactionType) {
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
          amount: amount,
          category: category,
          description: description,
          icon: icon,
          iconColor: iconColor,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: SizedBox(
              height: double.infinity,
              child: Icon(icon, color: iconColor),
            ),
            title: Text(
              toCurrencyString(
                amount.toString(),
                leadingSymbol: CurrencySymbols.DOLLAR_SIGN,
              ),
            ),
            subtitle: Text(DateFormat("M/d/y").format(date)),
            trailing: category != null
                ? Padding(
                    padding: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                      top: 5,
                      bottom: 5,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Categories.categoryColors(
                          category!,
                        )?.withAlpha(50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            backgroundColor: Categories.categoryColors(
                              category!,
                            ),
                            radius: 8,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            category!.toShortString(),
                            style: Theme.of(context).textTheme.labelLarge!
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: .5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
          if (!isLastItem) const Divider(height: 0, indent: 8, endIndent: 24),
        ],
      ),
    );
  }
}

class TransactionDialog extends StatelessWidget {
  final double amount;
  final String? description;
  final Categories? category;
  final IconData icon;
  final MaterialColor iconColor;

  const TransactionDialog({
    super.key,
    required this.amount,
    this.description,
    this.category,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 32),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Text(
                        toCurrencyString(
                          amount.toStringAsFixed(2),
                          leadingSymbol: CurrencySymbols.DOLLAR_SIGN,
                        ),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(description ?? "No description"),
                ),
              ),
            ],
          ),
        ),
        // Row(
        //   children: [
        //     Padding(
        //       padding: const EdgeInsets.all(16),
        //       child: Icon(
        //         icon,
        //         color: iconColor,
        //         size: 32,
        //       ),
        //     ),
        //     Column(
        //       children: [
        //         Text(
        //           toCurrencyString(amount.toStringAsFixed(2),
        //               leadingSymbol: CurrencySymbols.DOLLAR_SIGN),
        //           style: Theme.of(context).textTheme.titleLarge,
        //         ),
        //         const SizedBox(
        //           height: 8,
        //         ),
        //         Text(description ?? ""),
        //       ],
        //     )
        //   ],
        // )
      ],
    );
  }
}
