import 'package:componentes_lr/componentes_lr.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_module/modules/data/datasource/remote/stock_inventory_remote_datasource.dart';
import 'package:stock_module/modules/domain/entities/stock_inventory_row_entity.dart';
import 'package:stock_module/modules/domain/repositories/stock_inventory_repository.dart';
import 'package:stock_module/modules/domain/usecases/stock_inventory_usecases.dart';
import 'package:stock_module/modules/presentation/widgets/stock_add_entry_sheet.dart';
import 'package:stock_module/modules/presentation/widgets/barcode_scanner_sheet.dart';
import 'package:stock_module/modules/presentation/widgets/stock_create_product_sheet.dart';
import 'package:stock_module/modules/presentation/widgets/stock_edit_sheet.dart';

class StockHomeController extends GetxController {
  final rows = <StockInventoryRowEntity>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final filterQuery = ''.obs;

  LoadStockInventoryUseCase get _loadUseCase => instanceManager.get<LoadStockInventoryUseCase>();
  ListStockFormOptionsUseCase get _formOptionsUseCase =>
      instanceManager.get<ListStockFormOptionsUseCase>();
  RegisterStockEntryUseCase get _registerUseCase => instanceManager.get<RegisterStockEntryUseCase>();
  IStockInventoryRepository get _repo => instanceManager.get<IStockInventoryRepository>();

  List<StockInventoryRowEntity> get filteredRows {
    filterQuery.value;
    final q = filterQuery.value.trim().toLowerCase();
    if (q.isEmpty) return rows.toList();
    return rows.where((r) {
      if (r.productName.toLowerCase().contains(q)) return true;
      if ((r.sku ?? '').toLowerCase().contains(q)) return true;
      if ((r.barcode ?? '').toLowerCase().contains(q)) return true;
      if (formatValidity(r.expirationDate).toLowerCase().contains(q)) return true;
      if (r.quantityLabel.toLowerCase().contains(q)) return true;
      if (r.costLabel.toLowerCase().contains(q)) return true;
      if (r.saleLabel.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    refreshInventory();
  }

  Future<void> refreshInventory() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final list = await _loadUseCase();
      rows.assignAll(list);
    } on StockInventoryApiException catch (e) {
      errorMessage.value = e.message;
      rows.clear();
    } catch (e) {
      errorMessage.value = e.toString();
      rows.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openAddEntrySheet(BuildContext context) async {
    try {
      final opts = await _formOptionsUseCase();
      if (!context.mounted) return;
      if (opts.branches.isEmpty) {
        _snack(
          context,
          'Nenhuma filial disponível. É necessária uma filial para registrar entrada.',
        );
        return;
      }
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) {
          return StockAddEntrySheet(
            products: opts.products,
            branches: opts.branches,
            onCreateProduct: (p, {imagePath}) async {
              final created = await _repo.createProduct(p);
              if (imagePath != null && imagePath.isNotEmpty) {
                await _repo.addProductImage(
                  created.id,
                  imageUrl: imagePath,
                );
              }
              return created;
            },
            onSubmit: (params, {barcode, imagePath}) async {
              if (barcode != null && barcode.isNotEmpty) {
                final snap = await _repo.getProductSnapshot(params.productId);
                await _repo.applyProductSnapshot(snap.copyWith(barcode: barcode));
              }
              if (imagePath != null && imagePath.isNotEmpty) {
                await _repo.addProductImage(
                  params.productId,
                  imageUrl: imagePath,
                );
              }
              await _registerUseCase(params);
            },
          );
        },
      );
      if (!context.mounted) return;
      if (saved == true) {
        await refreshInventory();
        if (context.mounted) {
          _snack(context, 'Entrada registrada.');
        }
      }
    } on StockInventoryApiException catch (e) {
      if (context.mounted) _snack(context, e.message);
    } catch (e) {
      if (context.mounted) _snack(context, e.toString());
    }
  }

  Future<void> openCreateProductSheet(BuildContext context) async {
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) {
          return StockCreateProductSheet(
            onSave: (p, {imagePath}) async {
              final created = await _repo.createProduct(p);
              if (imagePath != null && imagePath.isNotEmpty) {
                await _repo.addProductImage(
                  created.id,
                  imageUrl: imagePath,
                );
              }
            },
          );
        },
      );
      if (!context.mounted) return;
      if (ok == true) {
        await refreshInventory();
        if (context.mounted) {
          _snack(context, 'Produto cadastrado.');
        }
      }
    } on StockInventoryApiException catch (e) {
      if (context.mounted) _snack(context, e.message);
    } catch (e) {
      if (context.mounted) _snack(context, e.toString());
    }
  }

  Future<void> openEditSheet(BuildContext context, StockInventoryRowEntity row) async {
    try {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) {
          return StockEditSheet(
            row: row,
            loadProduct: () => _repo.getProductSnapshot(row.productId),
            onSave: (product, batchExpiration, batchActive, imagePath) async {
              await _repo.applyProductSnapshot(product);
              if (imagePath != null && imagePath.isNotEmpty) {
                await _repo.addProductImage(
                  row.productId,
                  imageUrl: imagePath,
                );
              }
              await _repo.updateProductBatch(
                batchId: row.batchId,
                expirationDate: batchExpiration,
                active: batchActive,
              );
            },
          );
        },
      );
      if (!context.mounted) return;
      if (saved == true) {
        await refreshInventory();
        if (context.mounted) _snack(context, 'Alterações salvas.');
      }
    } catch (e) {
      if (context.mounted) _snack(context, e.toString());
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> openBarcodeScanner(BuildContext context) async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const BarcodeScannerSheet(),
    );
    if (!context.mounted) return;
    if (code == null || code.isEmpty) return;
    _showBarcodeResultPopup(context, code);
  }

  void _showBarcodeResultPopup(BuildContext context, String barcode) {
    StockInventoryRowEntity? row;
    for (final item in rows) {
      if ((item.barcode ?? '').trim() == barcode) {
        row = item;
        break;
      }
    }
    if (row == null) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Produto não encontrado'),
          content: Text(
            'Não existe produto vinculado ao código de barras:\n$barcode',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Voltar'),
            ),
          ],
        ),
      );
      return;
    }
    final found = row;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Produto encontrado'),
        content: SizedBox(
          width: 360,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nome: ${found.productName}'),
                  const SizedBox(height: 6),
                  Text('Valor: ${found.saleLabel}'),
                  const SizedBox(height: 6),
                  Text('Quantidade: ${found.quantityLabel}'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _snack(context, 'Produto adicionado ao carrinho.');
            },
            child: const Text('Adicionar ao carrinho'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  String formatValidity(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
