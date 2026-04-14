import 'package:componentes_lr/componentes_lr.dart';
import 'package:stock_module/modules/domain/repositories/module_version_repository.dart';
import 'package:stock_module/modules/domain/repositories/stock_inventory_repository.dart';
import 'package:stock_module/modules/domain/usecases/module_version_usecase.dart';
import 'package:stock_module/modules/domain/usecases/stock_inventory_usecases.dart';

void initUseCasesInstances() {
  instanceManager.registerLazySingleton<IModuleVersionUseCase>(
    () => ModuleVersionUseCase(
      moduleVersionRepository: instanceManager.get<IModuleVersionRepository>(),
    ),
  );

  instanceManager.registerLazySingleton<LoadStockInventoryUseCase>(
    () => LoadStockInventoryUseCase(
      instanceManager.get<IStockInventoryRepository>(),
    ),
  );

  instanceManager.registerLazySingleton<GetProductStockDetailUseCase>(
    () => GetProductStockDetailUseCase(
      instanceManager.get<IStockInventoryRepository>(),
    ),
  );

  instanceManager.registerLazySingleton<ListStockFormOptionsUseCase>(
    () => ListStockFormOptionsUseCase(
      instanceManager.get<IStockInventoryRepository>(),
    ),
  );

  instanceManager.registerLazySingleton<RegisterStockEntryUseCase>(
    () => RegisterStockEntryUseCase(
      instanceManager.get<IStockInventoryRepository>(),
    ),
  );

  instanceManager.registerLazySingleton<DeleteProductBatchUseCase>(
    () => DeleteProductBatchUseCase(
      instanceManager.get<IStockInventoryRepository>(),
    ),
  );
}
