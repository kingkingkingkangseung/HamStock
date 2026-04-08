import 'dart:convert';
import 'dart:io';

class HamstockApi {
  HamstockApi(this.baseUrl);

  final String baseUrl;

  Future<List<dynamic>> getStocks({
    String? q,
    String? sort,
    String? order,
  }) async {
    final query = <String, String>{};
    if (q != null && q.trim().isNotEmpty) query['q'] = q.trim();
    if (sort != null && sort.isNotEmpty) query['sort'] = sort;
    if (order != null && order.isNotEmpty) query['order'] = order;
    final uri = Uri.parse('$baseUrl/stocks').replace(queryParameters: query);
    final data = await _request(uri, 'GET');
    return data is List ? data : <dynamic>[];
  }

  Future<Map<String, dynamic>> getDashboard(int userId) async {
    final uri = Uri.parse('$baseUrl/me/dashboard')
        .replace(queryParameters: {'userId': '$userId'});
    final data = await _request(uri, 'GET');
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> buy({
    required int userId,
    required int stockId,
    required int quantity,
  }) async {
    final uri = Uri.parse('$baseUrl/orders/buy');
    final data = await _request(
      uri,
      'POST',
      body: {
        'userId': userId,
        'stockId': stockId,
        'quantity': quantity,
      },
    );
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> preview({
    required int userId,
    required int stockId,
    required int quantity,
    required String side,
    required String priceType,
    double? limitPrice,
  }) async {
    final uri = Uri.parse('$baseUrl/orders/preview');
    final body = <String, dynamic>{
      'userId': userId,
      'stockId': stockId,
      'quantity': quantity,
      'side': side,
      'priceType': priceType,
    };
    if (limitPrice != null) {
      body['limitPrice'] = limitPrice;
    }
    final data = await _request(
      uri,
      'POST',
      body: body,
    );
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> sell({
    required int userId,
    required int stockId,
    required int quantity,
  }) async {
    final uri = Uri.parse('$baseUrl/orders/sell');
    final data = await _request(
      uri,
      'POST',
      body: {
        'userId': userId,
        'stockId': stockId,
        'quantity': quantity,
      },
    );
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<List<dynamic>> getOrderHistory({
    required int userId,
    String? type,
  }) async {
    final query = <String, String>{'userId': '$userId'};
    if (type != null && type.isNotEmpty) query['type'] = type;
    final uri = Uri.parse('$baseUrl/orders/history')
        .replace(queryParameters: query);
    final data = await _request(uri, 'GET');
    return data is List ? data : <dynamic>[];
  }

  Future<List<dynamic>> getHoldings({required int userId}) async {
    final uri = Uri.parse('$baseUrl/stocks/holdings')
        .replace(queryParameters: {'userId': '$userId'});
    final data = await _request(uri, 'GET');
    return data is List ? data : <dynamic>[];
  }

  Future<dynamic> _request(
    Uri uri,
    String method, {
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient();
    try {
      final req = await client.openUrl(method, uri);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      if (body != null) {
        req.write(jsonEncode(body));
      }
      final res = await req.close();
      final raw = await utf8.decoder.bind(res).join();
      final parsed = raw.isEmpty ? null : jsonDecode(raw);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        final message = parsed is Map<String, dynamic> && parsed['message'] != null
            ? parsed['message'].toString()
            : 'Request failed (${res.statusCode})';
        throw Exception(message);
      }

      return parsed;
    } finally {
      client.close();
    }
  }
}
