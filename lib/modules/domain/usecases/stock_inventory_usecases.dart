import 'package:stock_module/modules/domain/entities/stock_entry_params.dart';
import 'package:stock_module/modules/domain/entities/stock_inventory_row_entity.dart';
import 'package:stock_module/modules/domain/repositories/stock_inventory_repository.dart';

class LoadStockInventoryUseCase {
  LoadStockInventoryUseCase(this._repository);

  final IStockInventoryRepository _repository;

  Future<List<StockInventoryRowEntity>> call({String? branchId}) =>
      _repository.loadRows(branchId: branchId);
}

class ListStockFormOptionsUseCase {
  ListStockFormOptionsUseCase(this._repository);

  final IStockInventoryRepository _repository;

  Future<({List<ProductRef> products, List<BranchRef> branches})> call() async {
    final products = await _repository.listProducts();
    final branches = await _repository.listBranches();
    return (products: products, branches: branches);
  }
}

class RegisterStockEntryUseCase {
  RegisterStockEntryUseCase(this._repository);

  final IStockInventoryRepository _repository;

  Future<StockEntryResult> call(StockEntryParams params) => _repository.registerEntry(params);
}
