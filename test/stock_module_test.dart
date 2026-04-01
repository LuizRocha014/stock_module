import 'package:flutter_test/flutter_test.dart';
import 'package:stock_module/config/database/stock_database_config.dart';

void main() {
  test('StockDatabaseConfig placeholder', () {
    expect(const StockDatabaseConfig(), isA<StockDatabaseConfig>());
  });
}
