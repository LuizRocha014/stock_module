import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stock_module/modules/data/models/api_parse.dart';
import 'package:stock_module/modules/data/models/branch_dto.dart';
import 'package:stock_module/modules/data/models/product_batch_dto.dart';
import 'package:stock_module/modules/data/models/product_dto.dart';
import 'package:stock_module/modules/data/stock_api_settings.dart';

abstract class IStockInventoryRemoteDataSource {
  Future<List<ProductDto>> fetchProducts();

  Future<ProductDto> fetchProduct(String id);
  Future<String?> fetchMainProductImageUrl(String productId);

  Future<List<ProductBatchDto>> fetchProductBatches({String? branchId, String? productId});

  Future<List<BranchDto>> fetchBranches({String? companyId});

  Future<StockEntryResponse> postInventoryEntry(StockEntryRequest request);

  Future<ProductDto> postProduct(Map<String, dynamic> body);

  Future<void> postProductImage(
    String productId, {
    required String url,
    bool isMain = true,
  });

  Future<void> putProduct(String id, Map<String, dynamic> body);

  Future<void> putProductBatch(String id, Map<String, dynamic> body);

  Future<void> deleteProductBatch(String id);
}

class StockEntryRequest {
  StockEntryRequest({
    required this.productId,
    required this.branchId,
    required this.quantity,
    required this.costPrice,
    this.expirationDate,
    this.entryDate,
    this.batchId,
  });

  final String productId;
  final String branchId;
  final double quantity;
  final double costPrice;
  final DateTime? expirationDate;
  final DateTime? entryDate;

  /// Acréscimo em lote existente (quando a API suporta).
  final String? batchId;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'branchId': branchId,
        'quantity': quantity,
        'costPrice': costPrice,
        'expirationDate': expirationDate?.toUtc().toIso8601String(),
        'entryDate': entryDate?.toUtc().toIso8601String(),
        if (batchId != null && batchId!.trim().isNotEmpty) 'batchId': batchId!.trim(),
      };
}

class StockEntryResponse {
  StockEntryResponse({this.batchId, this.movementId});

  final String? batchId;
  final String? movementId;

  factory StockEntryResponse.fromJson(Map<String, dynamic> m) {
    return StockEntryResponse(
      batchId: mapString(m, const ['batchId', 'BatchId']),
      movementId: mapString(m, const ['movementId', 'MovementId']),
    );
  }
}

class StockInventoryRemoteDataSource implements IStockInventoryRemoteDataSource {
  StockInventoryRemoteDataSource({required this.settings});

