import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../domain/mei_limit_calculator.dart';

Color meiLevelColor(ColorScheme scheme, MeiLimitLevel level) => switch (level) {
      MeiLimitLevel.safe => scheme.income,
      MeiLimitLevel.attention => scheme.warning,
      MeiLimitLevel.danger ||
      MeiLimitLevel.exceeded ||
      MeiLimitLevel.exceededBeyondTolerance =>
        scheme.expense,
    };

String meiLevelMessage(MeiLimitStatus status) => switch (status.level) {
      MeiLimitLevel.safe when status.projectionExceeds =>
        'No ritmo atual você passa do limite até dezembro. Fique de olho.',
      MeiLimitLevel.safe => 'Tudo tranquilo, você está dentro do limite.',
      MeiLimitLevel.attention =>
        'Atenção: você já usou boa parte do limite do ano.',
      MeiLimitLevel.danger =>
        'Cuidado: você está muito perto do limite do MEI.',
      MeiLimitLevel.exceeded =>
        'Você passou do limite. Até 20% acima, o desenquadramento vale a '
            'partir do ano que vem. Converse com seu contador.',
      MeiLimitLevel.exceededBeyondTolerance =>
        'Você passou mais de 20% do limite. Procure seu contador o quanto antes.',
    };

class MeiThermometer extends StatelessWidget {
  const MeiThermometer({super.key, required this.status});

  final MeiLimitStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = meiLevelColor(theme.colorScheme, status.level);
    final percent = status.usagePercent;
    final summary =
        '${Money.format(status.revenueCents)} de ${Money.format(status.limitCents)}';

    return Semantics(
      container: true,
      label: 'Limite do MEI em ${status.year}',
      value: '$percent por cento usado. $summary. ${meiLevelMessage(status)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Faturamento ${status.year}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                '$percent%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: status.usage.clamp(0, 1).toDouble(),
              minHeight: 14,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 8),
          Text(summary, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            meiLevelMessage(status),
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
