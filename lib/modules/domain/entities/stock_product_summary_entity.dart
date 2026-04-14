/// Uma linha na lista de estoque: **um produto** (soma dos lotes ativos).
class StockProductSummaryEntity {
  StockProductSummaryEntity({
    required this.productId,
    required this.productName,
    this.sku,
    this.barcode,
    this.imageUrl,
    required this.totalQuantity,
    required this.quantityLabel,
    required this.costLabel,
    required this.saleLabel,
    required this.activeBatchCount,
    this.earliestExpiration,
  });

  final String productId;
  final String productName;
  final String? sku;
  final String? barcode;
  final String? imageUrl;

  /// Soma das quantidades dos lotes **ativos**.
  final num totalQuantity;
  final String quantityLabel;

  /// Custo médio ponderado pelos lotes ativos, ou `—`.
  final String costLabel;
  final String saleLabel;

  final int activeBatchCount;

  /// Menor validade entre lotes ativos que tenham data (para filtro / exibição).
  final DateTime? earliestExpiration;
}
