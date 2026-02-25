import 'dart:async';
import 'dart:math';

import 'package:new_expense_tracker/helpers/date_helper.dart';
import 'package:new_expense_tracker/helpers/db_helper.dart';
import 'package:new_expense_tracker/models/account.dart';
import 'package:new_expense_tracker/models/db_where.dart';
import 'package:new_expense_tracker/models/transaction.dart';
import 'package:new_expense_tracker/providers/account_provider.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

class TransactionsProvider with ChangeNotifier {
  bool isDataLoaded = false;
  bool isMonthly = true;

  List<Transaction> transactions = [];
  List<Transaction> transactionsSummary = [];

  Future<void> deleteData() async {
    await DBHelper.clearData();
    notifyListeners();
  }

  void resetData() {
    isDataLoaded = false;
    isMonthly = false;

    transactions = [];
    transactionsSummary = [];
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
    if (transaction.type == TransactionType.deposit) {
      transaction.category = null;
    }
    transactions.insert(0, transaction);

    notifyListeners();
  }

  Future<void> fetchTransactions(
    Account activeAccount, {
    DateTimeRange? dateRange,
  }) async {
    if (isDataLoaded) {
      return;
    }

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

    // Convert the fetched data into a list of Transaction objects
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
    isDataLoaded = true;
    notifyListeners();
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
  }

  List<Transaction> fetchSummary(bool isMonthly) {
    DateTimeRange range = isMonthly
        ? DateHelper.getCurrentMonthRange()
        : DateHelper.getCurrentWeekRange();
    return transactions
        .where(
          (transaction) =>
              transaction.date.isAfter(
                range.start.subtract(Duration(seconds: 1)),
              ) &&
              transaction.date.isBefore(range.end.add(const Duration(days: 1))),
        )
        .toList();
  }

  Map<String, dynamic> fetchTransactionsByWeekYear() {
    final Map<String, dynamic> groupedTransactions = {};

    for (var transaction in transactions) {
      int weekYear = Jiffy.parseFromDateTime(transaction.date).weekOfYear;
      int year = Jiffy.parseFromDateTime(transaction.date).year;
      String key = "$year-$weekYear";
      int positiveNegative = transaction.type == TransactionType.deposit
          ? 1
          : -1;

      if (!groupedTransactions.containsKey(key)) {
        groupedTransactions[key] = {
          'sumAmount': 0.0,
          'deposit': 0.0,
          'spent': 0.0,
          'transactions': [],
        };
      }

      groupedTransactions[key]['sumAmount'] +=
          transaction.amount * positiveNegative;
      groupedTransactions[key]['deposit'] +=
          transaction.type == TransactionType.deposit ? transaction.amount : 0;
      groupedTransactions[key]['spent'] +=
          transaction.type == TransactionType.spent ? transaction.amount : 0;
      groupedTransactions[key]['transactions'].add(transaction);
    }

    return groupedTransactions;
  }

  double getExpensesChartMaxValue() {
    final Map<String, dynamic> transactionChartDataByWeekYear =
        fetchTransactionsByWeekYear();
    double maxValue = 0;
    for (var data in transactionChartDataByWeekYear.values) {
      maxValue = max(max(data['deposit'], data['spent']), maxValue);
    }
    return maxValue;
  }

  Map<String, dynamic> getExpensesDataChart({DateTimeRange? dateRange}) {
    Map<String, dynamic> groupedTransactions = fetchTransactionsByWeekYear();
    List<Map<String, dynamic>> expensesData = [];
    int weekYear = Jiffy.parseFromDateTime(DateTime.now()).weekOfYear;
    int year = Jiffy.parseFromDateTime(DateTime.now()).year;
    int max = 5; // Maximum week Lookout (Relative to the actual week)

    for (int actual = 0; actual < max; actual++) {
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

    return {
      for (var data in expensesData)
        "${data['weekYear']}": {
          "deposit": data['deposit'],
          "spent": data['spent'],
        },
    };
  }

  Map<Categories, double> getExpensesCategoryDataChart({
    DateTimeRange? dateRange,
  }) {
    Map<String, dynamic> groupedTransactions = fetchTransactionsByWeekYear();
    Map<Categories, double> expensesCategoryData = {};
    late int startWeekYear;
    late int endWeekYear;
    late int startYear;
    late int endYear;

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
            expensesCategoryData[transaction.category!] = transaction.amount;
          }
        }
      }
    }

    return expensesCategoryData;
  }
}
