import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/calculator/settlement_calculator.dart';
import '../../domain/calculator/split_calculator.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/bill_item.dart';
import '../../domain/models/complete_bill.dart';
import '../../domain/models/item_share.dart';
import '../../domain/models/participant.dart';
import '../../domain/models/person_result.dart';
import '../../domain/models/settlement.dart';
import '../../domain/parser/parsed_receipt.dart';

class BillDraftState {
  final int currentStep;
  final String? existingBillId;
  final String title;
  final DateTime createdAt;
  final List<BillItem> items;
  final List<Participant> participants;
  final List<ItemShare> shares;
  final String? paidByParticipantId;

  // Extra costs
  final int taxAmount;
  final bool isTaxPercent;
  final int taxPercent; // basis points (10% = 1000)

  final int serviceAmount;
  final bool isServicePercent;
  final int servicePercent; // basis points (5% = 500)

  final int discountAmount;
  final bool isDiscountPercent;
  final int discountPercent; // basis points

  final int? manualReceiptTotal;
  final String? receiptImagePath;
  final String? rawOcrText;

  const BillDraftState({
    this.currentStep = 0,
    this.existingBillId,
    this.title = 'Makan Bersama',
    required this.createdAt,
    this.items = const [],
    this.participants = const [],
    this.shares = const [],
    this.paidByParticipantId,
    this.taxAmount = 0,
    this.isTaxPercent = false,
    this.taxPercent = 1000, // default 10%
    this.serviceAmount = 0,
    this.isServicePercent = false,
    this.servicePercent = 500, // default 5%
    this.discountAmount = 0,
    this.isDiscountPercent = false,
    this.discountPercent = 0,
    this.manualReceiptTotal,
    this.receiptImagePath,
    this.rawOcrText,
  });

  int get subtotal => items.fold<int>(0, (sum, i) => sum + i.totalPrice);

  int get calculatedTotal =>
      subtotal + taxAmount + serviceAmount - discountAmount;

  int get receiptTotal => manualReceiptTotal ?? calculatedTotal;

  Bill toBill() {
    return Bill(
      id: existingBillId ?? IdGenerator.generate(),
      title: title.trim().isEmpty ? 'Makan Bersama' : title.trim(),
      createdAt: createdAt,
      subtotal: subtotal,
      taxAmount: taxAmount,
      serviceAmount: serviceAmount,
      discountAmount: discountAmount,
      total: receiptTotal,
      paidByParticipantId: paidByParticipantId,
      receiptImagePath: receiptImagePath,
      rawOcrText: rawOcrText,
    );
  }

  CompleteBill toCompleteBill() {
    final bill = toBill();
    return CompleteBill(
      bill: bill,
      participants: participants,
      items: items,
      shares: shares,
    );
  }

  SplitValidation get validation => SplitCalculator.validate(
        bill: toBill(),
        items: items,
        shares: shares,
      );

  List<PersonResult> get results {
    if (participants.isEmpty) return const [];
    return SplitCalculator.calculate(
      bill: toBill(),
      participants: participants,
      items: items,
      shares: shares,
    );
  }

  List<Settlement> get settlements {
    return SettlementCalculator.calculateSinglePayer(
      results: results,
      paidByParticipantId: paidByParticipantId,
    );
  }

  bool isItemAssigned(String itemId) {
    return shares.any((s) => s.itemId == itemId);
  }

  ItemShare? getShare(String itemId, String participantId) {
    return shares
        .where((s) => s.itemId == itemId && s.participantId == participantId)
        .firstOrNull;
  }

