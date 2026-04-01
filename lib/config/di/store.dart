import 'package:componentes_lr/componentes_lr.dart';
import 'package:stock_module/modules/data/store/module_version_store.dart';

void initStoreInstances() {
  instanceManager.registerLazySingleton<ModuleVersionStore>(
    () => ModuleVersionStore(),
  );
}
