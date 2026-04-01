# stock_module

Pacote Flutter de **estoque** do ecossistema InOutWareApp. Mesmo desenho arquitetural do `sale_module`: camadas domain / data / presentation e registro via **`instanceManager`** (`componentes_lr`).

## Dependências

- **`componentes_lr`**: `path: ../../../Flutter_X_Components_Flutter`.
- **`get`**: controllers e telas do módulo.

## Estrutura

```
lib/
  config/
    database/          # StockDatabaseConfig (placeholder)
    di/                # initStockInstances e registradores
  modules/
    domain/
    data/
    presentation/      # StockHomePage, StockHomeController
  stock_module.dart
  presentation_export.dart
  tables_export.dart
```

## Inicialização (DI)

No app host:

```dart
import 'package:stock_module/config/di/init_instances.dart';

initStockInstances();
```

## Uso no app

```yaml
dependencies:
  stock_module:
    path: ../packages/stock_module
```

Tela inicial do módulo: `StockHomePage` (ver `presentation_export.dart`).

## Banco de dados

Implementação local ainda pendente; datasources e config de banco lançam `UnimplementedError` ou são vazios até o schema existir.

## Desenvolvimento

```bash
cd packages/stock_module
flutter pub get
dart analyze
flutter test
```
