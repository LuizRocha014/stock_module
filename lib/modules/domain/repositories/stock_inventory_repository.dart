import 'package:stock_module/modules/domain/entities/create_product_params.dart';
import 'package:stock_module/modules/domain/entities/product_snapshot.dart';
import 'package:stock_module/modules/domain/entities/product_stock_detail_entity.dart';
import 'package:stock_module/modules/domain/entities/stock_entry_params.dart';
import 'package:stock_module/modules/domain/entities/stock_product_summary_entity.dart';

abstract class IStockInventoryRepository {
  /// Lista **um item por produto** (quantidades somadas dos lotes ativos).
  Future<List<StockProductSummaryEntity>> loadProductSummaries({String? branchId});

  /// Todos os lotes do produto (ativos e inativos), para tela de detalhe.
  Future<ProductStockDetailEntity> getProductStockDetail(String productId, {String? branchId});

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
    double? unitCost,
  });

  /// Remove o lote do estoque (`DELETE /api/productbatches/{id}`).
  Future<void> deleteProductBatch(String batchId);
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
