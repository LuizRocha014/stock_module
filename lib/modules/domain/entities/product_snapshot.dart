/// Dados do produto para edição (alinhado ao PUT /api/products/{id}).
class ProductSnapshot {
  const ProductSnapshot({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    this.unitType = 'UN',
    this.isPerishable = false,
    this.salePrice = 0,
    this.active = true,
  });

  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final String unitType;
  final bool isPerishable;
  final double salePrice;
  final bool active;

  ProductSnapshot copyWith({
    String? id,
    String? name,
    String? sku,
    String? barcode,
    String? unitType,
    bool? isPerishable,
    double? salePrice,
    bool? active,
  }) {
    return ProductSnapshot(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      unitType: unitType ?? this.unitType,
      isPerishable: isPerishable ?? this.isPerishable,
      salePrice: salePrice ?? this.salePrice,
      active: active ?? this.active,
    );
  }
}
