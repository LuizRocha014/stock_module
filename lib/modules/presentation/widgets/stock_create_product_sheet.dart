import 'package:componentes_lr/componentes_lr.dart' show ImagePickerInputWidget;
import 'package:flutter/material.dart';
import 'package:stock_module/modules/domain/entities/create_product_params.dart';
import 'package:stock_module/modules/presentation/design/iw_app_shell.dart';
import 'package:stock_module/modules/presentation/design/iw_design.dart';
import 'package:stock_module/modules/presentation/utils/brl_currency_formatter.dart';

class StockCreateProductSheet extends StatefulWidget {
  const StockCreateProductSheet({super.key, required this.onSave});

  final Future<void> Function(CreateProductParams params, {String? imagePath})
      onSave;

  @override
  State<StockCreateProductSheet> createState() =>
      _StockCreateProductSheetState();
}

class _StockCreateProductSheetState extends State<StockCreateProductSheet> {
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _saleCtrl = TextEditingController();
  String _unitType = 'UN';
  bool _isPerishable = false;
  bool _saving = false;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _saleCtrl.text = BrlCurrencyInputFormatter.formatDouble(0);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _saleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final sku = _skuCtrl.text.trim();
    if (name.isEmpty) return _toast('Informe o nome do produto.');
    if (sku.isEmpty) return _toast('Informe o SKU.');
    final sale = BrlCurrencyInputFormatter.parseToDouble(_saleCtrl.text);
    final barcode = _barcodeCtrl.text.trim();
    setState(() => _saving = true);
    try {
      await widget.onSave(
        CreateProductParams(
          name: name,
          sku: sku,
          barcode: barcode.isEmpty ? null : barcode,
          unitType: _unitType,
          isPerishable: _isPerishable,
          salePrice: sale < 0 ? 0 : sale,
        ),
        imagePath: _imagePath,
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
              title: 'Novo produto',
              subtitle: 'Cadastre o produto antes de registrar a primeira entrada.',
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _skuCtrl,
              decoration: const InputDecoration(labelText: 'SKU'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _barcodeCtrl,
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
                    initialValue: _unitType,
                    decoration: const InputDecoration(labelText: 'Unidade'),
                    items: const [
                      DropdownMenuItem(value: 'UN', child: Text('UN')),
                      DropdownMenuItem(value: 'KG', child: Text('KG')),
                      DropdownMenuItem(value: 'LT', child: Text('LT')),
                    ],
                    onChanged: (v) => setState(() => _unitType = v ?? 'UN'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _saleCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Preço de venda'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [BrlCurrencyInputFormatter()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _PerishableSwitch(
              value: _isPerishable,
              onChanged: (v) => setState(() => _isPerishable = v),
            ),
            const SizedBox(height: 6),
            ImagePickerInputWidget(
              title: 'Imagem do produto (opcional)',
              onImageChanged: (path) => _imagePath = path,
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Salvando…' : 'Cadastrar produto'),
              ),
            ),
          ],
        ),
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
