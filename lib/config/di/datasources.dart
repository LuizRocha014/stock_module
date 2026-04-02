import 'package:componentes_lr/componentes_lr.dart';
import 'package:stock_module/config/database/stock_database_config.dart';
import 'package:stock_module/modules/data/datasource/local/module_version_local_datasource.dart';
import 'package:stock_module/modules/data/datasource/remote/module_version_remote_datasource.dart';
import 'package:stock_module/modules/data/datasource/remote/stock_inventory_remote_datasource.dart';
import 'package:stock_module/modules/data/stock_api_settings.dart';

void initDataSourceInstances() {
  instanceManager.registerLazySingleton<StockDatabaseConfig>(
    () => const StockDatabaseConfig(),
  );

  instanceManager.registerLazySingleton<StockApiSettings>(
    () => StockApiSettings(
      baseUrl: const String.fromEnvironment(
        'STOCK_API_BASE',
        defaultValue: 'https://localhost:7001',
      ),
      accessToken: _stockApiTokenFromEnvironment(),
    ),
  );

  instanceManager.registerLazySingleton<IModuleVersionRemoteDataSource>(
    () => ModuleVersionRemoteDataSource(),
  );

  instanceManager.registerLazySingleton<IStockInventoryRemoteDataSource>(
    () => StockInventoryRemoteDataSource(
      settings: instanceManager.get<StockApiSettings>(),
    ),
  );

  instanceManager.registerLazySingleton<IModuleVersionLocalDataSource>(
    () => ModuleVersionLocalDataSource(
      database: instanceManager.get<StockDatabaseConfig>(),
    ),
  );
}

String? _stockApiTokenFromEnvironment() {
  const t = String.fromEnvironment('STOCK_API_TOKEN');
  return t.isEmpty ? null : t;
}
