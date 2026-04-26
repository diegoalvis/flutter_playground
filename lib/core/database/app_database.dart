import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Products extends Table {
  IntColumn get internalId => integer().autoIncrement()();
  IntColumn get remoteId => integer().unique()();
  TextColumn get title => text()();
  RealColumn get price => real()();
  TextColumn get description => text()();
  TextColumn get thumbnail => text()();
}

@DriftDatabase(tables: [Products])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'products_db');
  }
}
