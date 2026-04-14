/// Detalhe de estoque de um produto: todos os lotes (ativos e inativos).
class StockBatchDetailEntity {
  StockBatchDetailEntity({
    required this.batchId,
    this.quantity,
    this.expirationDate,
    required this.active,
    required this.quantityLabel,
    required this.costLabel,
    this.unitCost,
  });

  final String batchId;
  final num? quantity;
  final DateTime? expirationDate;
  final bool active;
  final String quantityLabel;
  final String costLabel;
  final num? unitCost;
}

class ProductStockDetailEntity {
  ProductStockDetailEntity({
    required this.productId,
    required this.productName,
    this.sku,
    this.barcode,
    this.imageUrl,
    required this.saleLabel,
    required this.batches,
  });

  final String productId;
  final String productName;
  final String? sku;
  final String? barcode;
  final String? imageUrl;
  final String saleLabel;
  final List<StockBatchDetailEntity> batches;
}
