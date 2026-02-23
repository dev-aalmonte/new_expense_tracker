import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:new_expense_tracker/helpers/date_helper.dart';
import 'package:new_expense_tracker/helpers/db_helper.dart';
import 'package:new_expense_tracker/models/account.dart';
import 'package:new_expense_tracker/models/db_where.dart';
import 'package:new_expense_tracker/models/transaction.dart';
import 'package:new_expense_tracker/providers/account_provider.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

class TransactionsProvider with ChangeNotifier {
  double maxValue = 0.00;
  bool isDataLoaded = false;
  bool isMonthly = true;

  List<Transaction> transactions = [];
  List<Transaction> transactionsSummary = [];
  Map<String, dynamic> transactionsByWeekYear = {};

  // Chart Data
  Map<String, double> transactionSummaryChartData = {};
  Map<String, dynamic> transactionChartDataByWeekYear = {};
  List<BarChartGroupData> expensesChartData = [];
  Map<Categories, double> expensesCategoryChartData = {};
  List<PieChartSectionData> categoryChartData = [];

  Future<void> deleteData() async {
    await DBHelper.clearData();
    notifyListeners();
  }

  void resetData() {
    maxValue = 0.00;
    isDataLoaded = false;
    isMonthly = false;

    transactionsSummary = [];
    transactionsByWeekYear = {};
    transactionSummaryChartData = {};
  }

  Future<void> addTransaction(
    Transaction transaction,
    Account activeAccount,
  ) async {
    // Create a transaction object to insert into the database
    var transactionObject = {
      "type": transaction.type.index,
      "amount": transaction.amount,
      "account_id": transaction.account.id,
      "date": transaction.date.toIso8601String(),
      "description": transaction.description,
    };

    // If the transaction is an expense, include the category
    if (transaction.type == TransactionType.spent) {
      transactionObject['category'] = transaction.category!.index;
    }

    // Add transaction to the database
    transaction.id = await DBHelper.insert('transactions', transactionObject);

    // Refresh the transaction summary and chart data
    fetchTransactionSummary(activeAccount);
    fetchTransactionsByWeekYear();

    notifyListeners();
  }

  Future<void> fetchTransactions(
    Account activeAccount, {
    DateTimeRange? dateRange,
  }) async {
    // Empty the transactions list
    List<Transaction> transactions = [];

    dateRange ??= DateTimeRange(
      start: DateTime(1970, 1, 1),
      end: DateTime.now(),
    );

    // Fetch transactions from the database
    final dataList = await DBHelper.fetchWhereMultiple('transactions', [
      DBWhere(
        column: 'date',
        operation: WhereOperation.between,
        value: [
          dateRange.start.toIso8601String(),
          dateRange.end.toIso8601String(),
        ],
        chain: WhereChain.and,
      ),
      DBWhere(
        column: 'account_id',
        operation: WhereOperation.equal,
        value: activeAccount.id,
      ),
    ]);

    for (var item in dataList) {
      transactions.add(
        Transaction(
          id: item['id'],
          account: await AccountProvider.fetchAccountById(item['account_id']),
          type: TransactionType.values[item['type']],
          amount: item['amount'],
          date: DateTime.parse(item['date']),
          category: item['category'] != null
              ? Categories.values[item['category']]
              : null,
          description: item['description'],
        ),
      );
    }

    this.transactions = transactions.reversed.toList();
    notifyListeners();
  }

  void fetchSummary() {
    transactionsSummary = transactions
        .where(
          (transaction) =>
              transaction.date.isAfter(
                DateHelper.getCurrentMonthRange().start,
              ) &&
              transaction.date.isBefore(DateHelper.getCurrentMonthRange().end),
        )
        .toList();
  }

  Future<void> fetchTransactionSummary(Account activeAccount) async {
    DateTimeRange range = isMonthly
        ? DateHelper.getCurrentMonthRange()
        : DateHelper.getCurrentWeekRange();

    final dataList = await DBHelper.fetchWhereMultiple('transactions', [
      DBWhere(
        column: 'date',
        operation: WhereOperation.between,
        value: [range.start.toIso8601String(), range.end.toIso8601String()],
        chain: WhereChain.and,
      ),
      DBWhere(
        column: 'account_id',
        operation: WhereOperation.equal,
        value: activeAccount.id,
      ),
    ]);

    List<Transaction> summaryTransactions = [];

    for (var item in dataList) {
      summaryTransactions.add(
        Transaction(
          id: item['id'],
          account: await AccountProvider.fetchAccountById(item['account_id']),
          type: TransactionType.values[item['type']],
          amount: item['amount'],
          date: DateTime.parse(item['date']),
          description: item['description'],
        ),
      );
    }

    transactionsSummary = summaryTransactions.reversed.toList();
    _fetchTransactionSummaryChartData();
  }

  void _fetchTransactionSummaryChartData() {
    transactionSummaryChartData = {"deposit": 0.00, "spent": 0.00};

    for (Transaction transaction in transactionsSummary) {
      if (transaction.type == TransactionType.deposit) {
        transactionSummaryChartData["deposit"] =
            (transactionSummaryChartData["deposit"] ?? 0) + transaction.amount;
      }
      if (transaction.type == TransactionType.spent) {
        transactionSummaryChartData["spent"] =
            (transactionSummaryChartData["spent"] ?? 0) + transaction.amount;
      }
    }
  }

