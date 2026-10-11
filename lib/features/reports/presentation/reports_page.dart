import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/money_text.dart';
import '../../transactions/domain/finance_calculator.dart';
import '../domain/report_data.dart';
import 'report_providers.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  bool _exporting = false;

  Future<void> _pickCustom(ReportPeriod current) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      initialDateRange: DateTimeRange(
        start: current.start,
        end: current.end.subtract(const Duration(days: 1)),
      ),
    );
    if (range == null) return;
    ref.read(reportPeriodProvider.notifier).custom(range.start, range.end);
  }

  Future<void> _export(ReportData data, {required bool pdf}) async {
    setState(() => _exporting = true);
    final exporter = ref.read(reportExporterProvider);
    final result =
        pdf ? await exporter.sharePdf(data) : await exporter.shareCsv(data);
    if (!mounted) return;
    setState(() => _exporting = false);
    if (result case Err(:final failure)) showFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(reportPeriodProvider);
    final notifier = ref.read(reportPeriodProvider.notifier);
    final presets = <String, ReportPeriod>{
      'Este mês': ReportPeriodNotifier.thisMonth(),
      'Mês passado': ReportPeriodNotifier.lastMonth(),
      'Este ano': ReportPeriodNotifier.thisYear(),
      'Ano passado': ReportPeriodNotifier.lastYear(),
    };
    final isPreset = presets.containsValue(period);

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final MapEntry(:key, :value) in presets.entries)
                ChoiceChip(
                  label: Text(key),
                  selected: period == value,
                  onSelected: (_) => notifier.select(value),
                ),
              ChoiceChip(
                avatar: const Icon(Icons.date_range),
                label: const Text('Escolher datas'),
                selected: !isPreset,
                onSelected: (_) => _pickCustom(period),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Período: ${periodLabel(period)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          AsyncValueView(
            value: ref.watch(reportDataProvider(period)),
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummarySection(
                  title: 'Negócio',
                  summary: data.businessSummary,
                  showProfit: true,
                ),
                const SizedBox(height: 12),
                _SummarySection(
                  title: 'Pessoal',
                  summary: data.personalSummary,
                ),
                const SizedBox(height: 8),
                Text(
                  '${data.transactions.length} lançamentos no período.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _exporting || data.transactions.isEmpty
                      ? null
                      : () => _export(data, pdf: true),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Enviar PDF'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _exporting || data.transactions.isEmpty
                      ? null
                      : () => _export(data, pdf: false),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Enviar planilha (CSV)'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'O PDF é ótimo para mandar ao contador. '
                  'O CSV abre no Excel ou Google Planilhas.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.title,
    required this.summary,
    this.showProfit = false,
  });

  final String title;
  final FinanceSummary summary;
  final bool showProfit;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, int cents) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              MoneyText(cents),
            ],
          ),
        );

    return SectionCard(
      title: title,
      child: Column(
        children: [
          row('Entradas', summary.incomeCents),
          row('Saídas', summary.expenseCents),
          if (showProfit) ...[
            row('Lucro', summary.profitCents),
            row('Pró-labore', summary.proLaboreCents),
          ],
          const Divider(),
          row(showProfit ? 'Sobra no caixa' : 'Saldo', summary.balanceCents),
        ],
      ),
    );
  }
}
