import 'package:componentes_lr/componentes_lr.dart' show ImagePickerInputWidget;
import 'package:flutter/material.dart';
import 'package:stock_module/modules/domain/entities/product_snapshot.dart';
import 'package:stock_module/modules/domain/entities/stock_inventory_row_entity.dart';
import 'package:stock_module/modules/presentation/design/iw_app_shell.dart';
import 'package:stock_module/modules/presentation/design/iw_design.dart';
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
    String? imagePath,
    double batchUnitCost,
  ) onSave;

  @override
  State<StockEditSheet> createState() => _StockEditSheetState();
}

class _StockEditSheetState extends State<StockEditSheet> {
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _saleCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  DateTime? _batchExpiration;
  bool _batchActive = true;
  bool _saving = false;
  Object? _loadError;
  ProductSnapshot? _base;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _batchExpiration = widget.row.expirationDate;
    _batchActive = widget.row.batchActive;
    widget.loadProduct().then((s) {
      if (!mounted) return;
      setState(() {
        _base = s;
        _nameCtrl.text = s.name;
        _skuCtrl.text = s.sku ?? '';
        _barcodeCtrl.text = s.barcode ?? '';
        _saleCtrl.text = BrlCurrencyInputFormatter.formatDouble(s.salePrice);
        _costCtrl.text = BrlCurrencyInputFormatter.formatDouble(
          (widget.row.unitCost ?? 0).toDouble(),
        );
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
    _costCtrl.dispose();
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

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _save() async {
    final base = _base;
    if (base == null) return;
    if (_nameCtrl.text.trim().isEmpty) {
      _toast('Informe o nome do produto.');
      return;
    }
    final sale = BrlCurrencyInputFormatter.parseToDouble(_saleCtrl.text);
    final cost = BrlCurrencyInputFormatter.parseToDouble(_costCtrl.text);
    final updated = base.copyWith(
      name: _nameCtrl.text.trim(),
      sku: _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
      barcode:
          _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
      salePrice: sale < 0 ? 0 : sale,
    );
    setState(() => _saving = true);
    try {
      await widget.onSave(
        updated,
        _batchExpiration,
        _batchActive,
        _imagePath,
        cost < 0 ? 0 : cost,
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
      child: _loadError != null
          ? _ErrorBlock(
              message: '$_loadError', onClose: () => Navigator.of(context).pop())
          : _base == null
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IwSheetHeader(
            title: 'Editar produto',
            subtitle: widget.row.productName,
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nome'),
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
              labelText: 'Código de barras',
              prefixIcon: Icon(Icons.qr_code_2_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _saleCtrl,
            decoration: const InputDecoration(labelText: 'Preço de venda'),
            keyboardType: TextInputType.number,
            inputFormatters: [BrlCurrencyInputFormatter()],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _costCtrl,
            decoration: const InputDecoration(
              labelText: 'Preço de custo (unitário · lote atual)',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [BrlCurrencyInputFormatter()],
          ),
          const SizedBox(height: 14),
          ImagePickerInputWidget(
            title: 'Adicionar imagem do produto (opcional)',
            onImageChanged: (path) => _imagePath = path,
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: IwColors.outlineVariant),
          const SizedBox(height: 14),
          const Text(
            'Lote',
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: IwColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          _ActiveSwitch(
            value: _batchActive,
            onChanged: (v) => setState(() => _batchActive = v),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(
              _batchExpiration == null
                  ? 'Validade (opcional)'
                  : 'Validade: ${_fmtDate(_batchExpiration!)}',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveSwitch extends StatelessWidget {
  const _ActiveSwitch({required this.value, required this.onChanged});
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
              child: Text(
                'Lote ativo',
                style: TextStyle(
                  fontSize: 16,
                  height: 24 / 16,
                  color: IwColors.onSurface,
                ),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onClose});
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_outlined,
            size: 48, color: IwColors.error),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: IwColors.onSurface),
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: onClose, child: const Text('Fechar')),
      ],
    );
  }
}
