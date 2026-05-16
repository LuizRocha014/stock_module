import 'dart:io';

import 'package:componentes_lr/componentes_lr.dart' show isDesktopFormFactor;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_module/modules/domain/entities/stock_product_summary_entity.dart';
import 'package:stock_module/modules/presentation/controllers/stock_home_controller.dart';
import 'package:stock_module/modules/presentation/design/iw_app_shell.dart';
import 'package:stock_module/modules/presentation/design/iw_design.dart';
import 'package:stock_module/modules/presentation/design/iw_pills.dart';

class StockHomePage extends StatefulWidget {
  const StockHomePage({super.key});

  @override
  State<StockHomePage> createState() => _StockHomePageState();
}

class _StockHomePageState extends State<StockHomePage> {
  late final StockHomeController controller =
      Get.put(StockHomeController(), tag: 'stock_home');
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    Get.delete<StockHomeController>(tag: 'stock_home');
    super.dispose();
  }

  IwValidityTone _validityTone(StockProductSummaryEntity r) {
    final d = r.earliestExpiration;
    if (d == null) return IwValidityTone.muted;
    final days = d.difference(DateTime.now()).inDays;
    if (days <= 7) return IwValidityTone.warn;
    return IwValidityTone.ok;
  }

  IwStockState _stockState(StockProductSummaryEntity r) {
    // Heurística pragmática: usa o quantity textual quando numérico baixo.
    final qty = _parseQuantityForBar(r.quantityLabel);
    if (qty == null) return IwStockState.ok;
    if (qty <= 0) return IwStockState.crit;
    if (qty <= 15) return IwStockState.warn;
    return IwStockState.ok;
  }

  double? _parseQuantityForBar(String label) {
    final m = RegExp(r'[\d.,]+').firstMatch(label);
    if (m == null) return null;
    return double.tryParse(m.group(0)!.replaceAll(',', '.'));
  }

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktopFormFactor;
    return IwModulePage(
      onBack: () => Get.back(),
      breadcrumb: desktop
          ? const IwBreadcrumbData(
              icon: Icons.inventory_2_outlined,
              label: 'Estoque',
              sub: 'Inventário',
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!desktop) ...[
            Obx(
              () => _MobilePageTitle(
                count: controller.filteredRows.length,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _Toolbar(
            searchCtrl: _searchCtrl,
            onSearchChanged: (v) => controller.filterQuery.value = v,
            onScanner: () => controller.openBarcodeScanner(context),
            onAddEntry: () => controller.openAddEntrySheet(context),
            onNewProduct: () => controller.openCreateProductSheet(context),
            onRefresh: controller.refreshInventory,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.rows.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final err = controller.errorMessage.value;
              if (err != null && controller.rows.isEmpty) {
                return _ErrorState(
                  message: err,
                  onRetry: controller.refreshInventory,
                );
              }
              if (controller.rows.isEmpty) {
                return const _EmptyState(
                  message:
                      'Nenhum lote listado. Registre uma entrada ou atualize a lista.',
                );
              }
              final list = controller.filteredRows;
              if (list.isEmpty) {
                return const _EmptyState(
                  message: 'Nenhum item corresponde ao filtro.',
                );
              }
              return RefreshIndicator(
                onRefresh: controller.refreshInventory,
                child: desktop
                    ? _DesktopList(
                        controller: controller,
                        rows: list,
                        validityTone: _validityTone,
                        stockState: _stockState,
                      )
                    : _MobileList(
                        controller: controller,
                        rows: list,
                        validityTone: _validityTone,
                        stockState: _stockState,
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MobilePageTitle extends StatelessWidget {
  const _MobilePageTitle({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estoque',
          style: TextStyle(
            fontSize: 22,
            height: 28 / 22,
            fontWeight: FontWeight.w600,
            color: IwColors.onSurface,
            letterSpacing: -0.11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Inventário · $count produtos',
          style: const TextStyle(
            fontSize: 13,
            color: IwColors.onSurfaceVariant,
            height: 18 / 13,
          ),
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onScanner,
    required this.onAddEntry,
    required this.onNewProduct,
    required this.onRefresh,
  });

  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onScanner;
  final VoidCallback onAddEntry;
  final VoidCallback onNewProduct;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 260, maxWidth: 520),
          child: TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: 'Filtrar por nome, SKU, código de barras…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Ler código de barras',
                icon: const Icon(Icons.photo_camera_outlined),
                onPressed: onScanner,
              ),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        FilledButton.icon(
          onPressed: onAddEntry,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Adicionar entrada'),
        ),
        OutlinedButton.icon(
          onPressed: onNewProduct,
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Novo produto'),
        ),
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton.filledTonal(
            tooltip: 'Atualizar',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }
}

class _DesktopList extends StatelessWidget {
  const _DesktopList({
    required this.controller,
    required this.rows,
    required this.validityTone,
    required this.stockState,
  });

  final StockHomeController controller;
  final List<StockProductSummaryEntity> rows;
  final IwValidityTone Function(StockProductSummaryEntity) validityTone;
  final IwStockState Function(StockProductSummaryEntity) stockState;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: IwColors.surface,
        borderRadius: BorderRadius.circular(IwRadius.lg),
        border: Border.all(color: IwColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DesktopHeader(),
          Expanded(
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: IwColors.outlineVariant),
              itemBuilder: (ctx, i) {
                final r = rows[i];
                return _DesktopRow(
                  row: r,
                  validity: controller.formatValidity(r.earliestExpiration),
                  validityTone: validityTone(r),
                  stockState: stockState(r),
                  onTap: () => controller.openProductDetailSheet(context, r),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      color: IwColors.surfaceContainerLow,
      child: Row(
        children: const [
          SizedBox(width: 72),
          Expanded(flex: 17, child: _HeaderText('Produto')),
          Expanded(flex: 10, child: _HeaderText('Validade')),
          Expanded(
            flex: 10,
            child: _HeaderText('Quantidade', align: TextAlign.right),
          ),
          Expanded(
            flex: 10,
            child: _HeaderText('Preço', align: TextAlign.right),
          ),
          SizedBox(width: 56),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.label, {this.align = TextAlign.left});
  final String label;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      textAlign: align,
      style: const TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: IwColors.onSurfaceVariant,
        letterSpacing: 0.66,
        height: 1,
      ),
    );
  }
}

class _DesktopRow extends StatelessWidget {
  const _DesktopRow({
    required this.row,
    required this.validity,
    required this.validityTone,
    required this.stockState,
    required this.onTap,
  });

  final StockProductSummaryEntity row;
  final String validity;
  final IwValidityTone validityTone;
  final IwStockState stockState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Row(
          children: [
            _Thumb(imageUrl: row.imageUrl, size: 48, radius: 12),
            const SizedBox(width: 24),
            Expanded(
              flex: 17,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    row.productName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: IwColors.onSurface,
                      height: 18 / 14,
                      letterSpacing: -0.07,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if ((row.sku ?? '').isNotEmpty) row.sku!,
                      if ((row.barcode ?? '').isNotEmpty) row.barcode!,
                    ].join(' · '),
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 11,
                      color: IwColors.onSurfaceVariant,
                      letterSpacing: 0.22,
                      height: 16 / 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 10,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IwValidityPill(tone: validityTone, label: validity),
              ),
            ),
            Expanded(
              flex: 10,
              child: Align(
                alignment: Alignment.centerRight,
                child: _QtyBlock(label: row.quantityLabel, state: stockState),
              ),
            ),
            Expanded(
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    row.saleLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: IwColors.onSurface,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'custo ${row.costLabel}',
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 11,
                      color: IwColors.onSurfaceVariant,
                      letterSpacing: 0.22,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 56,
              child: IconButton(
                tooltip: 'Editar',
                onPressed: onTap,
                icon: const Icon(Icons.edit_outlined),
                color: IwColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyBlock extends StatelessWidget {
  const _QtyBlock({required this.label, required this.state});
  final String label;
  final IwStockState state;

  @override
  Widget build(BuildContext context) {
    // Heurística: rótulo "12 UN" / "12,5 KG"; quebra em valor / unidade.
    final match = RegExp(r'^([\d.,]+)\s*(\S*)').firstMatch(label.trim());
    final value = match?.group(1) ?? label;
    final unit = match?.group(2) ?? '';
    final fill = switch (state) {
      IwStockState.warn => IwColors.warning,
      IwStockState.crit => IwColors.error,
      IwStockState.ok => IwColors.success,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: IwColors.onSurface,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            children: [
              TextSpan(text: value),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: IwColors.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(color: IwColors.surfaceContainerHigh),
                FractionallySizedBox(
                  widthFactor: state == IwStockState.warn
                      ? 0.25
                      : state == IwStockState.crit
                          ? 0.0
                          : 0.85,
                  child: Container(color: fill),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileList extends StatelessWidget {
  const _MobileList({
    required this.controller,
    required this.rows,
    required this.validityTone,
    required this.stockState,
  });

  final StockHomeController controller;
  final List<StockProductSummaryEntity> rows;
  final IwValidityTone Function(StockProductSummaryEntity) validityTone;
  final IwStockState Function(StockProductSummaryEntity) stockState;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final r = rows[i];
        return _MobileCard(
          row: r,
          validity: controller.formatValidity(r.earliestExpiration),
          validityTone: validityTone(r),
          stockState: stockState(r),
          onTap: () => controller.openProductDetailSheet(context, r),
        );
      },
    );
  }
}

class _MobileCard extends StatelessWidget {
  const _MobileCard({
    required this.row,
    required this.validity,
    required this.validityTone,
    required this.stockState,
    required this.onTap,
  });

  final StockProductSummaryEntity row;
  final String validity;
  final IwValidityTone validityTone;
  final IwStockState stockState;
  final VoidCallback onTap;

  Color get _stripeColor => switch (stockState) {
        IwStockState.warn => IwColors.warning,
        IwStockState.crit => IwColors.error,
        IwStockState.ok => IwColors.success,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: IwColors.surface,
      borderRadius: BorderRadius.circular(IwRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(IwRadius.lg),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(IwRadius.lg),
            border: Border.all(color: IwColors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    Container(width: 3, color: _stripeColor),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(13, 12, 14, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Thumb(
                                    imageUrl: row.imageUrl,
                                    size: 60,
                                    radius: 14),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        row.productName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: IwColors.onSurface,
                                          height: 1.25,
                                          letterSpacing: -0.075,
                                        ),
                                      ),
                                      if ((row.sku ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          row.sku!,
                                          style: const TextStyle(
                                            fontFamily: 'RobotoMono',
                                            fontSize: 11,
                                            color: IwColors.onSurfaceVariant,
                                            letterSpacing: 0.44,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      row.saleLabel,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: IwColors.onSurface,
                                        fontFeatures: [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'VENDA',
                                      style: TextStyle(
                                        fontFamily: 'RobotoMono',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: IwColors.onSurfaceVariant,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: IwColors.surfaceContainerLow,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _MetaBit(
                            icon: switch (validityTone) {
                              IwValidityTone.warn => Icons.schedule_outlined,
                              IwValidityTone.ok =>
                                Icons.event_available_outlined,
                              IwValidityTone.muted => Icons.all_inclusive,
                            },
                            label: validity,
                            color: switch (validityTone) {
                              IwValidityTone.warn => IwColors.warning,
                              IwValidityTone.ok => IwColors.success,
                              IwValidityTone.muted => IwColors.onSurfaceVariant,
                            },
                          ),
                          _MetaBit(
                            icon: Icons.inventory_2_outlined,
                            label: row.quantityLabel,
                            color: IwColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onTap,
                      icon: const Icon(Icons.edit_outlined),
                      color: IwColors.onSurfaceVariant,
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaBit extends StatelessWidget {
  const _MetaBit(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.imageUrl, this.size = 42, this.radius = 8});
  final String? imageUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final value = imageUrl?.trim();
    if (value == null || value.isEmpty) return _placeholder();
    final isHttp = value.startsWith('http://') || value.startsWith('https://');
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: isHttp
          ? Image.network(
              value,
              height: size,
              width: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : Image.file(
              File(value),
              height: size,
              width: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            IwColors.surfaceContainer,
            IwColors.surfaceContainerHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const Icon(
        Icons.image_outlined,
        size: 22,
        color: IwColors.onSurfaceVariant,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 56, color: IwColors.outline),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: IwColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: IwColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: IwColors.onSurface),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
