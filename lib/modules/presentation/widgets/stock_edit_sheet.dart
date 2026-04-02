import 'package:flutter/material.dart';
import 'package:stock_module/modules/domain/entities/product_snapshot.dart';
import 'package:stock_module/modules/domain/entities/stock_inventory_row_entity.dart';
import 'package:stock_module/modules/presentation/utils/brl_currency_formatter.dart';

class StockEditSheet extends StatefulWidget {
  const StockEditSheet({
    super.key,
    required this.row,
    required this.loadProduct,
    required this.onSave,
  });

  final StockInventoryRowEntity row;
  final Future<ProductSnapshot> Function() loadProduct;
  final Future<void> Function(
    ProductSnapshot product,
    DateTime? batchExpiration,
    bool batchActive,
  ) onSave;

  @override
  State<StockEditSheet> createState() => _StockEditSheetState();
}

class _StockEditSheetState extends State<StockEditSheet> {
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _saleCtrl = TextEditingController();
  DateTime? _batchExpiration;
  bool _batchActive = true;
  bool _saving = false;
  Object? _loadError;
  ProductSnapshot? _base;

  @override
  void initState() {
    super.initState();
    _batchExpiration = widget.row.expirationDate;
    _batchActive = true;
    widget.loadProduct().then((s) {
      if (!mounted) return;
      setState(() {
        _base = s;
        _nameCtrl.text = s.name;
        _skuCtrl.text = s.sku ?? '';
        _barcodeCtrl.text = s.barcode ?? '';
        _saleCtrl.text = BrlCurrencyInputFormatter.formatDouble(s.salePrice);
      });
    }).catchError((e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _saleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _batchExpiration ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (d != null) setState(() => _batchExpiration = d);
  }

  Future<void> _save() async {
    final base = _base;
    if (base == null) return;
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do produto.')),
      );
      return;
    }
    final sale = BrlCurrencyInputFormatter.parseToDouble(_saleCtrl.text);
    final updated = base.copyWith(
      name: _nameCtrl.text.trim(),
      sku: _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
      salePrice: sale < 0 ? 0 : sale,
    );
    setState(() => _saving = true);
    try {
      await widget.onSave(updated, _batchExpiration, _batchActive);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 16 + bottom),
      child: _loadError != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$_loadError', style: TextStyle(color: scheme.error)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            )
          : _base == null
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Editar',
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
                      Text(
                        widget.row.productName,
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _skuCtrl,
                        decoration: const InputDecoration(
                          labelText: 'SKU',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _barcodeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Código de barras',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _saleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Preço de venda',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [BrlCurrencyInputFormatter()],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lote',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Lote ativo'),
                        value: _batchActive,
                        onChanged: (v) => setState(() => _batchActive = v),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          _batchExpiration == null
                              ? 'Validade (opcional)'
                              : 'Validade: ${_batchExpiration!.day.toString().padLeft(2, '0')}/${_batchExpiration!.month.toString().padLeft(2, '0')}/${_batchExpiration!.year}',
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Salvar'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
