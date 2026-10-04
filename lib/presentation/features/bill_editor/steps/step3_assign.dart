import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/models/bill_item.dart';
import '../../../providers/bill_draft_controller.dart';
import '../widgets/live_summary_bar.dart';
import '../widgets/portion_dialog.dart';

class Step3Assign extends ConsumerWidget {
  const Step3Assign({super.key});

  void _showPortionDialog(
    BuildContext context,
    WidgetRef ref, {
    required String participantId,
    required String participantName,
    required BillItem item,
    required int currentPortion,
  }) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => PortionDialog(
        participantName: participantName,
        itemName: item.name,
        initialPortion: currentPortion,
      ),
    );

    if (result != null) {
      ref.read(billDraftControllerProvider.notifier).setSharePortion(
            item.id,
            participantId,
            result,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billDraftControllerProvider);
    final controller = ref.read(billDraftControllerProvider.notifier);

    final unassignedCount =
        state.items.where((i) => !state.isItemAssigned(i.id)).length;

    return Column(
      children: [
        // Status Bar Peringatan Unassigned
        if (unassignedCount > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$unassignedCount item belum dibagikan. Pastikan semua item sudah dipilih.',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Petunjuk Singkat Responsive
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.assignTitle,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                'Pilih siapa yang memakan item. Tekan lama chip untuk porsi > 1.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),

        // Daftar Item & Chips Peserta
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: state.items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = state.items[index];
              final isAssigned = state.isItemAssigned(item.id);

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isAssigned ? AppColors.borderLight : AppColors.error,
                    width: isAssigned ? 1 : 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header item: nama, qty x unit, total harga
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.quantity} × ${MoneyFormatter.format(item.unitPrice)}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                MoneyFormatter.format(item.totalPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (!isAssigned)
                                const Text(
                                  'Belum dibagi',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Deretan Chip Peserta & Tombol Semua
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Tombol "Semua"
                          ActionChip(
                            label: const Text(
                              AppStrings.assignAll,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            avatar: const Icon(Icons.done_all, size: 16),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            side: const BorderSide(color: AppColors.primary),
                            onPressed: () => controller.assignAllToItem(item.id),
                          ),

                          // Chip Tiap Peserta
                          ...state.participants.map((p) {
                            final share = state.getShare(item.id, p.id);
                            final isSelected = share != null;
                            final portion = share?.portion ?? 1;

                            return GestureDetector(
                              onLongPress: isSelected
                                  ? () => _showPortionDialog(
                                        context,
                                        ref,
                                        participantId: p.id,
                                        participantName: p.name,
                                        item: item,
                                        currentPortion: portion,
                                      )
                                  : null,
                              child: FilterChip(
                                label: Text(
                                  portion > 1 ? '${p.name} (${portion}x)' : p.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : null,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                checkmarkColor: Colors.white,
                                onSelected: (_) {
                                  controller.toggleShare(item.id, p.id);
                                },
                                avatar: isSelected && portion > 1
                                    ? const CircleAvatar(
                                        backgroundColor: Colors.white24,
                                        radius: 10,
                                        child: Icon(Icons.star, size: 12, color: Colors.white),
                                      )
                                    : null,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Live Summary Bar Sticky di Bawah
        LiveSummaryBar(state: state),
      ],
    );
  }
}
