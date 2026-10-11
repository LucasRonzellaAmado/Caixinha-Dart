import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/common.dart';
import '../domain/mei_limit_calculator.dart';
import 'mei_providers.dart';
import 'widgets/mei_thermometer.dart';

class MeiLimitPage extends ConsumerWidget {
  const MeiLimitPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Limite do MEI')),
      body: AsyncValueView(
        value: ref.watch(meiStatusProvider),
        data: (status) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(child: MeiThermometer(status: status)),
            const SizedBox(height: 16),
            _InfoTile(
              icon: Icons.trending_up,
              title: 'Projeção para dezembro',
              value: Money.format(status.projectedCents),
              subtitle: status.projectionExceeds
                  ? 'Se continuar nesse ritmo, você passa do limite.'
                  : 'Mantendo o ritmo atual, você fica dentro do limite.',
            ),
            _InfoTile(
              icon: Icons.savings_outlined,
              title: 'Ainda pode faturar no ano',
              value: Money.format(
                status.remainingCents < 0 ? 0 : status.remainingCents,
              ),
            ),
            _InfoTile(
              icon: Icons.calendar_month_outlined,
              title: 'Média por mês até dezembro',
              value: Money.format(status.monthlyRoomCents),
              subtitle: 'Quanto dá para faturar por mês sem estourar.',
            ),
            _InfoTile(
              icon: Icons.flag_outlined,
              title: 'Limite considerado em ${status.year}',
              value: Money.format(status.limitCents),
              subtitle: status.isProportional
                  ? 'Limite proporcional aos meses desde a abertura do MEI.'
                  : 'Você pode mudar esse valor se a lei mudar.',
              onTap: () => context.push(AppRoutes.settings),
            ),
            const SizedBox(height: 16),
            const _HowItWorks(),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = subtitle;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: text == null ? null : Text(text),
      trailing: Text(value, style: Theme.of(context).textTheme.titleSmall),
      onTap: onTap,
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'Como funciona',
      child: Text(
        'Entram na conta todas as entradas do negócio no ano (vendas e '
        'serviços). Lançamentos pessoais e pró-labore não contam. '
        'Se você abriu o MEI este ano, o limite é proporcional aos meses '
        'de atividade. Passou de 20% do limite? O desenquadramento pode '
        'valer desde janeiro, então fale com seu contador.',
      ),
    );
  }
}

extension MeiLimitLevelLabel on MeiLimitLevel {
  String get label => switch (this) {
        MeiLimitLevel.safe => 'Tranquilo',
        MeiLimitLevel.attention => 'Atenção',
        MeiLimitLevel.danger => 'Perto do limite',
        MeiLimitLevel.exceeded => 'Acima do limite',
        MeiLimitLevel.exceededBeyondTolerance => 'Muito acima do limite',
      };
}
