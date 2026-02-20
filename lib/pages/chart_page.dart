import 'package:new_expense_tracker/models/account.dart';
import 'package:new_expense_tracker/models/transaction.dart';
import 'package:new_expense_tracker/providers/account_provider.dart';
import 'package:new_expense_tracker/providers/transactions_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  double barChartYMax = 0.0;
  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 1)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChartData();
    });
  }

  void _loadChartData() {
    final AccountProvider accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final TransactionsProvider transactionsProvider =
        Provider.of<TransactionsProvider>(context, listen: false);

    final Account activeAccount = accountProvider.activeAccount!;
    transactionsProvider.expensesDataChart(activeAccount, dateRange).then((_) {
      transactionsProvider.fetchExpensesChart();
      if (mounted) {
        setState(() {
          barChartYMax =
              transactionsProvider.getExpensesChartMaxValue() +
              transactionsProvider.getExpensesChartMaxValue() * 0.2;
        });
      }
    });

    transactionsProvider
        .expensesCategoryDataChart(activeAccount, dateRange)
        .then((data) {
          transactionsProvider.fetchCategoryChart();
        });
  }

  void _selectDateRange() async {
    final newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: dateRange,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );

    if (newDateRange != null) {
      setState(() {
        dateRange = newDateRange;
      });
      _loadChartData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final startDate = dateRange.start;
    final endDate = dateRange.end;

    return Consumer<TransactionsProvider>(
      builder: (context, transactionsProvider, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 12),
            child: Text(
              "Charts",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "Date Range",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 32),
                  TextButton(
                    onPressed: _selectDateRange,
                    child: Text(
                      "${startDate.month}-${startDate.day}-${startDate.year} to ${endDate.month}-${endDate.day}-${endDate.year}",
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      bottom: 24,
                      top: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Weekly Expenses",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        maxY: barChartYMax,
                        barGroups: transactionsProvider.expensesChartData,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      bottom: 24,
                      top: 12,
                    ),
                    child: Text(
                      "Expenses Glosary",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (transactionsProvider.categoryChartData.isEmpty)
                    NoDataLabel()
                  else
                    Row(
                      children: [
                        Column(
                          spacing: 8,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: transactionsProvider
                              .expensesCategoryChartData
                              .keys
                              .map(
                                (category) => ChartLegend(
                                  color: Categories.categoryColors(category)!,
                                  label: category.toShortString(),
                                  value:
                                      "${((transactionsProvider.expensesCategoryChartData[category]! / transactionsProvider.maxValue) * 100).toStringAsFixed(2)}%",
                                ),
                              )
                              .toList(),
                        ),
                        Expanded(
                          child: SizedBox(
                            width: 120,
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections:
                                    transactionsProvider.categoryChartData,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NoDataLabel extends StatelessWidget {
  const NoDataLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 42),
          const SizedBox(height: 12),
          Text(
            "No data available",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const ChartLegend({
    super.key,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 4,
      children: [
        CircleAvatar(maxRadius: 5, backgroundColor: color),
        Text(
          "$label: ",
          style: Theme.of(
            context,
          ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(value, style: Theme.of(context).textTheme.labelLarge!),
      ],
    );
  }
}
