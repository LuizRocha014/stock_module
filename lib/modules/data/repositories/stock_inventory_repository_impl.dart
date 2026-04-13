import 'package:stock_module/modules/data/datasource/remote/stock_inventory_remote_datasource.dart';
import 'package:stock_module/modules/domain/entities/create_product_params.dart';
import 'package:stock_module/modules/domain/entities/product_snapshot.dart';
import 'package:stock_module/modules/domain/entities/stock_entry_params.dart';
import 'package:stock_module/modules/domain/entities/stock_inventory_row_entity.dart';
import 'package:stock_module/modules/domain/repositories/stock_inventory_repository.dart';

class StockInventoryRepositoryImpl implements IStockInventoryRepository {
  StockInventoryRepositoryImpl(this._remote);

  final IStockInventoryRemoteDataSource _remote;

  @override
  Future<List<BranchRef>> listBranches() async {
    final list = await _remote.fetchBranches();
    return list.map((b) => BranchRef(id: b.id, name: b.name)).toList();
  }

  @override
  Future<List<ProductRef>> listProducts() async {
    final list = await _remote.fetchProducts();
    return list
        .map((p) => ProductRef(id: p.id, name: p.name, unitType: p.unitType))
        .toList();
  }

  @override
  Future<List<StockInventoryRowEntity>> loadRows({String? branchId}) async {
    final products = await _remote.fetchProducts();
    final byId = {for (final p in products) p.id: p};
    final batches = await _remote.fetchProductBatches(branchId: branchId);
    final productIds = batches.map((e) => e.productId).toSet();
    final imageByProduct = <String, String?>{};
    await Future.wait(
      productIds.map((id) async {
        try {
          imageByProduct[id] = await _remote.fetchMainProductImageUrl(id);
        } catch (_) {
          imageByProduct[id] = null;
        }
      }),
    );

    String asMoney(num? value) {
      if (value == null) return 'R\$ 0,00';
      final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
      return 'R\$ $fixed';
    }

    final rows = <StockInventoryRowEntity>[];
    for (final b in batches) {
      if (b.active == false) continue;
      final p = byId[b.productId];
      final name = p?.name ?? 'Produto ${b.productId}';
      final q = b.quantity;
      rows.add(
        StockInventoryRowEntity(
          batchId: b.id,
          productId: b.productId,
          productName: name,
          sku: p?.sku,
          barcode: p?.barcode,
          imageUrl: imageByProduct[b.productId],
          expirationDate: b.expirationDate,
          quantity: q,
          quantityLabel: q == null ? '—' : _formatQty(q),
          costLabel: asMoney(b.effectiveCost),
          saleLabel: asMoney(p?.salePrice),
        ),
      );
    }
    rows.sort((a, b) => a.productName.compareTo(b.productName));
    return rows;
  }

  String _formatQty(num q) {
    if (q == q.roundToDouble()) return q.toInt().toString();
    return q.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Future<StockEntryResult> registerEntry(StockEntryParams params) async {
    final res = await _remote.postInventoryEntry(
      StockEntryRequest(
        productId: params.productId,
        branchId: params.branchId,
        quantity: params.quantity,
        costPrice: params.costPrice,
        expirationDate: params.expirationDate,
        entryDate: params.entryDate,
      ),
    );
    return StockEntryResult(batchId: res.batchId, movementId: res.movementId);
  }

  @override
  Future<ProductRef> createProduct(CreateProductParams p) async {
    final dto = await _remote.postProduct({
      'name': p.name,
      'sku': p.sku,
      'barcode': p.barcode,
      'unitType': p.unitType,
      'isPerishable': p.isPerishable,
      'salePrice': p.salePrice,
    });
    return ProductRef(id: dto.id, name: dto.name, unitType: dto.unitType);
  }

  @override
  Future<void> addProductImage(
    String productId, {
    required String imageUrl,
    bool isMain = true,
  }) {
    return _remote.postProductImage(
      productId,
      url: imageUrl,
      isMain: isMain,
    );
  }

  @override
  Future<ProductSnapshot> getProductSnapshot(String productId) async {
    final p = await _remote.fetchProduct(productId);
    return ProductSnapshot(
      id: p.id,
      name: p.name,
      sku: p.sku,
      barcode: p.barcode,
      unitType: p.unitType ?? 'UN',
      isPerishable: p.isPerishable ?? false,
      salePrice: (p.salePrice ?? 0).toDouble(),
      active: p.active ?? true,
    );
  }

  @override
  Future<void> applyProductSnapshot(ProductSnapshot s) async {
    await _remote.putProduct(s.id, {
      'name': s.name,
      'sku': s.sku ?? '',
      'barcode': s.barcode,
      'unitType': s.unitType,
      'isPerishable': s.isPerishable,
      'salePrice': s.salePrice,
      'active': s.active,
    });
  }

  @override
  Future<void> updateProductBatch({
    required String batchId,
    DateTime? expirationDate,
    required bool active,
  }) async {
    await _remote.putProductBatch(batchId, {
      'expirationDate': expirationDate?.toUtc().toIso8601String(),
      'active': active,
    });
  }
}
