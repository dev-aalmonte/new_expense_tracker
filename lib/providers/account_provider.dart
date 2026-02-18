import 'package:new_expense_tracker/helpers/db_helper.dart';
import 'package:new_expense_tracker/models/account.dart';
import 'package:new_expense_tracker/models/db_where.dart';
import 'package:flutter/material.dart';

class AccountProvider with ChangeNotifier {
  List<Account> _accounts = [];
  List<Account> get accounts {
    return [..._accounts];
  }

  Account? activeAccount;

  void setActiveAccount(Account account) {
    activeAccount = account;
    notifyListeners();
  }

  Future<void> fetchAccount() async {
    final dataList = await DBHelper.getData('accounts');
    _accounts = dataList
        .map(
          (item) => Account(
            id: item['id'],
            name: item['name'],
            accNumber: item['acc_number'],
            available: item['available'],
            spent: item['spent'],
          ),
        )
        .toList();
    notifyListeners();
  }

  static Future<Account> fetchAccountById(int accountId) async {
    final data = await DBHelper.fetchWhere("accounts", "id", accountId);
    Account returnAccount = data
        .map(
          (item) => Account(
            id: item['id'],
            name: item['name'],
            accNumber: item['acc_number'],
            available: item['available'],
            spent: item['spent'],
          ),
        )
        .toList()[0];
    return returnAccount;
  }

  Future<void> addAccount(Account account) async {
    var accountObject = {
      "name": account.name,
      "acc_number": account.accNumber,
      "available": account.available,
      "spent": account.spent,
    };

    account.id = await DBHelper.insert('accounts', accountObject);
    _accounts.add(account);

    notifyListeners();
  }

  static Future<void> updateAccount(Account account) async {
    var accountObject = {
      "id": account.id,
      "name": account.name,
      "acc_number": account.accNumber,
      "available": account.available,
      "spent": account.spent,
    };

    await DBHelper.update(
      'accounts',
      accountObject,
      DBWhere(column: 'id', operation: WhereOperation.equal, value: account.id),
    );
  }
}
