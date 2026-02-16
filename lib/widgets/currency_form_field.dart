import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CurrencyFormField extends StatefulWidget {
  final TextEditingController controller;

  const CurrencyFormField({super.key, required this.controller});

  @override
  State<CurrencyFormField> createState() => _CurrencyFormFieldState();
}

class _CurrencyFormFieldState extends State<CurrencyFormField> {
  @override
  void initState() {
    widget.controller.addListener(() {
      setState(() {
        _moveCursorToEnd();
      });
    });
    super.initState();
  }

  void _moveCursorToEnd() {
    final text = widget.controller.text;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: AutoSizeTextField(
        controller: widget.controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: false),
        inputFormatters: [MyCurrencyInputFormatter()],
        fullwidth: true,
        minFontSize: 32,
        maxLines: 1,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl, // Right to left
        style: Theme.of(context).textTheme.displayLarge!.copyWith(
              fontSize: 62,
            ),
        decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.attach_money,
              size: Theme.of(context).textTheme.displayMedium!.fontSize,
            ),
            contentPadding: const EdgeInsets.all(20)),
        onTap: _moveCursorToEnd,
      ),
    );
  }
}

class MyCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(".", "");
    double numericValue = double.tryParse(newText) ?? 0.0;
    String formattedValue = (numericValue / 100).toStringAsFixed(2);
    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}
