import 'package:componentes_lr/componentes_lr.dart';
import 'package:stock_module/config/database/stock_database_config.dart';
import 'package:stock_module/modules/data/datasource/local/module_version_local_datasource.dart';
import 'package:stock_module/modules/data/datasource/remote/module_version_remote_datasource.dart';

void initDataSourceInstances() {
  instanceManager.registerLazySingleton<StockDatabaseConfig>(
    () => const StockDatabaseConfig(),
  );

  instanceManager.registerLazySingleton<IModuleVersionRemoteDataSource>(
    () => ModuleVersionRemoteDataSource(),
  );

  instanceManager.registerLazySingleton<IModuleVersionLocalDataSource>(
    () => ModuleVersionLocalDataSource(
      database: instanceManager.get<StockDatabaseConfig>(),
    ),
  );
}
