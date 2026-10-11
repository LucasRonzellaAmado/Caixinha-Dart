import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/money.dart';

class MoneyText extends StatelessWidget {
  const MoneyText(
    this.cents, {
    super.key,
    this.style,
    this.colored = false,
    this.showSign = false,
  });

  final int cents;
  final TextStyle? style;
  final bool colored;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = !colored || cents == 0
        ? null
        : cents > 0
            ? scheme.income
            : scheme.expense;
    final text = showSign ? Money.formatSigned(cents) : Money.format(cents);
    return Semantics(
      label: cents < 0 ? 'menos ${Money.format(-cents)}' : Money.format(cents),
      excludeSemantics: true,
      child: Text(
        text,
        style: (style ?? DefaultTextStyle.of(context).style).copyWith(
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
