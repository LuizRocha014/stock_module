import 'package:flutter/material.dart';
import 'package:stock_module/modules/domain/entities/create_product_params.dart';
import 'package:stock_module/modules/domain/entities/stock_entry_params.dart';
import 'package:stock_module/modules/domain/repositories/stock_inventory_repository.dart';
import 'package:stock_module/modules/presentation/utils/brl_currency_formatter.dart';

class StockAddEntrySheet extends StatefulWidget {
  const StockAddEntrySheet({
    super.key,
    required this.products,
    required this.branches,
    required this.onCreateProduct,
    required this.onSubmit,
  });

  final List<ProductRef> products;
  final List<BranchRef> branches;
  final Future<ProductRef> Function(CreateProductParams params) onCreateProduct;
  final Future<void> Function(StockEntryParams params, {String? barcode}) onSubmit;

  @override
  State<StockAddEntrySheet> createState() => _StockAddEntrySheetState();
}

class _StockAddEntrySheetState extends State<StockAddEntrySheet> {
  late bool _useNewProduct;

  String? _productId;
  String? _branchId;
  final _qtyCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _barcodeUpdateCtrl = TextEditingController();

  final _newNameCtrl = TextEditingController();
  final _newSkuCtrl = TextEditingController();
  final _newBarcodeCtrl = TextEditingController();
  final _newSaleCtrl = TextEditingController();
  String _newUnitType = 'UN';
  bool _newPerishable = false;

  DateTime? _expiration;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _useNewProduct = widget.products.isEmpty;
    _costCtrl.text = BrlCurrencyInputFormatter.formatDouble(0);
    _newSaleCtrl.text = BrlCurrencyInputFormatter.formatDouble(0);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _barcodeUpdateCtrl.dispose();
    _newNameCtrl.dispose();
    _newSkuCtrl.dispose();
    _newBarcodeCtrl.dispose();
    _newSaleCtrl.dispose();
    super.dispose();
  }

  double _parseQty(String s) {
    final t = s.trim().replaceAll(',', '.');
    return double.tryParse(t) ?? 0;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _expiration ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (d != null) setState(() => _expiration = d);
  }

  Future<void> _save() async {
    if (_branchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a filial.')),
      );
      return;
    }
    final q = _parseQty(_qtyCtrl.text);
    if (q <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma quantidade maior que zero.')),
      );
      return;
    }
    if (!_useNewProduct && _productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o produto.')),
      );
      return;
    }
    if (_useNewProduct) {
      if (_newNameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe o nome do novo produto.')),
        );
        return;
      }
      if (_newSkuCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe o SKU do novo produto.')),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final String productId;
      if (_useNewProduct) {
        final sale = BrlCurrencyInputFormatter.parseToDouble(_newSaleCtrl.text);
        final bc = _newBarcodeCtrl.text.trim();
        final ref = await widget.onCreateProduct(
          CreateProductParams(
            name: _newNameCtrl.text.trim(),
            sku: _newSkuCtrl.text.trim(),
            barcode: bc.isEmpty ? null : bc,
            unitType: _newUnitType,
            isPerishable: _newPerishable,
            salePrice: sale < 0 ? 0 : sale,
          ),
        );
        productId = ref.id;
      } else {
        productId = _productId!;
      }

      final cost = BrlCurrencyInputFormatter.parseToDouble(_costCtrl.text);
      final barcodePatch =
          !_useNewProduct ? _barcodeUpdateCtrl.text.trim() : '';

      await widget.onSubmit(
        StockEntryParams(
          productId: productId,
          branchId: _branchId!,
          quantity: q,
          costPrice: cost < 0 ? 0 : cost,
          expirationDate: _expiration,
          entryDate: null,
        ),
        barcode: barcodePatch.isEmpty ? null : barcodePatch,
      );
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
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Entrada de estoque',
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
            if (widget.products.isNotEmpty) ...[
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Produto existente'),
                    icon: Icon(Icons.inventory_2_outlined, size: 18),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Novo produto'),
                    icon: Icon(Icons.add_box_outlined, size: 18),
                  ),
                ],
                selected: {_useNewProduct},
                onSelectionChanged: (Set<bool> next) {
                  setState(() => _useNewProduct = next.first);
                },
              ),
              const SizedBox(height: 16),
            ] else ...[
              Text(
                'Não há produtos cadastrados. Preencha os dados do novo produto e a entrada.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (!_useNewProduct) ...[
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Produto',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _productId,
                    hint: const Text('Selecione'),
                    items: widget.products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _productId = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _barcodeUpdateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código de barras (opcional)',
                  border: OutlineInputBorder(),
                  helperText: 'Atualiza o produto se preenchido',
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 12),
            ] else ...[
              TextField(
                controller: _newNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome do produto',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newSkuCtrl,
                decoration: const InputDecoration(
                  labelText: 'SKU',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newBarcodeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código de barras (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Unidade',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _newUnitType,
                    items: const [
                      DropdownMenuItem(value: 'UN', child: Text('UN')),
                      DropdownMenuItem(value: 'KG', child: Text('KG')),
                      DropdownMenuItem(value: 'LT', child: Text('LT')),
                    ],
                    onChanged: (v) => setState(() => _newUnitType = v ?? 'UN'),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Produto perecível'),
                value: _newPerishable,
                onChanged: (v) => setState(() => _newPerishable = v),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _newSaleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Preço de venda',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [BrlCurrencyInputFormatter()],
              ),
              const SizedBox(height: 12),
            ],
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Dados da entrada',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Filial',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _branchId,
                  hint: const Text('Selecione'),
                  items: widget.branches
                      .map(
                        (b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(b.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _branchId = v),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              decoration: const InputDecoration(
                labelText: 'Quantidade',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _costCtrl,
              decoration: const InputDecoration(
                labelText: 'Preço de custo',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [BrlCurrencyInputFormatter()],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                _expiration == null
                    ? 'Validade (opcional)'
                    : 'Validade: ${_expiration!.day.toString().padLeft(2, '0')}/${_expiration!.month.toString().padLeft(2, '0')}/${_expiration!.year}',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: Text(_saving ? 'Salvando…' : 'Registrar entrada'),
            ),
          ],
        ),
      ),
    );
  }
}
