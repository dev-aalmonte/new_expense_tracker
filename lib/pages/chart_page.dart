import 'package:jiffy/jiffy.dart';
import 'package:new_expense_tracker/models/transaction.dart';
import 'package:new_expense_tracker/providers/transactions_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  late final TransactionsProvider transactionsProvider;
  late Map<String, dynamic> expensesChartData;
  late Map<Categories, double> expensesCategoryChartData;
  late double barChartYMax;
  late double pieChartValueSum;

  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 1)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );
    barChartYMax = transactionsProvider.getExpensesChartMaxValue();
    expensesChartData = transactionsProvider.getExpensesDataChart();
    expensesCategoryChartData = transactionsProvider
        .getExpensesCategoryDataChart();
    pieChartValueSum = expensesCategoryChartData.values.fold(
      0.0,
      (previousValue, currValue) => previousValue + currValue,
    );
  }

  List<BarChartGroupData> loadExpensesChart() {
    final List<BarChartGroupData> expensesChartWidgetList = [];
    List<int> weekYears = [];

    for (var entry in expensesChartData.entries) {
      int weekYear = int.parse(entry.key);
      var data = entry.value;
      weekYears.add(weekYear);

      expensesChartWidgetList.add(
        BarChartGroupData(
          x: weekYear,
          barRods: [
            BarChartRodData(
              toY: (data['deposit'] as num).toDouble(),
              color: Colors.green,
            ),
            BarChartRodData(
              toY: (data['spent'] as num).toDouble(),
              color: Colors.red,
            ),
          ],
        ),
      );
    }

    return expensesChartWidgetList;
  }

  List<PieChartSectionData> loadCategoryChart() {
    final List<PieChartSectionData> categoryChartWidgetList = [];
    if (expensesCategoryChartData.isNotEmpty) {
      expensesCategoryChartData.forEach((key, value) {
        // double percentage = (value / max) * 100;
        categoryChartWidgetList.add(
          PieChartSectionData(
            // radius: 50,
            value: value,
            color: Categories.categoryColors(key),
            showTitle: false,
            // title: "${percentage.toStringAsFixed(2)}%",
          ),
        );
      });
    }
    return categoryChartWidgetList;
  }

  void _loadChartData() {
    setState(() {
      barChartYMax = transactionsProvider.getExpensesChartMaxValue();
      expensesChartData = transactionsProvider.getExpensesDataChart(
        dateRange: dateRange,
      );
      expensesCategoryChartData = transactionsProvider
          .getExpensesCategoryDataChart(dateRange: dateRange);
      pieChartValueSum = expensesCategoryChartData.values.fold(
        0.0,
        (previousValue, currValue) => previousValue + currValue,
      );
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
                  Container(
                    padding: const EdgeInsets.only(right: 16),
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                int weekYear = value.toInt();
                                DateTime today = DateTime.now();
                                int todayWeekYear = Jiffy.parseFromDateTime(
                                  today,
                                ).weekOfYear;

                                late DateTime firstDayOftheWeek;

                                if (todayWeekYear == weekYear) {
                                  firstDayOftheWeek = today.subtract(
                                    Duration(days: today.weekday - 1),
                                  );
                                } else {
                                  int weekDifference = todayWeekYear - weekYear;
                                  firstDayOftheWeek = today.subtract(
                                    Duration(
                                      days:
                                          (today.weekday - 1) +
                                          (weekDifference * 7),
                                    ),
                                  );
                                }
                                String formattedDate =
                                    "${firstDayOftheWeek.month}/${firstDayOftheWeek.day}";
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(formattedDate),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 80,
                              getTitlesWidget: (value, meta) {
                                return Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      toCurrencyString(
                                        value.toInt().toString(),
                                        leadingSymbol:
                                            CurrencySymbols.DOLLAR_SIGN,
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        maxY: barChartYMax * 1.2,
                        barGroups: loadExpensesChart(),
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
                  if (expensesCategoryChartData.isEmpty)
                    NoDataLabel()
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Column(
                            spacing: 8,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: expensesCategoryChartData.keys
                                .map(
                                  (category) => ChartLegend(
                                    color: Categories.categoryColors(category)!,
                                    label: category.toShortString(),
                                    value:
                                        "${((expensesCategoryChartData[category]! / pieChartValueSum) * 100).toStringAsFixed(2)}%",
                                  ),
                                )
                                .toList(),
                          ),
                          Expanded(
                            child: SizedBox(
                              width: 100,
                              height: 180,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: PieChart(
                                  PieChartData(sections: loadCategoryChart()),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
