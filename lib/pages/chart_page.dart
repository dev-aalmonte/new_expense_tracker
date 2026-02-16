import 'package:new_expense_tracker/models/transaction.dart';
import 'package:new_expense_tracker/providers/chart_provider.dart';
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
  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 1)),
    end: DateTime.now(),
  );
  Map<Categories, double>? expensesCategoryData;
  double? maxValue;

  @override
  void initState() {
    super.initState();
    Provider.of<ChartProvider>(context, listen: false).fetchExpensesChart();
  }

  void _selectDateRange() async {
    final newDateRange = await showDateRangePicker(
        context: context,
        initialDateRange: dateRange,
        firstDate: DateTime(2022),
        lastDate: DateTime.now());

    setState(() {
      dateRange = newDateRange ?? dateRange;
    });
  }

  // Future<List<PieChartSectionData>> getExpensesPerCategoryChartData(
  //     BuildContext context) async {
  //   expensesCategoryData = await Provider.of<TransactionsProvider>(context)
  //       .expensesCategoryDataChart(dateRange);

  //   maxValue = Provider.of<TransactionsProvider>(context).max;

  //   List<PieChartSectionData> chartData = [];

  //   if (expensesCategoryData != null) {
  //     expensesCategoryData!.forEach((key, value) {
  //       double percentage = (value / maxValue!) * 100;
  //       chartData.add(
  //         PieChartSectionData(
  //           showTitle: false,
  //           radius: 40,
  //           value: value,
  //           color: Categories.categoryColors(key),
  //           title: "${percentage.toStringAsFixed(2)}%",
  //           titleStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
  //                 fontWeight: FontWeight.bold,
  //                 color: Categories.categoryTextColors(key),
  //               ),
  //         ),
  //       );
  //     });
  //   }

  //   return chartData;
  // }

  @override
  Widget build(BuildContext context) {
    // List<PieChartSectionData> categoryChartData =
    //     getExpensesPerCategoryChartData(context);

    final startDate = dateRange.start;
    final endDate = dateRange.end;

    return Column(
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
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  width: 32,
                ),
                TextButton(
                  onPressed: _selectDateRange,
                  child: Text(
                      "${startDate.month}-${startDate.day}-${startDate.year} to ${endDate.month}-${endDate.day}-${endDate.year}"),
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
                  padding: const EdgeInsets.only(left: 16, bottom: 24, top: 12),
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
                        maxY: Provider.of<ChartProvider>(context)
                                .maxBarChartValue +
                            50,
                        barGroups:
                            Provider.of<ChartProvider>(context).expensesChart),
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
                  padding: const EdgeInsets.only(left: 16, bottom: 24, top: 12),
                  child: Text(
                    "Expenses Glosary",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (true)
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 42,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          "No data available",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        )
                      ],
                    ),
                  )
                // else
                //   Row(
                //     children: [
                //       Column(
                //         children: expensesCategoryData!.keys
                //             .map((category) => ChartLegend(
                //                   color: Categories.categoryColors(category)!,
                //                   label: category.toShortString(),
                //                   value:
                //                       "${((expensesCategoryData![category]! / maxValue!) * 100).toStringAsFixed(2)}%",
                //                 ))
                //             .toList(),
                //       ),
                //       Expanded(
                //         child: SizedBox(
                //           width: 120,
                //           height: 200,
                //           child: PieChart(
                //             PieChartData(
                //               centerSpaceRadius: 40,
                //               sections: categoryChartData,
                //             ),
                //           ),
                //         ),
                //       ),
                //     ],
                //   )
              ],
            ),
          ),
        )
      ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            maxRadius: 5,
            backgroundColor: color,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            "$label: ",
            style: Theme.of(context)
                .textTheme
                .labelLarge!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge!,
          ),
        ],
      ),
    );
  }
}
