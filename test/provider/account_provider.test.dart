import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:new_expense_tracker/interface/i_db_helper.dart';
import 'package:new_expense_tracker/models/account.dart';
import 'package:new_expense_tracker/providers/account_provider.dart';

class MockDBHelper extends Mock implements IDBHelper {}

void main() {
  late MockDBHelper mockDb;
  late AccountProvider provider;

  setUp(() {
    mockDb = MockDBHelper();
    provider = AccountProvider(mockDb);
  });

  test("Fetch all accounts from DB", () async {
    // Loading mock data
    when(() => mockDb.fetch('accounts')).thenAnswer(
      (_) async => [
        {
          'id': 1,
          'name': 'Adonis Almonte',
          'acc_number': '123456',
          'available': 500.00,
          'spent': 20.00,
        },
        {
          'id': 2,
          'name': 'Ivan Almonte',
          'acc_number': '789123',
          'available': 500.00,
          'spent': 20.00,
        },
      ],
    );

    // Fetch accounts providers
    await provider.fetchAccounts();

    // Testing Scenarios
    expect(provider.accounts.length, 2);
    expect(provider.accounts.first.accNumber, '123456');
  });

  test("Fetch individual account by ID", () async {
    // Loading mock data
    when(() => mockDb.fetchWhere('accounts', 'id', 1)).thenAnswer(
      (_) async => [
        {
          'id': 1,
          'name': 'Adonis Almonte',
          'acc_number': '123456',
          'available': 500.00,
          'spent': 20.00,
        },
      ],
    );

    // Fetch account
    Account account = await provider.fetchAccountById(1);

    // Testing Scenarios
    expect(account.id, 1);
    expect(account.accNumber, '123456');
  });

  test("Add an account to DB", () async {
    // Arrange: mock insert to return the new ID
    when(() => mockDb.insert('accounts', any())).thenAnswer((_) async => 99);
    final account = Account(name: 'Alex Almonte', accNumber: '147258');

    // Act
    await provider.addAccount(account);

    // Assert: account is in the list and has the ID returned by the DB
    expect(provider.accounts.length, 1);
    expect(provider.accounts.first.accNumber, '147258');
    expect(provider.accounts.first.id, 99);
    verify(() => mockDb.insert('accounts', any())).called(1);
  });
}
