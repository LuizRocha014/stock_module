import 'package:stock_module/modules/data/models/api_parse.dart';

class ProductBatchDto {
  ProductBatchDto({
    required this.id,
    required this.productId,
    this.branchId,
    this.quantity,
    this.expirationDate,
    this.active,
    this.costPrice,
    this.unitCost,
  });

  final String id;
  final String productId;
  final String? branchId;
  final num? quantity;
  final DateTime? expirationDate;
  final bool? active;
  final num? costPrice;
  final num? unitCost;

  factory ProductBatchDto.fromJson(Map<String, dynamic> json) {
    final m = asMap(json);
    return ProductBatchDto(
      id: mapString(m, const ['id', 'Id']) ?? '',
      productId: mapString(m, const ['productId', 'ProductId']) ?? '',
      branchId: mapString(m, const ['branchId', 'BranchId']),
      quantity: mapNum(m, const ['quantity', 'Quantity', 'currentQuantity', 'CurrentQuantity']),
      expirationDate: mapDate(m, const ['expirationDate', 'ExpirationDate']),
      active: mapValue<bool>(m, const ['active', 'Active']),
      costPrice: mapNum(m, const ['costPrice', 'CostPrice', 'averageCost', 'AverageCost']),
      unitCost: mapNum(m, const ['unitCost', 'UnitCost']),
    );
  }

  num? get effectiveCost => costPrice ?? unitCost;
}
