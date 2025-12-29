import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_assesment_1/core/network/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: 'https://api.escuelajs.co/api/v1/');
});
