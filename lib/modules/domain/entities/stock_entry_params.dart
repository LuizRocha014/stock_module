class StockEntryParams {
  StockEntryParams({
    required this.productId,
    required this.branchId,
    required this.quantity,
    required this.costPrice,
    this.expirationDate,
    this.entryDate,
  });

  final String productId;
  final String branchId;
  final double quantity;
  final double costPrice;
  final DateTime? expirationDate;
  final DateTime? entryDate;
}

class StockEntryResult {
  StockEntryResult({this.batchId, this.movementId});

  final String? batchId;
  final String? movementId;
}
