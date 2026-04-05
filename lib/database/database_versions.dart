import 'package:sqflite/sqflite.dart';

class DatabaseVersions {
  static Future<void> base(Database db) async {
    // Transaction table
    await db.execute("""CREATE TABLE IF NOT EXISTS transactions(
      id INTEGER PRIMARY KEY NOT NULL,
      account_id INTEGER NOT NULL,
      type INTEGER NOT NULL,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      category INTEGER,
      description TEXT)
    """);

    // User table
    await db.execute("""CREATE TABLE IF NOT EXISTS user_card(
      id INTEGER PRIMARY KEY NOT NULL,
      total REAL NOT NULL,
      spent REAL NOT NULL)
    """);

    // Account Table
    await db.execute("""CREATE TABLE IF NOT EXISTS accounts(
      id INTEGER PRIMARY KEY NOT NULL,
      name TEXT NOT NULL,
      acc_number TEXT NOT NULL UNIQUE,
      available REAL NOT NULL,
      spent REAL NOT NULL)
    """);

    // Categories Table
    await db.execute("""CREATE TABLE IF NOT EXISTS categories(
      id INTEGER PRIMARY KEY NOT NULL,
      color TEXT NOT NULL,
      name TEXT NOT NULL)
    """);
  }

  static Future<void> v2(Database db) async {
    // 1. Create accounts without the columns you want to remove
    await db.execute("""
      CREATE TABLE accounts_new(
        id INTEGER PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        acc_number TEXT NOT NULL UNIQUE)
    """);

    // 2. Copy existing data across
    await db.execute("""
      INSERT INTO accounts_new (id, name, acc_number)
      SELECT id, name, acc_number FROM accounts
    """);

    // 3. Drop the old table and rename the new one
    await db.execute("DROP TABLE accounts");
    await db.execute("ALTER TABLE accounts_new RENAME TO accounts");

    // 4. Drop user_card (this is safe on all SQLite versions)
    await db.execute("DROP TABLE user_card");
  }

  static Future<void> v3(Database db) async {
    await db.execute("""
      CREATE TABLE debts(
        id INTEGER PRIMARY KEY NOT NULL,
        account_id INTEGER NOT NULL,
        lender TEXT NOT NULL,
        title TEXT NOT NULL,
        lend REAL NOT NULL,
        interest_rate REAL NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL
      )
    """);
  }

  static Future<void> v4(Database db) async {
    // Apply the column/table removals that v2 failed to apply
    await db.execute("""
      CREATE TABLE accounts_new(
        id INTEGER PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        acc_number TEXT NOT NULL UNIQUE)
    """);

    await db.execute("""
      INSERT INTO accounts_new (id, name, acc_number)
      SELECT id, name, acc_number FROM accounts
    """);

    await db.execute("DROP TABLE accounts");
    await db.execute("ALTER TABLE accounts_new RENAME TO accounts");

    await db.execute("DROP TABLE IF EXISTS user_card");
  }
}
