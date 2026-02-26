import 'package:drift/drift.dart';

class UploadStates extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get localId => text()(); // PhotoManager ID
  TextColumn get hash => text()();
  IntColumn get size => integer()();

  TextColumn get status => text()(); 
  TextColumn get serverAssetId => text().nullable()();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}