  final StockApiSettings settings;
  final http.Client _client = http.Client();

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = settings.normalizedBase;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Map<String, String> _headers() {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final t = settings.accessToken?.trim();
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = t.toLowerCase().startsWith('bearer ') ? t : 'Bearer $t';
    }
    return h;
  }

  void _throwIfError(http.Response r, String context) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    String msg = 'HTTP ${r.statusCode}';
    try {
      final body = jsonDecode(r.body);
      if (body is Map && body['error'] != null) msg = '$msg: ${body['error']}';
    } catch (_) {
      if (r.body.isNotEmpty) msg = '$msg — ${r.body.length > 120 ? '${r.body.substring(0, 120)}…' : r.body}';
    }
    throw StockInventoryApiException('$context: $msg');
  }

  @override
  Future<List<ProductDto>> fetchProducts() async {
    final r = await _client.get(_uri('/api/products'), headers: _headers());
    _throwIfError(r, 'GET /api/products');
    final list = decodeJsonList(r.body);
    return list.map((e) => ProductDto.fromJson(asMap(e))).where((p) => p.id.isNotEmpty).toList();
  }

  @override
  Future<ProductDto> fetchProduct(String id) async {
    final r = await _client.get(_uri('/api/products/$id'), headers: _headers());
    _throwIfError(r, 'GET /api/products/{id}');
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) {
      throw StockInventoryApiException('Produto: resposta inválida.');
    }
    return ProductDto.fromJson(decoded);
  }

  @override
  Future<String?> fetchMainProductImageUrl(String productId) async {
    final r = await _client.get(
      _uri('/api/products/$productId/images'),
      headers: _headers(),
    );
    _throwIfError(r, 'GET /api/products/{productId}/images');
    final list = decodeJsonList(r.body);
    if (list.isEmpty) return null;
    Map<String, dynamic>? main;
    for (final item in list) {
      final m = asMap(item);
      final isMain = mapValue<bool>(m, const ['isMain', 'IsMain']) ?? false;
      if (isMain) {
        main = m;
        break;
      }
      main ??= m;
    }
    if (main == null) return null;
    final url = mapString(main, const ['url', 'Url']);
    return (url == null || url.isEmpty) ? null : url;
  }

  @override
  Future<List<ProductBatchDto>> fetchProductBatches({String? branchId, String? productId}) async {
    final q = <String, String>{};
    if (branchId != null && branchId.isNotEmpty) q['branchId'] = branchId;
    if (productId != null && productId.isNotEmpty) q['productId'] = productId;
    final r = await _client.get(_uri('/api/productbatches', q.isEmpty ? null : q), headers: _headers());
    _throwIfError(r, 'GET /api/productbatches');
    final list = decodeJsonList(r.body);
    return list.map((e) => ProductBatchDto.fromJson(asMap(e))).where((b) => b.id.isNotEmpty).toList();
  }

  @override
  Future<List<BranchDto>> fetchBranches({String? companyId}) async {
    final q = <String, String>{};
    if (companyId != null && companyId.isNotEmpty) q['companyId'] = companyId;
    final r = await _client.get(_uri('/api/branches', q.isEmpty ? null : q), headers: _headers());
    _throwIfError(r, 'GET /api/branches');
    final list = decodeJsonList(r.body);
    return list.map((e) => BranchDto.fromJson(asMap(e))).where((b) => b.id.isNotEmpty).toList();
  }

  @override
  Future<StockEntryResponse> postInventoryEntry(StockEntryRequest request) async {
    final r = await _client.post(
      _uri('/api/inventory/entries'),
      headers: _headers(),
      body: jsonEncode(request.toJson()),
    );
    _throwIfError(r, 'POST /api/inventory/entries');
    if (r.body.isEmpty) return StockEntryResponse();
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) return StockEntryResponse();
    return StockEntryResponse.fromJson(decoded);
  }

  @override
  Future<ProductDto> postProduct(Map<String, dynamic> body) async {
    final r = await _client.post(
      _uri('/api/products'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    _throwIfError(r, 'Cadastro de produto');
    if (r.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(r.body);
        if (decoded is Map<String, dynamic>) {
          final dto = ProductDto.fromJson(decoded);
          if (dto.id.isNotEmpty) return dto;
        }
      } catch (_) {}
    }
    final loc = r.headers['location'] ?? r.headers['Location'];
    if (loc != null) {
      final uri = Uri.tryParse(loc);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        final id = uri.pathSegments.last;
        if (id.isNotEmpty && id != 'products') {
          return fetchProduct(id);
        }
      }
      final m = RegExp(r'([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})')
          .firstMatch(loc);
      if (m != null) {
        return fetchProduct(m.group(1)!);
      }
    }
    throw StockInventoryApiException(
      'Produto criado, mas a API não retornou o ID (corpo ou cabeçalho Location).',
    );
  }

  @override
  Future<void> postProductImage(
    String productId, {
    required String url,
    bool isMain = true,
  }) async {
    final r = await _client.post(
      _uri('/api/products/$productId/images'),
      headers: _headers(),
      body: jsonEncode({
        'url': url,
        'isMain': isMain,
      }),
    );
    _throwIfError(r, 'Cadastro de imagem do produto');
  }

  @override
  Future<void> putProduct(String id, Map<String, dynamic> body) async {
    final r = await _client.put(
      _uri('/api/products/$id'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    _throwIfError(r, 'PUT /api/products/{id}');
  }

  @override
  Future<void> putProductBatch(String id, Map<String, dynamic> body) async {
    final r = await _client.put(
      _uri('/api/productbatches/$id'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    _throwIfError(r, 'PUT /api/productbatches/{id}');
  }

  @override
  Future<void> deleteProductBatch(String id) async {
    final r = await _client.delete(
      _uri('/api/productbatches/$id'),
      headers: _headers(),
    );
    _throwIfError(r, 'DELETE /api/productbatches/{id}');
  }
}

class StockInventoryApiException implements Exception {
  StockInventoryApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
