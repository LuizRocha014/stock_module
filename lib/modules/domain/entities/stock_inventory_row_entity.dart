/// Linha da lista de estoque (lote + dados agregados do produto).
class StockInventoryRowEntity {
  StockInventoryRowEntity({
    required this.batchId,
    required this.productId,
    required this.productName,
    this.sku,
    this.barcode,
    this.imageUrl,
    this.expirationDate,
    this.quantity,
    /// Custo unitário do lote (mesma base do [costLabel]).
    this.unitCost,
    required this.quantityLabel,
    required this.costLabel,
    required this.saleLabel,
    this.batchActive = true,
  });

  final String batchId;
  final String productId;
  final String productName;
  final String? sku;
  final String? barcode;
  final String? imageUrl;
  final DateTime? expirationDate;
  final num? quantity;
  final num? unitCost;
  final String quantityLabel;
  final String costLabel;
  final String saleLabel;

  /// Estado do lote ao abrir o editor (Switch “Lote ativo”).
  final bool batchActive;
}