  BillDraftState copyWith({
    int? currentStep,
    String? existingBillId,
    String? title,
    DateTime? createdAt,
    List<BillItem>? items,
    List<Participant>? participants,
    List<ItemShare>? shares,
    String? paidByParticipantId,
    bool clearPaidBy = false,
    int? taxAmount,
    bool? isTaxPercent,
    int? taxPercent,
    int? serviceAmount,
    bool? isServicePercent,
    int? servicePercent,
    int? discountAmount,
    bool? isDiscountPercent,
    int? discountPercent,
    int? manualReceiptTotal,
    bool clearManualTotal = false,
    String? receiptImagePath,
    String? rawOcrText,
  }) {
    return BillDraftState(
      currentStep: currentStep ?? this.currentStep,
      existingBillId: existingBillId ?? this.existingBillId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      participants: participants ?? this.participants,
      shares: shares ?? this.shares,
      paidByParticipantId: clearPaidBy
          ? null
          : (paidByParticipantId ?? this.paidByParticipantId),
      taxAmount: taxAmount ?? this.taxAmount,
      isTaxPercent: isTaxPercent ?? this.isTaxPercent,
      taxPercent: taxPercent ?? this.taxPercent,
      serviceAmount: serviceAmount ?? this.serviceAmount,
      isServicePercent: isServicePercent ?? this.isServicePercent,
      servicePercent: servicePercent ?? this.servicePercent,
      discountAmount: discountAmount ?? this.discountAmount,
      isDiscountPercent: isDiscountPercent ?? this.isDiscountPercent,
      discountPercent: discountPercent ?? this.discountPercent,
      manualReceiptTotal: clearManualTotal
          ? null
          : (manualReceiptTotal ?? this.manualReceiptTotal),
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
    );
  }
}

class BillDraftController extends StateNotifier<BillDraftState> {
  BillDraftController() : super(BillDraftState(createdAt: DateTime.now()));

  void resetDraft() {
    state = BillDraftState(createdAt: DateTime.now());
  }

  void loadFromCompleteBill(CompleteBill completeBill) {
    state = BillDraftState(
      currentStep: 0,
      existingBillId: completeBill.bill.id,
      title: completeBill.bill.title,
      createdAt: completeBill.bill.createdAt,
      items: completeBill.items,
      participants: completeBill.participants,
      shares: completeBill.shares,
      paidByParticipantId: completeBill.bill.paidByParticipantId,
      taxAmount: completeBill.bill.taxAmount,
      serviceAmount: completeBill.bill.serviceAmount,
      discountAmount: completeBill.bill.discountAmount,
      manualReceiptTotal: completeBill.bill.total,
      receiptImagePath: completeBill.bill.receiptImagePath,
      rawOcrText: completeBill.bill.rawOcrText,
    );
  }

  void loadFromParsedReceipt(ParsedReceipt receipt, {String? imagePath}) {
    final billId = IdGenerator.generate();
    final newItems = <BillItem>[];

    for (int i = 0; i < receipt.items.length; i++) {
      final pItem = receipt.items[i];
      newItems.add(
        BillItem.create(
          id: IdGenerator.generate(),
          billId: billId,
          name: pItem.name,
          unitPrice: pItem.unitPrice,
          quantity: pItem.quantity,
          sortOrder: i,
        ),
      );
    }

    state = state.copyWith(
      existingBillId: billId,
      items: newItems,
      taxAmount: receipt.tax ?? 0,
      serviceAmount: receipt.service ?? 0,
      discountAmount: receipt.discount ?? 0,
      manualReceiptTotal: receipt.total,
      receiptImagePath: imagePath,
      rawOcrText: receipt.rawText,
    );
  }

  void setStep(int step) {
    if (step >= 0 && step <= 4) {
      state = state.copyWith(currentStep: step);
    }
  }

