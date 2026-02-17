import 'package:new_expense_tracker/pages/accounts_page.dart';
import 'package:new_expense_tracker/pages/add_account_page.dart';
import 'package:new_expense_tracker/pages/add_transaction_page.dart';
// import 'package:new_expense_tracker/pages/splash_page.dart';
import 'package:new_expense_tracker/pages/tabs_page.dart';
import 'package:new_expense_tracker/providers/account_provider.dart';
import 'package:new_expense_tracker/providers/chart_provider.dart';
import 'package:new_expense_tracker/providers/transactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

var kColorScheme = ColorScheme.fromSeed(seedColor: Colors.green);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TransactionsProvider>(
          create: (_) => TransactionsProvider(),
        ),
        ChangeNotifierProvider<ChartProvider>(create: (_) => ChartProvider()),
        ChangeNotifierProvider<AccountProvider>(
          create: (_) => AccountProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: kColorScheme, useMaterial3: true),
        home: const AccountPage(),
        routes: {
          TabsPage.route: (context) => const TabsPage(),
          AccountPage.route: (context) => const AccountPage(),
          AddAccountPage.route: (context) => const AddAccountPage(),
          AddTransactionPage.route: (context) => const AddTransactionPage(),
        },
      ),
    );
  }
}
