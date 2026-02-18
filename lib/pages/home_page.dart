import 'package:new_expense_tracker/models/account.dart';
import 'package:new_expense_tracker/models/transaction.dart';
import 'package:new_expense_tracker/providers/account_provider.dart';
import 'package:new_expense_tracker/providers/transactions_provider.dart';
import 'package:new_expense_tracker/widgets/transaction_tile.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final List<Transaction> transactionsSummary;

  const HomePage({super.key, required this.transactionsSummary});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isMonthly = true;

  @override
  Widget build(BuildContext context) {
    AccountProvider accountProvider = Provider.of<AccountProvider>(
      context,
      listen: true,
    );
    TransactionsProvider transactionsProvider =
        Provider.of<TransactionsProvider>(context, listen: true);
    // Account activeAccount = accountProvider.activeAccount!;
    // List<Account> accounts = accountProvider.accounts;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 51.0,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                ChangeNotifierProvider.value(
                  value: accountProvider,
                  child: DropdownMenu(
                    initialSelection: accountProvider.activeAccount,
                    inputDecorationTheme: const InputDecorationTheme(
                      border: InputBorder.none,
                    ),
                    menuStyle: const MenuStyle(
                      visualDensity: VisualDensity.compact,
                      padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    ),
                    textStyle: Theme.of(context).textTheme.titleLarge,
                    trailingIcon: const Icon(null),
                    selectedTrailingIcon: const Icon(null),
                    label: const Text("Account"),
                    onSelected: (value) {
                      accountProvider.activeAccount = value;
                      transactionsProvider.resetData();
                      Future.wait([
                        transactionsProvider.fetchTransactionSummary(value!),
                        transactionsProvider.groupByWeekYear(value),
                      ]).then((_) {
                        transactionsProvider.isDataLoaded = true;
                        setState(() {});
                      });
                    },
                    dropdownMenuEntries: accountProvider.accounts
                        .map(
                          (item) => DropdownMenuEntry(
                            value: item,
                            label: item.name,
                            leadingIcon: const Icon(Icons.credit_card),
                          ),
                        )
                        .toList(),
                  ),
                ),
                ChangeNotifierProvider.value(
                  value: accountProvider,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: SegmentedButton(
                      style: const ButtonStyle(
                        visualDensity: VisualDensity(
                          vertical: -4,
                          horizontal: -4,
                        ),
                      ),
                      selected: {isMonthly},
                      onSelectionChanged: (newSelection) async {
                        transactionsProvider.isMonthly = newSelection.first;
                        transactionsProvider.fetchTransactionSummary(
                          accountProvider.activeAccount!,
                        );
                        setState(() {
                          isMonthly = newSelection.first;
                        });
                      },
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text("Week"),
                          icon: Icon(Icons.calendar_view_week),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text("Month"),
                          icon: Icon(Icons.calendar_view_month),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _expensesCard(context),
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Text(
              "Recent Transactions",
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(height: .1),
            ),
          ),
          ChangeNotifierProvider.value(
            value: transactionsProvider,
            child: Expanded(
              child: widget.transactionsSummary.isEmpty
                  ? _noDataWidget(context)
                  : ListView.builder(
                      itemCount: widget.transactionsSummary.length > 4
                          ? 4
                          : widget.transactionsSummary.length,
                      itemBuilder: (context, index) => _recentTransactions(
                        transactionType: widget.transactionsSummary[index].type,
                        category: widget.transactionsSummary[index].category,
                        amount: widget.transactionsSummary[index].amount,
                        date: widget.transactionsSummary[index].date,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Center _noDataWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 52),
          const SizedBox(height: 10),
          Text(
            "Sorry, no data to be shown!",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Padding _expensesCard(BuildContext context) {
    var summaryChartData = Provider.of<TransactionsProvider>(
      context,
    ).transactionSummaryChartData;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _expenseLabel(
                    context,
                    label: "Available",
                    value:
                        (summaryChartData["deposit"]! -
                        summaryChartData["spent"]!),
                    color: Colors.green,
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 200,
                      width: 150,
                      child: Stack(
                        children: [
                          _expenseChartLabel(
                            context,
                            summaryChartData["deposit"]!,
                          ),
                          _expenseChart(
                            (summaryChartData["deposit"]! -
                                summaryChartData["spent"]!),
                            summaryChartData["spent"]!,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _expenseLabel(
                    context,
                    label: "Spent",
                    value: summaryChartData["spent"]!,
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
          // child: Padding(
          //   padding:
          //       const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          //   child: _noDataWidget(context),
        ),
      ),
    );
  }

  Positioned _expenseChartLabel(BuildContext context, double deposit) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Total",
              style: Theme.of(
                context,
              ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              toCurrencyString(
                deposit.toString(),
                leadingSymbol: CurrencySymbols.DOLLAR_SIGN,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expenseLabel(
    BuildContext context, {
    required String label,
    required double value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              CircleAvatar(maxRadius: 4, backgroundColor: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            toCurrencyString(
              value.toStringAsFixed(2),
              leadingSymbol: CurrencySymbols.DOLLAR_SIGN,
            ),
          ),
        ],
      ),
    );
  }

  PieChart _expenseChart(double available, double spent) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: available,
            showTitle: false,
            color: Colors.green,
          ),
          PieChartSectionData(
            value: spent,
            showTitle: false,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Card _recentTransactions({
    required TransactionType transactionType,
    required double amount,
    required DateTime date,
    Categories? category,
  }) {
    return Card(
      child: TransactionTile(
        transactionType: transactionType,
        category: category,
        amount: amount,
        date: date,
      ),
    );
  }
}
