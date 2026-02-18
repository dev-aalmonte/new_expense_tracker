import 'package:new_expense_tracker/models/account.dart';
import 'package:new_expense_tracker/pages/add_account_page.dart';
import 'package:new_expense_tracker/pages/tabs_page.dart';
import 'package:new_expense_tracker/providers/account_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  static const String route = '/account';

  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  PageController accountPagesController = PageController();

  @override
  void initState() {
    super.initState();
    Provider.of<AccountProvider>(context, listen: false).fetchAccount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: PageView(
          controller: accountPagesController,
          clipBehavior: Clip.antiAlias,
          children: [
            ...Provider.of<AccountProvider>(
              context,
            ).accounts.map((account) => AccountCard(account: account)).toList(),
            const NewAccountCard(),
          ],
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
  final Account account;
  const AccountCard({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Provider.of<AccountProvider>(context, listen: false).activeAccount =
              account;
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
                          account.name,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      Positioned(
                        top: 136,
                        child: Text("Acc #: ${account.accNumber}"),
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
                  account.available.toStringAsFixed(2),
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall!.copyWith(color: Colors.green),
                ),
                const SizedBox(height: 80),
                Text("Spent", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  account.spent.toStringAsFixed(2),
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
