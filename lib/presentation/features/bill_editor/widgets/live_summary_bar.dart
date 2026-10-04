import 'package:flutter/material.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../providers/bill_draft_controller.dart';

class LiveSummaryBar extends StatelessWidget {
  final BillDraftState state;

  const LiveSummaryBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.participants.isEmpty) return const SizedBox.shrink();

    // Hitung alokasi sementara dari item yang sudah di-assign
    final personTotals = <String, int>{};
    for (final p in state.participants) {
      personTotals[p.id] = 0;
    }

    for (final item in state.items) {
      final itemShares = state.shares.where((s) => s.itemId == item.id).toList();
      if (itemShares.isEmpty) continue;

      final totalPortion = itemShares.fold<int>(0, (s, share) => s + share.portion);
      if (totalPortion <= 0) continue;

      for (final share in itemShares) {
        if (personTotals.containsKey(share.participantId)) {
          final shareAmount = (item.totalPrice * share.portion) ~/ totalPortion;
          personTotals[share.participantId] =
              (personTotals[share.participantId] ?? 0) + shareAmount;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.tempTotalLive,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              Text(
                'Subtotal: ${MoneyFormatter.format(state.subtotal)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: state.participants.map((p) {
                final amount = personTotals[p.id] ?? 0;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        MoneyFormatter.format(amount),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
