import 'package:componentes_lr/componentes_lr.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const TextWidget(
          'Estoque',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: TextWidget(
          'stock_module',
          textColor: scheme.onSurface,
          fontSize: 16,
        ),
      ),
    );
  }
}
