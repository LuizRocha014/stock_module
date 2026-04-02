/// Linha da lista de estoque (lote + dados agregados do produto).
class StockInventoryRowEntity {
  StockInventoryRowEntity({
    required this.batchId,
    required this.productId,
    required this.productName,
    this.sku,
    this.barcode,
    this.expirationDate,
    this.quantity,
    required this.quantityLabel,
    required this.unitOrCostLabel,
  });

  final String batchId;
  final String productId;
  final String productName;
  final String? sku;
  final String? barcode;
  final DateTime? expirationDate;
  final num? quantity;
  final String quantityLabel;
  final String unitOrCostLabel;
}
