import 'package:flutter/material.dart';
import 'package:stock_module/modules/domain/entities/create_product_params.dart';
import 'package:stock_module/modules/presentation/utils/brl_currency_formatter.dart';

/// Cadastro apenas de produto (POST /api/products).
class StockCreateProductSheet extends StatefulWidget {
  const StockCreateProductSheet({
    super.key,
    required this.onSave,
  });

  final Future<void> Function(CreateProductParams params) onSave;

  @override
  State<StockCreateProductSheet> createState() => _StockCreateProductSheetState();
}

class _StockCreateProductSheetState extends State<StockCreateProductSheet> {
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _saleCtrl = TextEditingController();
  String _unitType = 'UN';
  bool _isPerishable = false;
  bool _saving = false;

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
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do produto.')),
      );
      return;
    }
    if (sku.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o SKU.')),
      );
      return;
    }
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
                    'Novo produto',
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
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
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
                  value: _unitType,
                  items: const [
                    DropdownMenuItem(value: 'UN', child: Text('UN')),
                    DropdownMenuItem(value: 'KG', child: Text('KG')),
                    DropdownMenuItem(value: 'LT', child: Text('LT')),
                  ],
                  onChanged: (v) => setState(() => _unitType = v ?? 'UN'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Produto perecível'),
              value: _isPerishable,
              onChanged: (v) => setState(() => _isPerishable = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _saleCtrl,
              decoration: const InputDecoration(
                labelText: 'Preço de venda',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [BrlCurrencyInputFormatter()],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
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
          ],
        ),
      ),
    );
  }
}
