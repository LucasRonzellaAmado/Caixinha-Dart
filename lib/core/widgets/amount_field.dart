import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/money.dart';

class CentsInputFormatter extends TextInputFormatter {
  static const _maxDigits = 12;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return TextEditingValue.empty;
    if (digits.length > _maxDigits) digits = digits.substring(0, _maxDigits);
    final text = Money.format(int.parse(digits), symbol: false);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.label = 'Valor',
    this.autofocus = false,
    this.large = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final bool large;
  final ValueChanged<String>? onSubmitted;

  static int centsOf(TextEditingController controller) =>
      Money.fromDigits(controller.text);

  static String textFor(int cents) =>
      cents <= 0 ? '' : Money.format(cents, symbol: false);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CentsInputFormatter(),
      ],
      style: large
          ? textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600)
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'R\$ ',
        hintText: '0,00',
      ),
      onSubmitted: onSubmitted,
    );
  }
}
