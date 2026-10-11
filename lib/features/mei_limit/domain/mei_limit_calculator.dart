import '../../../core/fiscal/fiscal_rules.dart';

enum MeiLimitLevel { safe, attention, danger, exceeded, exceededBeyondTolerance }

final class MeiLimitStatus {
  const MeiLimitStatus({
    required this.year,
    required this.revenueCents,
    required this.limitCents,
    required this.projectedCents,
    required this.monthlyRoomCents,
    required this.level,
    required this.isProportional,
  });

  final int year;
  final int revenueCents;
  final int limitCents;
  final int projectedCents;
  final int monthlyRoomCents;
  final MeiLimitLevel level;
  final bool isProportional;

  double get usage => limitCents <= 0 ? 0 : revenueCents / limitCents;

  int get usagePercent => (usage * 100).floor();

  int get remainingCents => limitCents - revenueCents;

  bool get projectionExceeds => projectedCents > limitCents;
}

class MeiLimitCalculator {
  const MeiLimitCalculator(this.rules);

  final FiscalRules rules;

  MeiLimitStatus calculate({
    required int revenueCents,
    required int annualLimitCents,
    required DateTime now,
    DateTime? openingDate,
  }) {
    final year = now.year;
    final limit = rules.effectiveAnnualLimit(
      annualLimitCents: annualLimitCents,
      year: year,
      openingDate: openingDate,
    );
    final opening =
        openingDate != null && openingDate.year == year ? openingDate : null;
    final periodStart =
        opening != null ? DateTime.utc(year, opening.month) : DateTime.utc(year);
    final today = DateTime.utc(year, now.month, now.day);
    final endOfYear = DateTime.utc(year, 12, 31);
    final elapsedDays = today.difference(periodStart).inDays + 1;
    final totalDays = endOfYear.difference(periodStart).inDays + 1;
    final projected = elapsedDays <= 0
        ? revenueCents
        : revenueCents * totalDays ~/ elapsedDays;
    final monthsLeft = 12 - now.month + 1;
    final remaining = limit - revenueCents;

    return MeiLimitStatus(
      year: year,
      revenueCents: revenueCents,
      limitCents: limit,
      projectedCents: projected,
      monthlyRoomCents: remaining <= 0 ? 0 : remaining ~/ monthsLeft,
      level: levelFor(revenueCents: revenueCents, limitCents: limit),
      isProportional: opening != null,
    );
  }

  MeiLimitLevel levelFor({required int revenueCents, required int limitCents}) {
    if (limitCents <= 0) return MeiLimitLevel.safe;
    final usage = revenueCents / limitCents;
    if (usage > rules.toleranceThreshold) {
      return MeiLimitLevel.exceededBeyondTolerance;
    }
    if (usage > 1) return MeiLimitLevel.exceeded;
    if (usage >= rules.dangerThreshold) return MeiLimitLevel.danger;
    if (usage >= rules.attentionThreshold) return MeiLimitLevel.attention;
    return MeiLimitLevel.safe;
  }
}
