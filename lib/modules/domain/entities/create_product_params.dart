/// Corpo de POST /api/products (DocumentaçãoAPI).
class CreateProductParams {
  CreateProductParams({
    required this.name,
    required this.sku,
    this.barcode,
    this.unitType = 'UN',
    this.isPerishable = false,
    this.salePrice = 0,
  });

  final String name;
  final String sku;
  final String? barcode;
  final String unitType;
  final bool isPerishable;
  final double salePrice;
}
