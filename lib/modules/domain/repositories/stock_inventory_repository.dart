import 'package:stock_module/modules/domain/entities/create_product_params.dart';
import 'package:stock_module/modules/domain/entities/product_snapshot.dart';
import 'package:stock_module/modules/domain/entities/stock_entry_params.dart';
import 'package:stock_module/modules/domain/entities/stock_inventory_row_entity.dart';

abstract class IStockInventoryRepository {
  Future<List<StockInventoryRowEntity>> loadRows({String? branchId});

  Future<List<BranchRef>> listBranches();

  Future<List<ProductRef>> listProducts();

  Future<StockEntryResult> registerEntry(StockEntryParams params);

  Future<ProductRef> createProduct(CreateProductParams params);

  Future<void> addProductImage(
    String productId, {
    required String imageUrl,
    bool isMain = true,
  });

  Future<ProductSnapshot> getProductSnapshot(String productId);

  Future<void> applyProductSnapshot(ProductSnapshot snapshot);

  Future<void> updateProductBatch({
    required String batchId,
    DateTime? expirationDate,
    required bool active,
  });
}

class BranchRef {
  BranchRef({required this.id, required this.name});
  final String id;
  final String name;
}

class ProductRef {
  ProductRef({required this.id, required this.name, this.unitType});
  final String id;
  final String name;
  final String? unitType;
}