  Future<void> fetchTransactionsByWeekYear() async {
    Map<String, dynamic> groupedTransactions = {};

    for (var transaction in transactions) {
      int weekYear = Jiffy.parseFromDateTime(transaction.date).weekOfYear;
      int year = Jiffy.parseFromDateTime(transaction.date).year;
      String key = "$year-$weekYear";
      int positiveNegative = transaction.type == TransactionType.deposit
          ? 1
          : -1;

      if (!groupedTransactions.containsKey(key)) {
        groupedTransactions[key] = {'sumAmount': 0, 'transactions': []};
      }

      groupedTransactions[key]['sumAmount'] +=
          transaction.amount * positiveNegative;
      groupedTransactions[key]['transactions'].add(transaction);
    }

    transactionsByWeekYear = groupedTransactions;
  }

  Future<void> expensesDataChart(
    Account activeAccount,
    DateTimeRange? dateRange,
  ) async {
    Map<String, dynamic> groupedTransactions = transactionsByWeekYear;
    List<Map<String, dynamic>> expensesData = [];
    int weekYear = Jiffy.parseFromDateTime(DateTime.now()).weekOfYear;
    int year = Jiffy.parseFromDateTime(DateTime.now()).year;
    int max = 2; // Maximum week Lookout (Relative to the actual week)

    for (int actual = -2; actual <= max; actual++) {
      String key = "$year-${weekYear - actual}";

      List<Transaction> weeklyTransactions = groupedTransactions[key] == null
          ? []
          : [...groupedTransactions[key]['transactions']];

      double deposit = 0;
      double spent = 0;

      for (var transaction in weeklyTransactions) {
        if (transaction.category == null) {
          deposit += transaction.amount;
        } else {
          spent += transaction.amount;
        }
      }

      expensesData.add({
        'deposit': deposit,
        'spent': spent,
        'weekYear': weekYear - actual,
      });
    }

    transactionSummaryChartData = {
      "deposit": expensesData.fold(0, (sum, data) => sum + data['deposit']),
      "spent": expensesData.fold(0, (sum, data) => sum + data['spent']),
    };

    transactionChartDataByWeekYear = {
      for (var data in expensesData)
        "${data['weekYear']}": {
          "deposit": data['deposit'],
          "spent": data['spent'],
        },
    };
  }

  void fetchExpensesChart() async {
    expensesChartData = [];
    List<int> weekYears = [];

    for (var entry in transactionChartDataByWeekYear.entries) {
      int weekYear = int.parse(entry.key);
      var data = entry.value;
      weekYears.add(weekYear);

      expensesChartData.add(
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
    notifyListeners();
  }

  double getExpensesChartMaxValue() {
    double maxValue = 0;
    for (var data in transactionChartDataByWeekYear.values) {
      maxValue = max(max(data['deposit'], data['spent']), maxValue);
    }
    return maxValue;
  }

  Future<void> expensesCategoryDataChart(
    Account activeAccount,
    DateTimeRange? dateRange,
  ) async {
    Map<String, dynamic> groupedTransactions = transactionsByWeekYear;
    Map<Categories, double> expensesCategoryData = {};
    late int startWeekYear;
    late int endWeekYear;
    late int startYear;
    late int endYear;

    maxValue = 0;

    if (dateRange != null) {
      startWeekYear = Jiffy.parseFromDateTime(dateRange.start).weekOfYear;
      endWeekYear = Jiffy.parseFromDateTime(dateRange.end).weekOfYear;
      startYear = Jiffy.parseFromDateTime(dateRange.start).year;
      endYear = Jiffy.parseFromDateTime(dateRange.end).year;
    } else {
      final DateTimeRange defaultRange = DateHelper.getCurrentMonthRange();
      startWeekYear = Jiffy.parseFromDateTime(defaultRange.start).weekOfYear;
      endWeekYear = Jiffy.parseFromDateTime(defaultRange.end).weekOfYear;
      startYear = Jiffy.parseFromDateTime(defaultRange.start).year;
      endYear = Jiffy.parseFromDateTime(defaultRange.end).year;
    }

    for (int year = startYear; year <= endYear; year++) {
      for (int weekYear = startWeekYear; weekYear <= endWeekYear; weekYear++) {
        String key = "$year-$weekYear";
        if (!groupedTransactions.containsKey(key)) {
          continue;
        }

        for (Transaction transaction
            in groupedTransactions[key]['transactions']) {
          if (transaction.category != null) {
            maxValue += transaction.amount;
            expensesCategoryData[transaction.category!] = transaction.amount;
          }
        }
      }
    }

    expensesCategoryChartData = expensesCategoryData;
    fetchCategoryChart();
  }

  void fetchCategoryChart() {
    categoryChartData = [];
    if (expensesCategoryChartData.isNotEmpty) {
      expensesCategoryChartData.forEach((key, value) {
        // double percentage = (value / max) * 100;
        categoryChartData.add(
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
    // notifyListeners();
  }
}
