import 'package:new_expense_tracker/models/account.dart';
import 'package:new_expense_tracker/models/category.dart';
import 'package:new_expense_tracker/models/transaction.dart';
import 'package:new_expense_tracker/providers/account_provider.dart';
import 'package:new_expense_tracker/providers/transactions_provider.dart';
import 'package:new_expense_tracker/widgets/color_picker_field.dart';
import 'package:new_expense_tracker/widgets/currency_form_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddTransactionPage extends StatefulWidget {
  static const String route = '/addTransactions';
  final Function? changePage;
  final Transaction? transactionToEdit;

  const AddTransactionPage({
    super.key,
    this.changePage,
    this.transactionToEdit,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  // Providers
  late TransactionsProvider transactionsProvider;

  // Form Input Controllers
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final ValueNotifier<Color> _categoryColorNotifier = ValueNotifier<Color>(
    Colors.red,
  );

  late final Account _activeAccount;
  late Transaction? transactionToEdit;
  late DateTime _actualDate;
  late FocusNode _categoryFocusNode;
  late Future<void> _fetchFuture;

  final DateTime _today = DateTime.now();
  bool _isDeposit = true;
  Category? category;

  @override
  void initState() {
    super.initState();

    transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );

    _categoryFocusNode = FocusNode(debugLabel: 'Category Autocomplete');
    _categoryFocusNode.addListener(() {
      if (!_categoryFocusNode.hasFocus) {
        // When lose focus, check if name exist in the category List
        final String currentCategoryText = _categoryController.text;
        final bool categoryExists = transactionsProvider.categoryList.any(
          (category) =>
              category.name.toLowerCase() == currentCategoryText.toLowerCase(),
        );

        if (!categoryExists) {
          category = null;
        }
      }
    });
    _fetchFuture = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    ).fetchCategories();

    transactionToEdit = widget.transactionToEdit;
    if (transactionToEdit != null) {
      _isDeposit = transactionToEdit!.type == TransactionType.deposit;
      _amountController.text = transactionToEdit!.amount.toStringAsFixed(2);
      _dateController.text = DateFormat(
        'M/d/y',
      ).format(transactionToEdit!.date);
      _descriptionController.text = transactionToEdit!.description ?? "";
      _actualDate = transactionToEdit!.date;

      if (transactionToEdit!.type == TransactionType.spent) {
        category = transactionToEdit!.category;
        _categoryController.text = transactionToEdit!.category!.name;
        _categoryColorNotifier.value = transactionToEdit!.category!.color;
      }
    } else {
      _actualDate = _today;
      _dateController.text = DateFormat('M/d/y').format(_today);
      _amountController.text = "0.00";
      _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length),
      );
    }
    _activeAccount = Provider.of<AccountProvider>(
      context,
      listen: false,
    ).activeAccount!;
  }

  Future<void> _submitForm() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final Transaction transaction = Transaction(
      type: _isDeposit ? TransactionType.deposit : TransactionType.spent,
      amount: double.parse(_amountController.text),
      account: _activeAccount,
      date: DateFormat('M/d/y').parse(_dateController.text),
      description: _descriptionController.text,
      category: category,
    );

    if (category == null && transaction.type == TransactionType.spent) {
      debugPrint("Creating a category");
      category = Category(
        color: _categoryColorNotifier.value,
        name: _categoryController.text,
      );
      await Provider.of<TransactionsProvider>(
        context,
        listen: false,
      ).addCategory(category!);
      transaction.category = category;
    }

    if (transaction.amount <= 0.00) {
      if (mounted) {
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
    } else {
      if (transactionToEdit != null) {
        transaction.id = transactionToEdit!.id;
        transactionsProvider.editTransaction(transaction, _activeAccount);
      } else {
        transactionsProvider.addTransaction(transaction, _activeAccount);
      }

      if (widget.changePage != null) {
        widget.changePage!();
      } else {
        if (mounted) {
          Navigator.pop(context);
        }
      }
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
    return FutureBuilder(
      future: _fetchFuture,
      builder: (context, asyncSnapshot) {
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
                        transactionToEdit != null
                            ? "Edit Transaction"
                            : "Add New Transaction",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: _depositExpenseSelectorWidget(context),
                      ),
                      Align(
                        heightFactor: 1.05,
                        alignment: Alignment.bottomCenter,
                        child: CurrencyFormField(controller: _amountController),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!_isDeposit) ...[
                        // _selectCategoryWidget(),
                        Expanded(
                          child: Autocomplete<Category>(
                            textEditingController: _categoryController,
                            focusNode: _categoryFocusNode,
                            displayStringForOption: (Category category) =>
                                category.name,
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text == '') {
                                return const Iterable<Category>.empty();
                              }
                              return Provider.of<TransactionsProvider>(
                                context,
                                listen: false,
                              ).categoryList.where(
                                (category) =>
                                    category.name.toLowerCase().contains(
                                      textEditingValue.text.toLowerCase(),
                                    ),
                              );

                              // return Category.values.where((Category category) {
                              //   return category
                              //       .toShortString()
                              //       .toLowerCase()
                              //       .contains(textEditingValue.text.toLowerCase());
                              // });
                            },
                            fieldViewBuilder:
                                (
                                  BuildContext context,
                                  TextEditingController textEditingController,
                                  FocusNode focusNode,
                                  VoidCallback onFieldSubmitted,
                                ) {
                                  return TextField(
                                    controller: textEditingController,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'Category',
                                      isDense: true,
                                    ),
                                    onSubmitted: (String value) {
                                      debugPrint('String submitted: $value');
                                      onFieldSubmitted();
                                    },
                                  );
                                },
                            onSelected: (Category category) {
                              this.category = category;
                              setState(() {
                                _categoryColorNotifier.value = category.color;
                              });
                              debugPrint('Category Selected: ${category.name}');
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        ColorPickerField(colorNotifier: _categoryColorNotifier),
                      ],
                    ],
                  ),
                  TextField(
                    onTap: () {
                      _selectDate();
                    },
                    controller: _dateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Date'),
                    style: const TextStyle(fontSize: 18),
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
                        child: transactionToEdit != null
                            ? const Text('Save Changes')
                            : const Text('Add Transaction'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        backgroundColor: WidgetStatePropertyAll(
          _isDeposit
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        foregroundColor: WidgetStatePropertyAll(
          _isDeposit
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onError,
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(118, 42)),
      ),
      icon: Icon(_isDeposit ? Icons.arrow_upward : Icons.arrow_downward),
      label: Text(_isDeposit ? "Deposit" : "Expense"),
    );
  }

  // Widget _selectCategoryWidget() {
  //   final colorScheme = Theme.of(context).colorScheme;
  //   return DecoratedBox(
  //     decoration: BoxDecoration(
  //       color: colorScheme.surfaceContainerLow,
  //       borderRadius: BorderRadius.circular(50),
  //       boxShadow: [
  //         BoxShadow(
  //           color: colorScheme.shadow.withAlpha(26),
  //           spreadRadius: 1,
  //           blurRadius: 1,
  //           offset: const Offset(0, 1),
  //         ),
  //       ],
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.only(left: 20, right: 20),
  //       child: DropdownButton(
  //         value: category,
  //         onChanged: (value) {
  //           setState(() {
  //             category = value!;
  //           });
  //         },
  //         style: TextStyle(
  //           color: colorScheme.secondary,
  //           fontWeight: FontWeight.w600,
  //           fontSize: 16,
  //         ),
  //         dropdownColor: colorScheme.surfaceContainerLow,
  //         icon: const SizedBox(), // used to no show any Dropdown Icon
  //         underline:
  //             const SizedBox(), // used to no show any underline in the dropdown
  //         items: Categories.values.map<DropdownMenuItem<String>>((value) {
  //           return DropdownMenuItem<String>(
  //             value: value.toShortString(),
  //             child: Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 CircleAvatar(
  //                   backgroundColor: Categories.categoryColors(value),
  //                   radius: 10,
  //                 ),
  //                 const SizedBox(width: 16),
  //                 Text(value.toShortString()),
  //               ],
  //             ),
  //           );
  //         }).toList(),
  //       ),
  //     ),
  //   );
  // }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
