import 'package:new_expense_tracker/models/account.dart';
import 'package:new_expense_tracker/pages/add_transaction_page.dart';
import 'package:new_expense_tracker/pages/chart_page.dart';
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
  late final TransactionsProvider transactionsProvider;
  late PageController _pageController;
  late Future<void> _fetchFuture;
  late Account activeAccount;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);

    transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );

    activeAccount = Provider.of<AccountProvider>(
      context,
      listen: false,
    ).activeAccount!;

    _fetchFuture = transactionsProvider.fetchTransactions(activeAccount);
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
    return FutureBuilder(
      future: _fetchFuture,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return PopScope(
          onPopInvokedWithResult: (bool didPop, dynamic _) async {
            transactionsProvider.resetData();
          },
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.only(top: 28),
              child: Consumer<TransactionsProvider>(
                builder: (context, transProvider, _) {
                  return PageView(
                    controller: _pageController,
                    onPageChanged: (value) {
                      setState(() {
                        _selectedIndex = value;
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TransactionsPage(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: HomePage(),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        // TODO: Update chart page to solve crash issues
                        // child: NotFoundPage(),
                        child: ChartPage(),
                      ),
                    ],
                  );
                },
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
      },
    );
  }
}
