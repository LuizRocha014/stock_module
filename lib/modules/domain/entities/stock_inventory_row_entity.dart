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
    required this.quantityLabel,
    required this.costLabel,
    required this.saleLabel,
  });

  final String batchId;
  final String productId;
  final String productName;
  final String? sku;
  final String? barcode;
  final String? imageUrl;
  final DateTime? expirationDate;
  final num? quantity;
  final String quantityLabel;
  final String costLabel;
  final String saleLabel;
}
