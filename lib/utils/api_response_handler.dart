// lib/utils/api_response_handler.dart
class ApiResponseHandler {
  static bool isSuccess(Map<String, dynamic> response) {
    return response['success'] == true;
  }

  static String getErrorMessage(Map<String, dynamic> response) {
    if (response.containsKey('message')) {
      return response['message'] as String;
    }
    
    if (response.containsKey('errors')) {
      final errors = response['errors'];
      if (errors is Map) {
        return errors.values.first.toString();
      }
      if (errors is String) {
        return errors;
      }
    }
    
    return 'Terjadi kesalahan yang tidak diketahui';
  }

  static T? getData<T>(Map<String, dynamic> response) {
    if (isSuccess(response) && response.containsKey('data')) {
      return response['data'] as T?;
    }
    return null;
  }
}
