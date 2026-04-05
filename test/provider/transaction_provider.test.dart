import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:new_expense_tracker/interface/i_db_helper.dart';
import 'package:new_expense_tracker/models/account.dart';
import 'package:new_expense_tracker/models/category.dart';
import 'package:new_expense_tracker/models/db_where.dart';
import 'package:new_expense_tracker/models/transaction.dart';
import 'package:new_expense_tracker/providers/transactions_provider.dart';

class MockDBHelper extends Mock implements IDBHelper {}

void main() {
  late MockDBHelper mockDb;
  late TransactionsProvider provider;

  setUpAll(() {
    registerFallbackValue(
      DBWhere(column: 'id', operation: WhereOperation.equal, value: 0),
    );
  });

  final List<Map<String, dynamic>> mockTransactions = [
    {
      'id': 5,
      'account_id': 1,
      'type': 0,
      'amount': 100.0,
      'date': '2026-02-17T00:00:00.000',
      'category': null,
      'description': 'Going overboard',
    },
    {
      'id': 6,
      'account_id': 1,
      'type': 0,
      'amount': 5000.0,
      'date': '2026-02-01T00:00:00.000',
      'category': null,
      'description': 'Testing the filtering',
    },
    {
      'id': 7,
      'account_id': 1,
      'type': 1,
      'amount': 150.0,
      'date': '2026-02-18T00:00:00.000',
      'category': 0,
      'description': 'Electricity',
    },
  ];

  setUp(() {
    mockDb = MockDBHelper();
    provider = TransactionsProvider(mockDb);
  });

  // Category
  group("Category tests |", () {
    test("Fetch all categories", () async {
      // Arrange
      when(() => mockDb.fetch('categories')).thenAnswer(
        (_) async => [
          {'id': 1, 'color': '4294198070', 'name': 'Bills'},
          {'id': 2, 'color': '4294826037', 'name': 'Gaming'},
        ],
      );

      // Act
      await provider.fetchCategories();

      // Assert
      expect(provider.categoryList.length, 2);
      expect(provider.categoryList.first.name, "Bills");
      verify(() => mockDb.fetch('categories')).called(1);
    });

    test("Fetch singular category on a loaded list", () async {
      // Arrange
      when(() => mockDb.fetch('categories')).thenAnswer(
        (_) async => [
          {'id': 1, 'color': '4294198070', 'name': 'Bills'},
          {'id': 2, 'color': '4294826037', 'name': 'Gaming'},
        ],
      );
      await provider.fetchCategories();

      // Act
      Category category = provider.fetchCategoryById(1)!;

      // Assert
      expect(category.id, 1);
      expect(category.name, "Bills");
      verify(() => mockDb.fetch('categories')).called(1);
    });

    test("Fetch singular category on a unloaded list", () {
      // Arrange
      // Act
      Category? category = provider.fetchCategoryById(1);

      // Assert
      expect(category, null);
      verifyNever(() => mockDb.fetch('categories'));
    });

    test("Add category", () async {
      // Arrange
      when(
        () => mockDb.insert('categories', any()),
      ).thenAnswer((_) async => 99);
      final Category category = Category(name: 'Bills', color: Colors.red);

      // Act
      await provider.addCategory(category);

      // Assert
      expect(provider.categoryList.length, 1);
      expect(provider.categoryList.last.name, "Bills");
      verify(() => mockDb.insert('categories', any())).called(1);
    });
  });

  group("Transactions tests |", () {
    test("Fetch all transactions", () async {
      // Arrange
      when(
        () => mockDb.fetchWhereMultiple('transactions', any()),
      ).thenAnswer((_) async => mockTransactions);

      final Account currentAccount = Account(
        id: 1,
        name: "Adonis Almonte",
        accNumber: "123456",
      );

      // Act
      await provider.fetchTransactions(currentAccount);

      // Assert
      expect(provider.transactions.length, 3);
      expect(provider.transactions.first.account.name, "Adonis Almonte");
      expect(provider.transactions.first.amount, 150.0);
      verify(() => mockDb.fetchWhereMultiple('transactions', any())).called(1);
    });

    test("fetchTransactions does not reload if already loaded", () async {
      // Arrange
      when(
        () => mockDb.fetchWhereMultiple('transactions', any()),
      ).thenAnswer((_) async => mockTransactions);

      final Account currentAccount = Account(
        id: 1,
        name: "Adonis Almonte",
        accNumber: "123456",
      );

      // Act
      await provider.fetchTransactions(currentAccount); // first call loads data
      await provider.fetchTransactions(
        currentAccount,
      ); // second call should skip

      // Assert — DB should only be hit once
      verify(() => mockDb.fetchWhereMultiple('transactions', any())).called(1);
    });

    test(
      "Add deposit transaction inserts into DB and prepends to list",
      () async {
        // Arrange
        when(
          () => mockDb.insert('transactions', any()),
        ).thenAnswer((_) async => 10);

        final Account currentAccount = Account(
          id: 1,
          name: "Adonis Almonte",
          accNumber: "123456",
        );

        final transaction = Transaction(
          account: currentAccount,
          type: TransactionType.deposit,
          amount: 200.0,
          date: DateTime(2026, 2, 20),
          description: 'Paycheck',
        );

        // Act
        await provider.addTransaction(transaction, currentAccount);

        // Assert
        expect(provider.transactions.length, 1);
        expect(provider.transactions.first.id, 10);
        expect(provider.transactions.first.type, TransactionType.deposit);
        expect(provider.transactions.first.category, null);
        verify(() => mockDb.insert('transactions', any())).called(1);
      },
    );

    test("Add spent transaction includes category in DB call", () async {
      // Arrange
      when(
        () => mockDb.insert('transactions', any()),
      ).thenAnswer((_) async => 11);

      final Account currentAccount = Account(
        id: 1,
        name: "Adonis Almonte",
        accNumber: "123456",
      );

      final category = Category(id: 1, name: 'Bills', color: Colors.orange);
      final transaction = Transaction(
        account: currentAccount,
        type: TransactionType.spent,
        amount: 150.0,
        date: DateTime(2026, 2, 20),
        category: category,
        description: 'Electricity',
      );

      // Act
      await provider.addTransaction(transaction, currentAccount);

      // Assert
      expect(provider.transactions.first.category, category);
      verify(
        () => mockDb.insert(
          'transactions',
          any(
            that: predicate<Map<String, dynamic>>(
              (map) => map['category'] == 1,
            ),
          ),
        ),
      ).called(1);
    });

    test("Edit transaction updates DB and replaces entry in list", () async {
      // Arrange — seed the list first
      when(
        () => mockDb.fetchWhereMultiple('transactions', any()),
      ).thenAnswer((_) async => mockTransactions);

      final Account currentAccount = Account(
        id: 1,
        name: "Adonis Almonte",
        accNumber: "123456",
      );

      await provider.fetchTransactions(currentAccount);

      when(
        () => mockDb.update('transactions', any(), any()),
      ).thenAnswer((_) async => 1);

      final updatedTransaction = Transaction(
        id: 7,
        account: currentAccount,
        type: TransactionType.spent,
        amount: 999.0,
        date: DateTime(2026, 2, 18),
        description: 'Updated Electricity',
        category: Category(id: 1, color: Colors.red, name: "Bills"),
      );

      // Act
      await provider.editTransaction(updatedTransaction, currentAccount);

      // Assert
      final edited = provider.transactions.firstWhere((t) => t.id == 7);
      expect(edited.amount, 999.0);
      expect(edited.description, 'Updated Electricity');
      verify(() => mockDb.update('transactions', any(), any())).called(1);
    });

    test("Delete transaction removes it from DB and from list", () async {
      // Arrange — seed the list first
      when(
        () => mockDb.fetchWhereMultiple('transactions', any()),
      ).thenAnswer((_) async => mockTransactions);

      final Account currentAccount = Account(
        id: 1,
        name: "Adonis Almonte",
        accNumber: "123456",
      );

      await provider.fetchTransactions(currentAccount);

      when(
        () => mockDb.delete('transactions', any()),
      ).thenAnswer((_) async => 1);

      // Act
      await provider.deleteTransaction(7);

      // Assert
      expect(provider.transactions.length, 2);
      expect(provider.transactions.any((t) => t.id == 7), false);
      verify(() => mockDb.delete('transactions', any())).called(1);
    });

    test("resetData clears all in-memory state", () async {
      // Arrange — seed some state
      when(
        () => mockDb.fetchWhereMultiple('transactions', any()),
      ).thenAnswer((_) async => mockTransactions);

      final Account currentAccount = Account(
        id: 1,
        name: "Adonis Almonte",
        accNumber: "123456",
      );

      await provider.fetchTransactions(currentAccount);
      expect(provider.transactions.length, 3);
      expect(provider.isDataLoaded, true);

      // Act
      provider.resetData();

      // Assert
      expect(provider.transactions, isEmpty);
      expect(provider.categoryList, isEmpty);
      expect(provider.isDataLoaded, false);
    });
  });

  group("Chart / analysis tests |", () {
    Future<void> seedTransactions() async {
      when(
        () => mockDb.fetchWhereMultiple('transactions', any()),
      ).thenAnswer((_) async => mockTransactions);

      when(() => mockDb.fetch('categories')).thenAnswer(
        (_) async => [
          {'id': 0, 'color': '4294198070', 'name': 'Bills'},
        ],
      );

      await provider.fetchCategories();
      await provider.fetchTransactions(
        Account(id: 1, name: "Adonis Almonte", accNumber: "123456"),
      );
    }

    test(
      "getExpensesChartMaxValue returns the highest deposit or spent amount",
      () async {
        // Arrange
        await seedTransactions();
        final expenseChartData = provider.fetchTransactionsByWeekYear();

        // Act
        final maxValue = provider.getExpensesChartMaxValue(expenseChartData);

        // Assert — deposits are 100 and 5000, spent is 150; max should be 5000
        expect(maxValue, 5000.0);
      },
    );

    test(
      "getExpensesCategoryDataChart returns only spent transactions",
      () async {
        // Arrange
        await seedTransactions();

        // Act
        final categoryChart = provider.getExpensesCategoryDataChart(
          dateRange: DateTimeRange(
            start: DateTime(2026, 2, 1),
            end: DateTime(2026, 2, 28),
          ),
        );

        // Assert — only transaction 7 (spent) has a category
        expect(categoryChart.length, 1);
        expect(categoryChart.values.first, 150.0);
      },
    );

    test(
      "fetchTransactionsByWeekYear groups deposit and spent totals correctly",
      () async {
        // Arrange
        await seedTransactions();

        // Act
        final grouped = provider.fetchTransactionsByWeekYear();

        // Assert — total deposit across all weeks: 100 + 5000 = 5100
        final totalDeposit = grouped.values.fold<double>(
          0,
          (sum, week) => sum + (week['deposit'] as double),
        );
        expect(totalDeposit, 5100.0);

        // Total spent: 150
        final totalSpent = grouped.values.fold<double>(
          0,
          (sum, week) => sum + (week['spent'] as double),
        );
        expect(totalSpent, 150.0);
      },
    );
  });
}
