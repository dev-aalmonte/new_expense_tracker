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
        theme: ThemeData().copyWith(
          useMaterial3: true,
          colorScheme: kColorScheme,
          appBarTheme: const AppBarTheme().copyWith(
            backgroundColor: kColorScheme.primaryContainer,
            foregroundColor: kColorScheme.onPrimaryContainer,
          ),
          textTheme: ThemeData().textTheme.copyWith(
            displayLarge: ThemeData().textTheme.displayLarge!.copyWith(),
            displayMedium: ThemeData().textTheme.displayMedium!.copyWith(),
            displaySmall: ThemeData().textTheme.displaySmall!.copyWith(),
            headlineLarge: ThemeData().textTheme.headlineLarge!.copyWith(),
            headlineMedium: ThemeData().textTheme.headlineMedium!.copyWith(),
            headlineSmall: ThemeData().textTheme.headlineSmall!.copyWith(),
            titleLarge: ThemeData().textTheme.titleLarge!.copyWith(),
            titleMedium: ThemeData().textTheme.titleMedium!.copyWith(),
            titleSmall: ThemeData().textTheme.titleSmall!.copyWith(),
            labelLarge: ThemeData().textTheme.labelLarge!.copyWith(),
            labelMedium: ThemeData().textTheme.labelMedium!.copyWith(),
            labelSmall: ThemeData().textTheme.labelSmall!.copyWith(),
            bodyLarge: ThemeData().textTheme.bodyLarge!.copyWith(),
            bodyMedium: ThemeData().textTheme.bodyMedium!.copyWith(),
            bodySmall: ThemeData().textTheme.bodySmall!.copyWith(),
          ),
        ),
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
