import 'package:new_expense_tracker/models/account.dart';
import 'package:new_expense_tracker/providers/account_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddAccountPage extends StatefulWidget {
  static const String route = '/addAccount';
  const AddAccountPage({super.key});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _accountNameController = TextEditingController();

  void _submitForm() {
    var uuid = const Uuid();
    final Account account = Account(
      name: _accountNameController.text,
      accNumber: uuid.v1(),
      available: 0,
      spent: 0,
    );

    Provider.of<AccountProvider>(context, listen: false).addAccount(account);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
        child: Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "Create an Account",
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium!.copyWith(color: Colors.black),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _accountNameController,
                decoration: const InputDecoration(labelText: "Account Name"),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text("Add"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
