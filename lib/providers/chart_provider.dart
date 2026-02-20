import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:new_expense_tracker/models/transaction.dart';

class ChartProvider with ChangeNotifier {
  double maxBarChartValue = 0;
  List<BarChartGroupData> _expensesChart = [];
  List<BarChartGroupData> get expensesChart {
    return [..._expensesChart];
  }

  double totalPieChartValue = 0;
  List<PieChartSectionData> _categoryChart = [];
  List<PieChartSectionData> get categoryChart {
    return [..._categoryChart];
  }

  void fetchExpensesChart(List<Map<String, dynamic>> dataChart) async {
    _expensesChart = [];
    for (var data in dataChart) {
      maxBarChartValue = max(
        max(data['deposit'], data['spent']),
        maxBarChartValue,
      );
      _expensesChart.add(
        BarChartGroupData(
          x: data['weekYear'],
          barRods: [
            BarChartRodData(toY: data['deposit'], color: Colors.green),
            BarChartRodData(toY: data['spent'], color: Colors.red),
          ],
        ),
      );
    }
    notifyListeners();
  }

  void fetchCategoryChart(
    Map<Categories, double>? expensesCategoryData,
    double max,
  ) {
    if (expensesCategoryData != null) {
      expensesCategoryData.forEach((key, value) {
        // double percentage = (value / max) * 100;
        _categoryChart.add(
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
    notifyListeners();
  }
}
