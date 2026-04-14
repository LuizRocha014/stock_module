import 'package:flutter/material.dart';
import 'package:stock_module/modules/domain/entities/product_stock_detail_entity.dart';
import 'package:stock_module/modules/domain/entities/stock_inventory_row_entity.dart';

/// Detalhes do produto no estoque: lotes (ativo / validade / qtd) e ações por lote.
class StockProductDetailSheet extends StatefulWidget {
  const StockProductDetailSheet({
    super.key,
    required this.loadDetail,
    required this.rowForBatch,
    required this.onEditBatch,
    required this.onDeleteBatch,
  });

  final Future<ProductStockDetailEntity> Function() loadDetail;
  final StockInventoryRowEntity Function(ProductStockDetailEntity detail, StockBatchDetailEntity batch)
      rowForBatch;
  final Future<void> Function(StockInventoryRowEntity row) onEditBatch;
  final Future<void> Function(StockInventoryRowEntity row) onDeleteBatch;

  @override
  State<StockProductDetailSheet> createState() => _StockProductDetailSheetState();
}

class _StockProductDetailSheetState extends State<StockProductDetailSheet> {
  late Future<ProductStockDetailEntity> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadDetail();
  }

  void _reload() {
    setState(() {
      _future = widget.loadDetail();
    });
  }

  String _validity(DateTime? d) {
    if (d == null) return 'Sem data';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: maxH,
          child: FutureBuilder<ProductStockDetailEntity>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '${snap.error}',
                    style: TextStyle(color: scheme.error),
                  ),
                );
              }
              final d = snap.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.productName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((d.sku ?? '').trim().isNotEmpty)
                          Text('SKU: ${d.sku}', style: Theme.of(context).textTheme.bodySmall),
                        if ((d.barcode ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Código: ${d.barcode}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                        const SizedBox(height: 4),
                        Text('Venda: ${d.saleLabel}', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Text(
                          'Lotes (${d.batches.length})',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: d.batches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final b = d.batches[i];
                        final row = widget.rowForBatch(d, b);
                        return Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            b.quantityLabel,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(width: 8),
                                          Chip(
                                            label: Text(
                                              b.active ? 'Ativo' : 'Inativo',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            visualDensity: VisualDensity.compact,
                                            backgroundColor: b.active
                                                ? scheme.primaryContainer
                                                : scheme.surfaceContainerHighest,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Validade: ${_validity(b.expirationDate)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        'Custo: ${b.costLabel}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Editar lote',
                                  icon: const Icon(Icons.edit_outlined, size: 22),
                                  onPressed: () async {
                                    await widget.onEditBatch(row);
                                    if (context.mounted) _reload();
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Excluir lote',
                                  icon: Icon(Icons.delete_outline, size: 22, color: scheme.error),
                                  onPressed: () async {
                                    await widget.onDeleteBatch(row);
                                    if (context.mounted) _reload();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
