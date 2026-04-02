import 'package:componentes_lr/componentes_lr.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stock_module/modules/data/datasource/remote/stock_inventory_remote_datasource.dart';
import 'package:stock_module/modules/domain/entities/stock_inventory_row_entity.dart';
import 'package:stock_module/modules/domain/repositories/stock_inventory_repository.dart';
import 'package:stock_module/modules/domain/usecases/stock_inventory_usecases.dart';
import 'package:stock_module/modules/presentation/widgets/stock_add_entry_sheet.dart';
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
      if (r.unitOrCostLabel.toLowerCase().contains(q)) return true;
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
            onCreateProduct: (p) => _repo.createProduct(p),
            onSubmit: (params, {barcode}) async {
              if (barcode != null && barcode.isNotEmpty) {
                final snap = await _repo.getProductSnapshot(params.productId);
                await _repo.applyProductSnapshot(snap.copyWith(barcode: barcode));
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
            onSave: (p) async {
              await _repo.createProduct(p);
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
            onSave: (product, batchExpiration, batchActive) async {
              await _repo.applyProductSnapshot(product);
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

  String formatValidity(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
