import 'package:stock_module/modules/data/models/api_parse.dart';

class ProductDto {
  ProductDto({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    this.unitType,
    this.totalStock,
    this.salePrice,
    this.isPerishable,
    this.active,
  });

  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final String? unitType;
  final num? totalStock;
  final num? salePrice;
  final bool? isPerishable;
  final bool? active;

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    final m = asMap(json);
    return ProductDto(
      id: mapString(m, const ['id', 'Id']) ?? '',
      name: mapString(m, const ['name', 'Name']) ?? '',
      sku: mapString(m, const ['sku', 'Sku']),
      barcode: mapString(m, const ['barcode', 'Barcode']),
      unitType: mapString(m, const ['unitType', 'UnitType']),
      totalStock: mapNum(m, const ['totalStock', 'TotalStock']),
      salePrice: mapNum(m, const ['salePrice', 'SalePrice']),
      isPerishable: mapValue<bool>(m, const ['isPerishable', 'IsPerishable']),
      active: mapValue<bool>(m, const ['active', 'Active']),
    );
  }
}
