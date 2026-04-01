import 'package:stock_module/config/di/datasources.dart';
import 'package:stock_module/config/di/repositories.dart';
import 'package:stock_module/config/di/store.dart';
import 'package:stock_module/config/di/usecases.dart';

void initStockInstances() {
  initDataSourceInstances();
  initRepositoryInstances();
  initUseCasesInstances();
  initStoreInstances();
}
