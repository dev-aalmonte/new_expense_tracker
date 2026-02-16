import 'package:new_expense_tracker/models/account.dart';
import 'package:new_expense_tracker/pages/add_transaction_page.dart';
import 'package:new_expense_tracker/pages/chart_page.dart';
import 'package:new_expense_tracker/pages/debug/not_found_page.dart';
import 'package:new_expense_tracker/pages/home_page.dart';
import 'package:new_expense_tracker/pages/transactions_page.dart';
import 'package:new_expense_tracker/providers/account_provider.dart';
import 'package:new_expense_tracker/providers/transactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TabsPage extends StatefulWidget {
  static const String route = '/tabs';

  const TabsPage({super.key});

  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  int _selectedIndex = 1;
  late PageController _pageController;

  late Account activeAccount;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    activeAccount = Provider.of<AccountProvider>(context).activeAccount!;
    if (!Provider.of<TransactionsProvider>(context).isDataLoaded) {
      Future.wait([
        Provider.of<TransactionsProvider>(
          context,
          listen: false,
        ).fetchTransactionSummary(activeAccount),
        Provider.of<TransactionsProvider>(
          context,
          listen: false,
        ).groupByWeekYear(activeAccount),
      ]).then((_) {
        Provider.of<TransactionsProvider>(context, listen: false).isDataLoaded =
            true;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    TransactionsProvider transactionsProvider =
        Provider.of<TransactionsProvider>(context);

    if (!transactionsProvider.isDataLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return WillPopScope(
      onWillPop: () async {
        Provider.of<TransactionsProvider>(context, listen: false).resetData();
        return true;
      },
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(top: 28),
          child: PageView(
            controller: _pageController,
            onPageChanged: (value) {
              setState(() {
                _selectedIndex = value;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TransactionsPage(
                  transactionsHistory: Provider.of<TransactionsProvider>(
                    context,
                  ).transactionsByWeekYear,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HomePage(
                  transactionsSummary: Provider.of<TransactionsProvider>(
                    context,
                  ).transactionsSummary,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: NotFoundPage(),
                // TODO: Update chart page to solve crash issues
                // child: ChartPage(),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, AddTransactionPage.route);
          },
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _selectPage,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.compare_arrows),
              label: "Transactions",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart),
              label: "Charts",
            ),
          ],
        ),
      ),
    );
  }
}
