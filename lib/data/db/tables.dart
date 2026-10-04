import 'package:drift/drift.dart';

@DataClassName('BillEntry')
class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get subtotal => integer()();
  IntColumn get taxAmount => integer().withDefault(const Constant(0))();
  IntColumn get serviceAmount => integer().withDefault(const Constant(0))();
  IntColumn get discountAmount => integer().withDefault(const Constant(0))();
  IntColumn get total => integer()();
  TextColumn get receiptImagePath => text().nullable()();
  TextColumn get rawOcrText => text().nullable()();
  TextColumn get paidByParticipantId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ParticipantEntry')
class Participants extends Table {
  TextColumn get id => text()();
  TextColumn get billId => text().references(Bills, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BillItemEntry')
class BillItems extends Table {
  TextColumn get id => text()();
  TextColumn get billId => text().references(Bills, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get unitPrice => integer()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  IntColumn get totalPrice => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ItemShareEntry')
class ItemShares extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(BillItems, #id, onDelete: KeyAction.cascade)();
  TextColumn get participantId => text().references(Participants, #id, onDelete: KeyAction.cascade)();
  IntColumn get portion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {itemId, participantId}
      ];
}

@DataClassName('SavedFriendEntry')
class SavedFriends extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}
