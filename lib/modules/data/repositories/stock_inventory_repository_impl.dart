import 'package:stock_module/modules/data/datasource/remote/stock_inventory_remote_datasource.dart';
import 'package:stock_module/modules/data/models/product_batch_dto.dart';
import 'package:stock_module/modules/domain/entities/create_product_params.dart';
import 'package:stock_module/modules/domain/entities/product_snapshot.dart';
import 'package:stock_module/modules/domain/entities/product_stock_detail_entity.dart';
import 'package:stock_module/modules/domain/entities/stock_entry_params.dart';
import 'package:stock_module/modules/domain/entities/stock_product_summary_entity.dart';
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
  Future<List<StockProductSummaryEntity>> loadProductSummaries({String? branchId}) async {
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

    final grouped = <String, List<ProductBatchDto>>{};
    for (final b in batches) {
      grouped.putIfAbsent(b.productId, () => []).add(b);
    }

    final summaries = <StockProductSummaryEntity>[];
    for (final entry in grouped.entries) {
      final productId = entry.key;
      final list = entry.value;
      final activeBatches = list.where((b) => b.active != false).toList();
      if (activeBatches.isEmpty) continue;

      num totalQty = 0;
      for (final b in activeBatches) {
        totalQty += b.quantity ?? 0;
      }
      if (totalQty <= 0) continue;

      final p = byId[productId];
      final name = p?.name ?? 'Produto $productId';

      num sumCost = 0;
      num sumQ = 0;
      for (final b in activeBatches) {
        final q = b.quantity ?? 0;
        final c = b.effectiveCost;
        if (c != null && q > 0) {
          sumCost += q * c;
          sumQ += q;
        }
      }
      final avgCost = sumQ > 0 ? sumCost / sumQ : null;

      DateTime? earliest;
      for (final b in activeBatches) {
        final e = b.expirationDate;
        if (e == null) continue;
        if (earliest == null || e.isBefore(earliest)) earliest = e;
      }

      summaries.add(
        StockProductSummaryEntity(
          productId: productId,
          productName: name,
          sku: p?.sku,
          barcode: p?.barcode,
          imageUrl: imageByProduct[productId],
          totalQuantity: totalQty,
          quantityLabel: _formatQty(totalQty),
          costLabel: avgCost == null ? '—' : asMoney(avgCost),
          saleLabel: asMoney(p?.salePrice),
          activeBatchCount: activeBatches.length,
          earliestExpiration: earliest,
        ),
      );
    }
    summaries.sort((a, b) => a.productName.compareTo(b.productName));
    return summaries;
  }

  @override
  Future<ProductStockDetailEntity> getProductStockDetail(String productId, {String? branchId}) async {
    final products = await _remote.fetchProducts();
    final byId = {for (final p in products) p.id: p};
    final p = byId[productId];
    final batches = await _remote.fetchProductBatches(branchId: branchId, productId: productId);

    String? imageUrl;
    try {
      imageUrl = await _remote.fetchMainProductImageUrl(productId);
    } catch (_) {
      imageUrl = null;
    }

    String asMoney(num? value) {
      if (value == null) return 'R\$ 0,00';
      final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
      return 'R\$ $fixed';
    }

    final name = p?.name ?? 'Produto $productId';
    final sorted = [...batches]..sort((a, b) {
        final ae = a.expirationDate;
        final be = b.expirationDate;
        if (ae == null && be == null) return 0;
        if (ae == null) return 1;
        if (be == null) return -1;
        return ae.compareTo(be);
      });

    final lines = <StockBatchDetailEntity>[];
    for (final b in sorted) {
      final active = b.active != false;
      final q = b.quantity;
      lines.add(
        StockBatchDetailEntity(
          batchId: b.id,
          quantity: q,
          expirationDate: b.expirationDate,
          active: active,
          quantityLabel: q == null ? '—' : _formatQty(q),
          costLabel: asMoney(b.effectiveCost),
          unitCost: b.effectiveCost,
        ),
      );
    }

    return ProductStockDetailEntity(
      productId: productId,
      productName: name,
      sku: p?.sku,
      barcode: p?.barcode,
      imageUrl: imageUrl,
      saleLabel: asMoney(p?.salePrice),
      batches: lines,
    );
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
        batchId: params.targetBatchId,
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
    double? unitCost,
  }) async {
    final body = <String, dynamic>{
      'expirationDate': expirationDate?.toUtc().toIso8601String(),
      'active': active,
    };
    if (unitCost != null) {
      body['costPrice'] = unitCost;
      body['unitCost'] = unitCost;
    }
    await _remote.putProductBatch(batchId, body);
  }

  @override
  Future<void> deleteProductBatch(String batchId) => _remote.deleteProductBatch(batchId);
}
