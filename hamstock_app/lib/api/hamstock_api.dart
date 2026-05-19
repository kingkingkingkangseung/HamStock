import 'dart:convert';
import 'dart:io';

class HamstockApi {
  HamstockApi(this.baseUrl);

  final String baseUrl;

  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/signup');
    final data = await _request(
      uri,
      'POST',
      body: {
        'email': email.trim(),
        'password': password.trim(),
        'nickname': nickname.trim(),
      },
    );
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final data = await _request(
      uri,
      'POST',
      body: {
        'email': email.trim(),
        'password': password.trim(),
      },
    );
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

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

  Future<List<dynamic>> getCoreStocks({String? market}) async {
    final query = <String, String>{};
    if (market != null && market.trim().isNotEmpty) {
      query['market'] = market.trim();
    }
    final uri = Uri.parse('$baseUrl/stocks/core').replace(queryParameters: query);
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
    String priceType = 'MARKET',
    double? limitPrice,
  }) async {
    final uri = Uri.parse('$baseUrl/orders/buy');
    final body = <String, dynamic>{
      'userId': userId,
      'stockId': stockId,
      'quantity': quantity,
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
    String priceType = 'MARKET',
    double? limitPrice,
  }) async {
    final uri = Uri.parse('$baseUrl/orders/sell');
    final body = <String, dynamic>{
      'userId': userId,
      'stockId': stockId,
      'quantity': quantity,
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

  Future<Map<String, dynamic>> getChart({
    required String code,
    required String market,
    required String range,
  }) async {
    final uri = Uri.parse('$baseUrl/stocks/chart').replace(
      queryParameters: {
        'code': code,
        'market': market,
        'range': range,
      },
    );
    final data = await _request(uri, 'GET');
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getStockDetail({
    required String code,
    required String market,
  }) async {
    final uri = Uri.parse('$baseUrl/stocks/detail').replace(
      queryParameters: {
        'code': code,
        'market': market,
      },
    );
    final data = await _request(uri, 'GET');
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getQuiz({required int userId}) async {
    final uri = Uri.parse('$baseUrl/quiz/random')
        .replace(queryParameters: {'userId': '$userId'});
    final data = await _request(uri, 'GET');
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> submitQuiz({
    required int userId,
    required int questionId,
    required String answer,
  }) async {
    final uri = Uri.parse('$baseUrl/quiz/answer');
    final data = await _request(
      uri,
      'POST',
      body: {
        'userId': userId,
        'questionId': questionId,
        'answer': answer,
      },
    );
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> exchangeSeeds({required int userId}) async {
    final uri = Uri.parse('$baseUrl/quiz/exchange');
    final data = await _request(
      uri,
      'POST',
      body: {'userId': userId},
    );
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  Future<dynamic> _request(
    Uri uri,
    String method, {
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient();
    try {
      final req = await client.openUrl(method, uri);
      req.headers.contentType = ContentType(
        'application',
        'json',
        charset: 'utf-8',
      );
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        req.write(jsonEncode(_sanitizeJson(body)));
      }
      final res = await req.close();
      final raw = await utf8.decoder.bind(res).join();
      dynamic parsed;
      if (raw.isNotEmpty) {
        try {
          parsed = jsonDecode(raw);
        } catch (_) {
          parsed = raw;
        }
      }

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception(_errorMessage(parsed, res.statusCode));
      }

      return parsed;
    } finally {
      client.close();
    }
  }

  dynamic _sanitizeJson(dynamic value) {
    if (value is String) return value.trim();
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _sanitizeJson(item)),
      );
    }
    if (value is List) {
      return value.map(_sanitizeJson).toList(growable: false);
    }
    return value;
  }

  String _errorMessage(dynamic parsed, int statusCode) {
    if (parsed is Map) {
      final message = parsed['message'];
      if (message is List) return message.join('\n');
      if (message != null) return message.toString();

      final error = parsed['error'];
      if (error != null) return error.toString();
    }

    if (parsed is String && parsed.trim().isNotEmpty) {
      return parsed;
    }

    return 'Request failed ($statusCode)';
  }
}
