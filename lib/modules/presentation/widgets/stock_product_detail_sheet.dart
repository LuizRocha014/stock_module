import 'package:flutter/material.dart';
import 'package:stock_module/modules/domain/entities/product_stock_detail_entity.dart';
import 'package:stock_module/modules/domain/entities/stock_inventory_row_entity.dart';
import 'package:stock_module/modules/presentation/design/iw_app_shell.dart';
import 'package:stock_module/modules/presentation/design/iw_design.dart';
import 'package:stock_module/modules/presentation/design/iw_pills.dart';

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
  final StockInventoryRowEntity Function(
      ProductStockDetailEntity detail, StockBatchDetailEntity batch) rowForBatch;
  final Future<void> Function(StockInventoryRowEntity row) onEditBatch;
  final Future<void> Function(StockInventoryRowEntity row) onDeleteBatch;

  @override
  State<StockProductDetailSheet> createState() =>
      _StockProductDetailSheetState();
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

  IwValidityTone _toneFor(DateTime? d) {
    if (d == null) return IwValidityTone.muted;
    final days = d.difference(DateTime.now()).inDays;
    if (days <= 7) return IwValidityTone.warn;
    return IwValidityTone.ok;
  }

  String _validity(DateTime? d) {
    if (d == null) return 'Sem validade';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Center(
                    child: Text('${snap.error}',
                        style: const TextStyle(color: IwColors.error)),
                  ),
                );
              }
              final d = snap.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
                    child: IwSheetHeader(
                      title: d.productName,
                      onClose: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _ProductMeta(detail: d),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'Lotes',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: IwColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: IwColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${d.batches.length}',
                            style: const TextStyle(
                              fontFamily: 'RobotoMono',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: IwColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: d.batches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final b = d.batches[i];
                        final row = widget.rowForBatch(d, b);
                        return _BatchCard(
                          batch: b,
                          tone: _toneFor(b.expirationDate),
                          validity: _validity(b.expirationDate),
                          onEdit: () async {
                            await widget.onEditBatch(row);
                            if (context.mounted) _reload();
                          },
                          onDelete: () async {
                            await widget.onDeleteBatch(row);
                            if (context.mounted) _reload();
                          },
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

class _ProductMeta extends StatelessWidget {
  const _ProductMeta({required this.detail});
  final ProductStockDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if ((detail.sku ?? '').trim().isNotEmpty) {
      chips.add(_MetaChip(icon: Icons.tag, label: detail.sku!));
    }
    if ((detail.barcode ?? '').trim().isNotEmpty) {
      chips.add(_MetaChip(
          icon: Icons.qr_code_2_outlined, label: detail.barcode!));
    }
    chips.add(_MetaChip(
        icon: Icons.local_offer_outlined, label: detail.saleLabel));

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: chips,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: IwColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: IwColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: IwColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: IwColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.batch,
    required this.tone,
    required this.validity,
    required this.onEdit,
    required this.onDelete,
  });

  final StockBatchDetailEntity batch;
  final IwValidityTone tone;
  final String validity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: IwColors.surface,
        borderRadius: BorderRadius.circular(IwRadius.md),
        border: Border.all(color: IwColors.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      batch.quantityLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: IwColors.onSurface,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: batch.active
                            ? IwColors.successContainer
                            : IwColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        batch.active ? 'Ativo' : 'Inativo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: batch.active
                              ? IwColors.onSuccessContainer
                              : IwColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IwValidityPill(tone: tone, label: validity),
                    Text(
                      'Custo: ${batch.costLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: IwColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar lote',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
            color: IwColors.onSurfaceVariant,
          ),
          IconButton(
            tooltip: 'Excluir lote',
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
            color: IwColors.error,
          ),
        ],
      ),
    );
  }
}
