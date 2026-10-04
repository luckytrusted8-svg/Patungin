import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../providers/bill_draft_controller.dart';

class Step2Participants extends ConsumerStatefulWidget {
  const Step2Participants({super.key});

  @override
  ConsumerState<Step2Participants> createState() => _Step2ParticipantsState();
}

class _Step2ParticipantsState extends ConsumerState<Step2Participants> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addParticipant() {
    final text = _nameController.text.trim();
    if (text.isNotEmpty) {
      ref.read(billDraftControllerProvider.notifier).addParticipant(text);
      _nameController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billDraftControllerProvider);
    final controller = ref.read(billDraftControllerProvider.notifier);

    return Column(
      children: [
        // Input tambah nama peserta
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: AppStrings.participantName,
                        hintText: 'Contoh: Andi, Budi...',
                        prefixIcon: Icon(Icons.person_add_alt_1_outlined),
                      ),
                      onSubmitted: (_) => _addParticipant(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addParticipant,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(60, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (state.participants.length < 2)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.minParticipantsWarning,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Dropdown siapa yang bayar duluan
        if (state.participants.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              color: AppColors.primary.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.payment, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            AppStrings.paidBy,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          DropdownButton<String?>(
                            isExpanded: true,
                            underline: const SizedBox.shrink(),
                            value: state.paidByParticipantId,
                            hint: const Text(AppStrings.noOnePaidYet),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  AppStrings.noOnePaidYet,
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                              ...state.participants.map(
                                (p) => DropdownMenuItem<String?>(
                                  value: p.id,
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              controller.setPaidBy(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const Divider(height: 16),

        // Daftar Peserta Reorderable
        Expanded(
          child: state.participants.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.group_outlined,
                            size: 56,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum Ada Peserta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tambahkan minimal 2 orang untuk membagi tagihan ini secara adil.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  buildDefaultDragHandles: false,
                  itemCount: state.participants.length,
                  onReorderItem: (oldIndex, newIndex) =>
                      controller.reorderParticipants(oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final p = state.participants[index];
                    final isPayer = state.paidByParticipantId == p.id;

                    return Card(
                      key: ValueKey('participant_${p.id}'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isPayer ? AppColors.accent : AppColors.primary,
                              foregroundColor: Colors.white,
                              child: Text(
                                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          p.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isPayer) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Talangi',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    index == 0
                                        ? 'Prioritas penerima pecahan Rp 1'
                                        : 'Peserta #${index + 1}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                  ),
                                ],
                              ),
                            ),
                            if (state.participants.length > 1) ...[
                              if (index > 0)
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                                  tooltip: 'Pindah ke atas',
                                  onPressed: () => controller.moveParticipantUp(index),
                                  visualDensity: VisualDensity.compact,
                                ),
                              if (index < state.participants.length - 1)
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                                  tooltip: 'Pindah ke bawah',
                                  onPressed: () => controller.moveParticipantDown(index),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                              onPressed: () => controller.removeParticipant(p.id),
                              visualDensity: VisualDensity.compact,
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
