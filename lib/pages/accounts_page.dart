import 'package:new_expense_tracker/models/account.dart';
import 'package:new_expense_tracker/models/transaction.dart';
import 'package:new_expense_tracker/pages/add_account_page.dart';
import 'package:new_expense_tracker/pages/tabs_page.dart';
import 'package:new_expense_tracker/providers/account_provider.dart';
import 'package:flutter/material.dart';
import 'package:new_expense_tracker/providers/transactions_provider.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  static const String route = '/account';

  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late PageController accountPagesController;

  @override
  void initState() {
    accountPagesController = PageController();
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    accountProvider.fetchAccounts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Consumer<AccountProvider>(
          builder: (context, accountProvider, _) {
            return PageView(
              controller: accountPagesController,
              clipBehavior: Clip.antiAlias,
              children: [
                ...accountProvider.accounts.map(
                  (account) => AccountCard(
                    accountProvider: accountProvider,
                    currentAccount: account,
                  ),
                ),
                const NewAccountCard(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class NewAccountCard extends StatelessWidget {
  const NewAccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(AddAccountPage.route);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(25)),
            gradient: LinearGradient(
              colors: [
                Color(0xffb6f2af),
                Color(0xffbaefa8),
                Color(0xffbfeca1),
                Color(0xffc3e99a),
                Color(0xffc8e694),
                Color(0xffcde38e),
                Color(0xffd1df88),
                Color(0xffd6dc83),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 60),
              const SizedBox(height: 12),
              Text(
                "Add an account",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.accountProvider,
    required this.currentAccount,
  });

  final AccountProvider accountProvider;
  final Account currentAccount;

  @override
  Widget build(BuildContext context) {
    final TransactionsProvider transactionsProvider =
        Provider.of<TransactionsProvider>(context, listen: true);

    if (transactionsProvider.transactionsSummary.isEmpty) {
      transactionsProvider.fetchTransactionSummary(currentAccount);
    }

    final double spent = transactionsProvider.transactionsSummary
        .where((transaction) => transaction.type == TransactionType.spent)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
    final double available =
        transactionsProvider.transactionsSummary
            .where((transaction) => transaction.type == TransactionType.deposit)
            .fold(0.0, (sum, transaction) => sum + transaction.amount) -
        spent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          accountProvider.activeAccount = currentAccount;
          Navigator.of(context).pushNamed(TabsPage.route);
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                    gradient: LinearGradient(
                      colors: [
                        Color(0xffb6f2af),
                        Color(0xffc0eb9f),
                        Color(0xffcbe490),
                        Color(0xffd6dc83),
                        Color(0xffe1d378),
                        Color(0xffecc970),
                        Color(0xfff6c06c),
                        Color(0xffffb56b),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      const Positioned(
                        top: 12,
                        child: Icon(Icons.card_membership, size: 64),
                      ),
                      Positioned(
                        top: 84,
                        child: Text(
                          currentAccount.name,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      Positioned(
                        top: 136,
                        child: Text("Acc #: ${currentAccount.accNumber}"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
                Text(
                  "Available",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${available.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall!.copyWith(color: Colors.green),
                ),
                const SizedBox(height: 80),
                Text("Spent", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  '\$${spent.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(
                    color: Colors.red.shade300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
