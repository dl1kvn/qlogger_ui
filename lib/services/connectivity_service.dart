import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  /// Check if the device has an active internet connection.
  /// First checks connectivity status, then verifies with a quick HTTP request.
  static Future<bool> hasInternetConnection() async {
    try {
      // Check connectivity status
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }

      // Verify actual internet access with a quick request
      final response = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
