import 'dart:async';

import 'package:http/http.dart' as http;

class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient({
    http.Client? inner,
    this.timeout = const Duration(seconds: 20),
  }) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final Duration timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner
        .send(request)
        .timeout(
          timeout,
          onTimeout: () => throw TimeoutException(
            'The server took too long to respond. Please try again.',
          ),
        );
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
