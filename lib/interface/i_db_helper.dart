import 'package:new_expense_tracker/models/db_where.dart';

abstract class IDBHelper {
  Future<int> insert(String table, Map<String, dynamic> data);
  Future<int> update(String table, Map<String, dynamic> values, DBWhere where);
  Future<int> delete(String table, DBWhere where);
  Future<List<Map<String, dynamic>>> fetch(String table);
  Future<List<Map<String, dynamic>>> fetchWhere(
    String table,
    String column,
    dynamic value,
  );
  Future<List<Map<String, dynamic>>> fetchWhereMultiple(
    String table,
    List<DBWhere> arguments,
  );
  Future<List<Map<String, dynamic>>> fetchWhereBetween(
    String table,
    String column,
    List range,
  );
  Future<void> clearData();
}
