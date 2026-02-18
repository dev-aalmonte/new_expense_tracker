import 'package:new_expense_tracker/models/account.dart';
import 'package:new_expense_tracker/models/transaction.dart';
import 'package:new_expense_tracker/providers/account_provider.dart';
import 'package:new_expense_tracker/providers/transactions_provider.dart';
import 'package:new_expense_tracker/widgets/currency_form_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddTransactionPage extends StatefulWidget {
  static const String route = '/addTransactions';
  final Function? changePage;

  const AddTransactionPage({super.key, this.changePage});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final Account _activeAccount;

  final DateTime _today = DateTime.now();
  late DateTime _actualDate;
  bool _isDeposit = true;
  String category = Categories.bill.toShortString();

  @override
  void initState() {
    super.initState();
    _actualDate = _today;
    _dateController.text = DateFormat('M/d/y').format(_today);
    _amountController.text = "0.00";
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
    _activeAccount = Provider.of<AccountProvider>(
      context,
      listen: false,
    ).activeAccount!;
  }

  void _submitForm() {
    FocusManager.instance.primaryFocus?.unfocus();
    final Transaction transaction = Transaction(
      type: _isDeposit ? TransactionType.deposit : TransactionType.spent,
      category: Categories.fromName(category.toLowerCase()),
      amount: double.parse(_amountController.text),
      account: _activeAccount,
      date: DateFormat('M/d/y').parse(_dateController.text),
      description: _descriptionController.text,
    );

    if (transaction.amount > 0.00) {
      Provider.of<TransactionsProvider>(
        context,
        listen: false,
      ).addTransaction(transaction, _activeAccount);

      if (widget.changePage != null) {
        widget.changePage!();
      } else {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: const Text("Transaction should have amount"),
          action: SnackBarAction(
            textColor: Colors.white,
            label: 'Ok',
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    }
  }

  void _selectDate() async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: _today,
      firstDate: _today.subtract(const Duration(days: 30)),
      lastDate: _today,
    );
    _dateController.text = DateFormat('M/d/y').format(newDate ?? _actualDate);
    _actualDate = newDate ?? _actualDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Add Transaction",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  _depositExpenseSelectorWidget(context),
                ],
              ),
              CurrencyFormField(controller: _amountController),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!_isDeposit) ...[
                    _selectCategoryWidget(),
                    const SizedBox(width: 24),
                  ],
                  Expanded(
                    child: TextField(
                      onTap: () {
                        _selectDate();
                      },
                      controller: _dateController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Date'),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Cancel"),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Add Transaction'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextButton _depositExpenseSelectorWidget(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        setState(() {
          _isDeposit = !_isDeposit;
        });
      },
      style: ButtonStyle(
        backgroundColor: MaterialStatePropertyAll(
          _isDeposit
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        foregroundColor: MaterialStatePropertyAll(
          _isDeposit
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onError,
        ),
        padding: const MaterialStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
        minimumSize: const MaterialStatePropertyAll(Size(118, 42)),
      ),
      icon: Icon(_isDeposit ? Icons.arrow_upward : Icons.arrow_downward),
      label: Text(_isDeposit ? "Deposit" : "Expense"),
    );
  }

  Widget _selectCategoryWidget() {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: DropdownButton(
          value: category,
          onChanged: (value) {
            setState(() {
              category = value!;
            });
          },
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          dropdownColor: colorScheme.secondaryContainer,
          icon: const SizedBox(),
          underline: const SizedBox(),
          items: Categories.values.map<DropdownMenuItem<String>>((value) {
            return DropdownMenuItem<String>(
              value: value.toShortString(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: Categories.categoryColors(value),
                    radius: 10,
                  ),
                  const SizedBox(width: 16),
                  Text(value.toShortString()),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
