import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  /// Fetches the user's public IP address and location (City, Country).
  /// Returns a map with 'ip' and 'location' keys.
  static Future<Map<String, String>> fetchIpAndLocation() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json/')).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ip = data['query'] ?? 'Unknown';
        final city = data['city'] ?? '';
        final country = data['country'] ?? '';
        
        String location = 'Unknown';
        if (city.isNotEmpty && country.isNotEmpty) {
          location = '$city, $country';
        } else if (city.isNotEmpty) {
          location = city;
        } else if (country.isNotEmpty) {
          location = country;
        }

        return {
          'ip': ip,
          'location': location,
        };
      }
    } catch (e) {
      print('Failed to fetch IP and Location: $e');
    }
    
    // Fallback if network request fails
    return {
      'ip': 'Unknown',
      'location': 'Unknown',
    };
  }
}
