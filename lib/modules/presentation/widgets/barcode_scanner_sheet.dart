import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:stock_module/modules/presentation/design/iw_app_shell.dart';
import 'package:stock_module/modules/presentation/design/iw_design.dart';

class BarcodeScannerSheet extends StatefulWidget {
  const BarcodeScannerSheet({super.key});

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    if (capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue?.trim();
    if (code == null || code.isEmpty) return;
    _handling = true;
    await _controller.stop();
    if (mounted) Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 460,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IwSheetHeader(
                title: 'Ler código de barras',
                subtitle: 'Aponte a câmera para o código.',
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(IwRadius.lg),
                  child: Container(
                    decoration: BoxDecoration(
                      color: IwColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(IwRadius.lg),
                      border: Border.all(color: IwColors.outlineVariant),
                    ),
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
