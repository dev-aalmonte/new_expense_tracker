import 'package:new_expense_tracker/interface/i_db_helper.dart';
import 'package:new_expense_tracker/models/account.dart';
import 'package:new_expense_tracker/models/db_where.dart';
import 'package:flutter/material.dart';

class AccountProvider with ChangeNotifier {
  final IDBHelper _db;
  AccountProvider(this._db);

  List<Account> _accounts = [];
  List<Account> get accounts {
    return [..._accounts];
  }

  Account? activeAccount;

  void setActiveAccount(Account account) {
    activeAccount = account;
    notifyListeners();
  }

  Future<void> fetchAccounts() async {
    final dataList = await _db.fetch('accounts');
    _accounts = dataList
        .map(
          (item) => Account(
            id: item['id'],
            name: item['name'],
            accNumber: item['acc_number'],
          ),
        )
        .toList();
    notifyListeners();
  }

  Future<Account> fetchAccountById(int accountId) async {
    final data = await _db.fetchWhere("accounts", "id", accountId);
    Account returnAccount = data
        .map(
          (item) => Account(
            id: item['id'],
            name: item['name'],
            accNumber: item['acc_number'],
          ),
        )
        .toList()[0];
    return returnAccount;
  }

  Future<void> addAccount(Account account) async {
    var accountObject = {"name": account.name, "acc_number": account.accNumber};

    account.id = await _db.insert('accounts', accountObject);
    _accounts.add(account);

    notifyListeners();
  }

  // TODO: remove we do not update accounts information because available/spent columns are depricated
  Future<void> updateAccount(Account account) async {
    var accountObject = {
      "id": account.id,
      "name": account.name,
      "acc_number": account.accNumber,
    };

    await _db.update(
      'accounts',
      accountObject,
      DBWhere(column: 'id', operation: WhereOperation.equal, value: account.id),
    );
  }
}