  void nextStep() {
    if (state.currentStep < 4) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void addItem({
    required String name,
    required int unitPrice,
    required int quantity,
  }) {
    final billId = state.existingBillId ?? IdGenerator.generate();
    final newItem = BillItem.create(
      id: IdGenerator.generate(),
      billId: billId,
      name: name.trim(),
      unitPrice: unitPrice,
      quantity: quantity,
      sortOrder: state.items.length,
    );

    final updated = [...state.items, newItem];
    state = state.copyWith(
      existingBillId: billId,
      items: updated,
    );
    _recalculatePercents();
  }

  void updateItem({
    required String id,
    required String name,
    required int unitPrice,
    required int quantity,
  }) {
    final updated = state.items.map((item) {
      if (item.id == id) {
        return item.copyWith(
          name: name.trim(),
          unitPrice: unitPrice,
          quantity: quantity,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: updated);
    _recalculatePercents();
  }

  void removeItem(String id) {
    final updatedItems = state.items.where((i) => i.id != id).toList();
    final updatedShares = state.shares.where((s) => s.itemId != id).toList();
    state = state.copyWith(
      items: updatedItems,
      shares: updatedShares,
    );
    _recalculatePercents();
  }

  void addParticipant(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    // Cek nama kembar dan berikan penanda unik otomatis bila perlu
    String uniqueName = trimmed;
    final existingNames = state.participants.map((p) => p.name).toSet();
    if (existingNames.contains(uniqueName)) {
      int suffix = 2;
      while (existingNames.contains('$uniqueName ($suffix)')) {
        suffix++;
      }
      uniqueName = '$uniqueName ($suffix)';
    }

    final billId = state.existingBillId ?? IdGenerator.generate();
    final newParticipant = Participant(
      id: IdGenerator.generate(),
      billId: billId,
      name: uniqueName,
      sortOrder: state.participants.length,
    );

    state = state.copyWith(
      existingBillId: billId,
      participants: [...state.participants, newParticipant],
    );
  }

  void removeParticipant(String id) {
    final updatedParticipants =
        state.participants.where((p) => p.id != id).toList();
    // Bersihkan seluruh share milik peserta ini
    final updatedShares =
        state.shares.where((s) => s.participantId != id).toList();

    final clearPaid = state.paidByParticipantId == id;

    state = state.copyWith(
      participants: updatedParticipants,
      shares: updatedShares,
      clearPaidBy: clearPaid,
    );
  }

  void reorderParticipants(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.participants.length) return;
    var targetIndex = newIndex;
    if (targetIndex >= state.participants.length) {
      targetIndex = state.participants.length - 1;
    }
    if (targetIndex < 0) targetIndex = 0;
    if (oldIndex == targetIndex) return;

    final list = List<Participant>.from(state.participants);
    final item = list.removeAt(oldIndex);
    list.insert(targetIndex, item);

    final reordered = List<Participant>.generate(
      list.length,
      (i) => list[i].copyWith(sortOrder: i),
    );

    state = state.copyWith(participants: reordered);
  }

  void moveParticipantUp(int index) {
    if (index > 0 && index < state.participants.length) {
      reorderParticipants(index, index - 1);
    }
  }

  void moveParticipantDown(int index) {
    if (index >= 0 && index < state.participants.length - 1) {
      reorderParticipants(index, index + 1);
    }
  }

  void setPaidBy(String? participantId) {
    state = state.copyWith(
      paidByParticipantId: participantId,
      clearPaidBy: participantId == null,
    );
  }

  void toggleShare(String itemId, String participantId) {
    final existing = state.getShare(itemId, participantId);
    if (existing != null) {
      // Hapus share
      state = state.copyWith(
        shares: state.shares
            .where((s) => !(s.itemId == itemId && s.participantId == participantId))
            .toList(),
      );
    } else {
      // Tambah share porsi 1
      final newShare = ItemShare(
        id: IdGenerator.generate(),
        itemId: itemId,
        participantId: participantId,
        portion: 1,
      );
      state = state.copyWith(shares: [...state.shares, newShare]);
    }
  }

  void assignAllToItem(String itemId) {
    final otherShares = state.shares.where((s) => s.itemId != itemId).toList();
    final newShares = state.participants.map((p) {
      final existing = state.getShare(itemId, p.id);
      return ItemShare(
        id: existing?.id ?? IdGenerator.generate(),
        itemId: itemId,
        participantId: p.id,
        portion: existing?.portion ?? 1,
      );
    }).toList();

    state = state.copyWith(shares: [...otherShares, ...newShares]);
  }

  void clearItemShares(String itemId) {
    state = state.copyWith(
      shares: state.shares.where((s) => s.itemId != itemId).toList(),
    );
  }

  void setSharePortion(String itemId, String participantId, int portion) {
    if (portion <= 0) {
      toggleShare(itemId, participantId);
      return;
    }

    final existing = state.getShare(itemId, participantId);
    if (existing != null) {
      final updated = state.shares.map((s) {
        if (s.itemId == itemId && s.participantId == participantId) {
          return s.copyWith(portion: portion);
        }
        return s;
      }).toList();
      state = state.copyWith(shares: updated);
    } else {
      final newShare = ItemShare(
        id: IdGenerator.generate(),
        itemId: itemId,
        participantId: participantId,
        portion: portion,
      );
      state = state.copyWith(shares: [...state.shares, newShare]);
    }
  }

  // --- Biaya Tambahan ---
  void setTaxMode(bool isPercent) {
    state = state.copyWith(isTaxPercent: isPercent);
    _recalculatePercents();
  }

  void setTaxNominal(int amount) {
    state = state.copyWith(
      isTaxPercent: false,
      taxAmount: amount < 0 ? 0 : amount,
    );
  }

  void setTaxPercent(int percentBasisPoints) {
    final nominal = SplitCalculator.percentToAmount(
      state.subtotal,
      percentBasisPoints,
    );
    state = state.copyWith(
      isTaxPercent: true,
      taxPercent: percentBasisPoints,
      taxAmount: nominal,
    );
  }

  void setServiceMode(bool isPercent) {
    state = state.copyWith(isServicePercent: isPercent);
    _recalculatePercents();
  }

  void setServiceNominal(int amount) {
    state = state.copyWith(
      isServicePercent: false,
      serviceAmount: amount < 0 ? 0 : amount,
    );
  }

  void setServicePercent(int percentBasisPoints) {
    final nominal = SplitCalculator.percentToAmount(
      state.subtotal,
      percentBasisPoints,
    );
    state = state.copyWith(
      isServicePercent: true,
      servicePercent: percentBasisPoints,
      serviceAmount: nominal,
    );
  }

  void setDiscountMode(bool isPercent) {
    state = state.copyWith(isDiscountPercent: isPercent);
    _recalculatePercents();
  }

  void setDiscountNominal(int amount) {
    final safeAmount = amount < 0 ? 0 : amount;
    state = state.copyWith(
      isDiscountPercent: false,
      discountAmount: safeAmount,
    );
  }

  void setDiscountPercent(int percentBasisPoints) {
    final nominal = SplitCalculator.percentToAmount(
      state.subtotal,
      percentBasisPoints,
    );
    state = state.copyWith(
      isDiscountPercent: true,
      discountPercent: percentBasisPoints,
      discountAmount: nominal,
    );
  }

  void setReceiptTotal(int? total) {
    state = state.copyWith(
      manualReceiptTotal: total,
      clearManualTotal: total == null,
    );
  }

  void _recalculatePercents() {
    int newTax = state.taxAmount;
    if (state.isTaxPercent) {
      newTax = SplitCalculator.percentToAmount(state.subtotal, state.taxPercent);
    }

    int newService = state.serviceAmount;
    if (state.isServicePercent) {
      newService = SplitCalculator.percentToAmount(state.subtotal, state.servicePercent);
    }

    int newDiscount = state.discountAmount;
    if (state.isDiscountPercent) {
      newDiscount = SplitCalculator.percentToAmount(state.subtotal, state.discountPercent);
    }

    state = state.copyWith(
      taxAmount: newTax,
      serviceAmount: newService,
      discountAmount: newDiscount,
    );
  }
}

final billDraftControllerProvider =
    StateNotifierProvider<BillDraftController, BillDraftState>((ref) {
  return BillDraftController();
});
