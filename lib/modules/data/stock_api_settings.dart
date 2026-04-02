/// Configuração da API descrita em DocumentaçãoAPI (JWT em [accessToken], base sem barra final).
class StockApiSettings {
  StockApiSettings({
    required this.baseUrl,
    this.accessToken,
  });

  /// Ex.: `https://localhost:7001` — use `String.fromEnvironment` no app ou substitua o singleton.
  String baseUrl;
  String? accessToken;

  String get normalizedBase => baseUrl.replaceAll(RegExp(r'/+$'), '');
}
