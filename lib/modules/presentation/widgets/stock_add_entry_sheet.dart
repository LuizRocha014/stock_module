import 'package:componentes_lr/componentes_lr.dart' show ImagePickerInputWidget;
import 'package:flutter/material.dart';
import 'package:stock_module/modules/domain/entities/create_product_params.dart';
import 'package:stock_module/modules/domain/entities/stock_entry_params.dart';
import 'package:stock_module/modules/domain/repositories/stock_inventory_repository.dart';
import 'package:stock_module/modules/presentation/design/iw_app_shell.dart';
import 'package:stock_module/modules/presentation/design/iw_design.dart';
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
  final Future<ProductRef> Function(CreateProductParams params,
      {String? imagePath}) onCreateProduct;
  final Future<void> Function(
    StockEntryParams params, {
    String? barcode,
    String? imagePath,
  }) onSubmit;

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
  String? _newImagePath;
  String? _existingImagePath;

  DateTime? _expiration;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _useNewProduct = widget.products.isEmpty;
    if (widget.branches.length == 1) {
      _branchId = widget.branches.first.id;
    }
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

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _save() async {
    if (_branchId == null) {
      _toast('Selecione a filial.');
      return;
    }
    final q = _parseQty(_qtyCtrl.text);
    if (q <= 0) {
      _toast('Informe uma quantidade maior que zero.');
      return;
    }
    if (!_useNewProduct && _productId == null) {
      _toast('Selecione o produto.');
      return;
    }
    if (_useNewProduct) {
      if (_newNameCtrl.text.trim().isEmpty) {
        _toast('Informe o nome do novo produto.');
        return;
      }
      if (_newSkuCtrl.text.trim().isEmpty) {
        _toast('Informe o SKU do novo produto.');
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
          imagePath: _newImagePath,
        );
        productId = ref.id;
      } else {
        productId = _productId!;
      }

      final cost = BrlCurrencyInputFormatter.parseToDouble(_costCtrl.text);
      final barcodePatch = !_useNewProduct ? _barcodeUpdateCtrl.text.trim() : '';
      final imagePath = !_useNewProduct ? _existingImagePath : null;

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
        imagePath: imagePath,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _toast(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IwSheetHeader(
              title: 'Entrada de estoque',
              subtitle: widget.products.isEmpty
                  ? 'Não há produtos cadastrados. Cadastre um novo agora.'
                  : 'Registre uma nova entrada para um produto existente ou cadastre um novo agora.',
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 22),
            if (widget.products.isNotEmpty) ...[
              SegmentedButton<bool>(
                showSelectedIcon: true,
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
                onSelectionChanged: (next) {
                  setState(() => _useNewProduct = next.first);
                },
              ),
              const SizedBox(height: 20),
            ],
            if (!_useNewProduct) ..._existingProductSection() else ..._newProductSection(),
            const SizedBox(height: 18),
            const Divider(height: 1, color: IwColors.outlineVariant),
            const SizedBox(height: 14),
            const _SectionLabel('Dados da entrada'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _branchId,
              decoration: const InputDecoration(
                labelText: 'Filial',
                prefixIcon: Icon(Icons.store_outlined),
              ),
              hint: const Text('Selecione'),
              items: widget.branches
                  .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                  .toList(),
              onChanged: (v) => setState(() => _branchId = v),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    decoration: InputDecoration(
                      labelText: 'Quantidade',
                      suffixText: _useNewProduct ? _newUnitType : null,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _costCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Preço de custo'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [BrlCurrencyInputFormatter()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(
                _expiration == null
                    ? 'Validade (opcional)'
                    : 'Validade: ${_fmtDate(_expiration!)}',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
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
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _existingProductSection() {
    return [
      DropdownButtonFormField<String>(
        initialValue: _productId,
        decoration: const InputDecoration(
          labelText: 'Produto',
          prefixIcon: Icon(Icons.inventory_2_outlined),
        ),
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
      const SizedBox(height: 14),
      TextField(
        controller: _barcodeUpdateCtrl,
        decoration: const InputDecoration(
          labelText: 'Código de barras (opcional)',
          helperText: 'Atualiza o produto se preenchido',
          prefixIcon: Icon(Icons.qr_code_2_outlined),
        ),
      ),
      const SizedBox(height: 14),
      ImagePickerInputWidget(
        title: 'Foto do produto (opcional)',
        onImageChanged: (path) => _existingImagePath = path,
      ),
    ];
  }

  List<Widget> _newProductSection() {
    return [
      TextField(
        controller: _newNameCtrl,
        decoration: const InputDecoration(labelText: 'Nome do produto'),
        textCapitalization: TextCapitalization.words,
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _newSkuCtrl,
        decoration: const InputDecoration(labelText: 'SKU'),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _newBarcodeCtrl,
        decoration: const InputDecoration(
          labelText: 'Código de barras (opcional)',
          prefixIcon: Icon(Icons.qr_code_2_outlined),
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _newUnitType,
              decoration: const InputDecoration(labelText: 'Unidade'),
              items: const [
                DropdownMenuItem(value: 'UN', child: Text('UN')),
                DropdownMenuItem(value: 'KG', child: Text('KG')),
                DropdownMenuItem(value: 'LT', child: Text('LT')),
              ],
              onChanged: (v) => setState(() => _newUnitType = v ?? 'UN'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _newSaleCtrl,
              decoration: const InputDecoration(labelText: 'Preço de venda'),
              keyboardType: TextInputType.number,
              inputFormatters: [BrlCurrencyInputFormatter()],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _PerishableSwitch(
        value: _newPerishable,
        onChanged: (v) => setState(() => _newPerishable = v),
      ),
      const SizedBox(height: 6),
      ImagePickerInputWidget(
        title: 'Imagem do novo produto (opcional)',
        onImageChanged: (path) => _newImagePath = path,
      ),
    ];
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: IwColors.onSurface,
      ),
    );
  }
}

class _PerishableSwitch extends StatelessWidget {
  const _PerishableSwitch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(IwRadius.sm),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Produto perecível',
                    style: TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      color: IwColors.onSurface,
                    ),
                  ),
                  Text(
                    'Coletaremos lote e validade nas próximas entradas',
                    style: TextStyle(
                      fontSize: 12,
                      color: IwColors.onSurfaceVariant,
                      height: 16 / 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
