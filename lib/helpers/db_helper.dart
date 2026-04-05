import 'dart:io';
import 'package:new_expense_tracker/database/database_versions.dart';
import 'package:new_expense_tracker/interface/i_db_helper.dart';
import 'package:new_expense_tracker/models/db_where.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqlite_api.dart';

class DBHelper implements IDBHelper {
  static Future<void> backupDatabase() async {
    final dbPath = await sql.getDatabasesPath();
    final original = File(path.join(dbPath, 'expenses.db'));
    final backup = File(path.join(dbPath, 'expenses_backup.db'));

    if (await original.exists()) {
      await original.copy(backup.path);
    }
  }

  static Future<void> restoreDatabase() async {
    final dbPath = await sql.getDatabasesPath();
    final original = File(path.join(dbPath, 'expenses.db'));
    final backup = File(path.join(dbPath, 'expenses_backup.db'));

    if (await backup.exists()) {
      await backup.copy(original.path);
      await backup.delete();
    }
  }

  static Future<void> _migrate(Database db, int oldv, int newv) async {
    if (oldv < 1 && newv >= 1) await DatabaseVersions.base(db);
    if (oldv < 2 && newv >= 2) await DatabaseVersions.v2(db);
    if (oldv < 3 && newv >= 3) await DatabaseVersions.v3(db);
    if (oldv < 4 && newv >= 4) await DatabaseVersions.v4(db);
  }

  static Future<Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    return sql.openDatabase(
      path.join(dbPath, 'expenses.db'),
      onCreate: (db, version) async {
        await _migrate(db, 0, version);
      },
      onUpgrade: (db, oldv, newv) async {
        await _migrate(db, oldv, newv);
      },
      onDowngrade: (db, oldv, newv) async {
        await db.close();
        await DBHelper.backupDatabase();
        await onDatabaseDowngradeDelete(db, oldv, newv);
      },
      version: 4,
    );
  }

  static bool tableExists(Database db, String table) {
    bool result = false;
    db
        .query('sqlite_master', where: 'name = ?', whereArgs: [table])
        .then((value) => result = value.isNotEmpty);
    return result;
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await DBHelper.database();
    return db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values,
    DBWhere where,
  ) async {
    final db = await DBHelper.database();
    return db.update(
      table,
      values,
      where: where.toString(),
      whereArgs: [where.value],
    );
  }

  @override
  Future<int> delete(String table, DBWhere where) async {
    final db = await DBHelper.database();
    return db.delete(table, where: where.toString(), whereArgs: [where.value]);
  }

  @override
  Future<List<Map<String, dynamic>>> fetch(String table) async {
    final db = await DBHelper.database();
    return db.query(table, orderBy: "id DESC");
  }

  @override
  Future<List<Map<String, dynamic>>> fetchWhere(
    String table,
    String column,
    var value,
  ) async {
    final db = await DBHelper.database();
    return db.query(table, where: '$column = ?', whereArgs: [value]);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchWhereMultiple(
    String table,
    List<DBWhere> arguments,
  ) async {
    final db = await DBHelper.database();
    String where = '';
    List values = [];
    for (final argument in arguments) {
      where += argument.toString();

      if (argument.operation == WhereOperation.between) {
        values.add(argument.value[0]);
        values.add(argument.value[1]);
      } else {
        values.add(argument.value);
      }

      if (argument.chain != null) {
        where += "${WhereChain.operatorToString(argument.chain!)} ";
      }
    }

    return db.query(table, where: where, whereArgs: values);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchWhereBetween(
    String table,
    String column,
    List range,
  ) async {
    final db = await DBHelper.database();
    return db.query(table, where: '$column BETWEEN ? AND ?', whereArgs: range);
  }

  @override
  Future<void> clearData() async {
    final dbPath = await sql.getDatabasesPath();
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    sql.deleteDatabase(path.join(dbPath, 'expenses.db'));
    prefs.remove('deposit');
    prefs.remove('spent');
  }
}
