import 'dart:io';

import 'package:componentes_lr/componentes_lr.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_module/modules/domain/entities/stock_inventory_row_entity.dart';
import 'package:stock_module/modules/presentation/controllers/stock_home_controller.dart';

class StockHomePage extends StatefulWidget {
  const StockHomePage({super.key});

  @override
  State<StockHomePage> createState() => _StockHomePageState();
}

class _StockHomePageState extends State<StockHomePage> {
  late final StockHomeController controller =
      Get.put(StockHomeController(), tag: 'stock_home');

  @override
  void dispose() {
    Get.delete<StockHomeController>(tag: 'stock_home');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AdaptiveModulePage(
      title: 'Estoque',
      onBack: () => Get.back(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Filtrar por nome, SKU, código de barras…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Ler código de barras',
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: () => controller.openBarcodeScanner(context),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            onChanged: (v) => controller.filterQuery.value = v,
          ),
          const SizedBox(height: 12),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.openAddEntrySheet(context),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Adicionar entrada'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.openCreateProductSheet(context),
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('Novo produto'),
                ),
                IconButton.filledTonal(
                  tooltip: 'Atualizar',
                  onPressed:
                      controller.isLoading.value ? null : controller.refreshInventory,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
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
                return Center(
                  child: Text(
                    'Nenhum lote listado. Registre uma entrada ou atualize a lista.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                );
              }
              final list = controller.filteredRows;
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    'Nenhum item corresponde ao filtro.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.refreshInventory,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _TableHeader(scheme: scheme),
                    const Divider(height: 1),
                    ...list.map(
                      (r) => _StockRow(
                        row: r,
                        validity: controller.formatValidity(r.expirationDate),
                        onEdit: () => controller.openEditSheet(context, r),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: isDesktopFormFactor ? 14 : 13,
      color: scheme.primary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 58),
          Expanded(flex: 3, child: Text('Nome', style: style)),
          Expanded(flex: 2, child: Text('Validade', style: style)),
          Expanded(flex: 2, child: Text('Quantidade', style: style)),
          Expanded(flex: 2, child: Text('Custo', style: style)),
          Expanded(flex: 2, child: Text('Venda', style: style)),
          SizedBox(
            width: 48,
            child: Icon(Icons.edit_outlined, size: 18, color: scheme.primary),
          ),
        ],
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({
    required this.row,
    required this.validity,
    required this.onEdit,
  });

  final StockInventoryRowEntity row;
  final String validity;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cell = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ProductImageThumb(imageUrl: row.imageUrl),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.productName,
              style: cell?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(flex: 2, child: Text(validity, style: cell)),
          Expanded(
            flex: 2,
            child: Text(
              row.quantityLabel,
              style: cell,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(flex: 2, child: Text(row.costLabel, style: cell)),
          Expanded(flex: 2, child: Text(row.saleLabel, style: cell)),
          SizedBox(
            width: 48,
            child: IconButton(
              tooltip: 'Editar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: const Icon(Icons.edit_outlined, size: 22),
              onPressed: onEdit,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImageThumb extends StatelessWidget {
  const _ProductImageThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final value = imageUrl?.trim();
    final scheme = Theme.of(context).colorScheme;
    if (value == null || value.isEmpty) {
      return _placeholder(scheme);
    }
    final isHttp = value.startsWith('http://') || value.startsWith('https://');
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: isHttp
          ? Image.network(
              value,
              height: 42,
              width: 42,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(scheme),
            )
          : Image.file(
              File(value),
              height: 42,
              width: 42,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(scheme),
            ),
    );
    return SizedBox(width: 42, height: 42, child: image);
  }

  Widget _placeholder(ColorScheme scheme) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: scheme.surfaceContainerHighest,
      ),
      child: Icon(Icons.image_outlined, size: 20, color: scheme.onSurfaceVariant),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurface),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}
