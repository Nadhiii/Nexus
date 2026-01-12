import 'dart:convert';
import 'package:http/http.dart' as http;

class RTOService {
  static const String _apiKey =
      'e356771fa0msh6b1eb9d872bd6b0p1f57f2jsn9f014540309f';
  static const String _apiHost = 'rto-vehicle-details5.p.rapidapi.com';

  Future<VehicleDetails?> getVehicleDetails(String registrationNumber) async {
    try {
      final cleanRegNo = registrationNumber.replaceAll(' ', '').toUpperCase();

      final uri = Uri.https(_apiHost, '/address', {'registration': cleanRegNo});

      print('🚀 RTO: Fetching full details for $cleanRegNo...');

      final response = await http.get(
        uri,
        headers: {'x-rapidapi-key': _apiKey, 'x-rapidapi-host': _apiHost},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, dynamic> info =
            (data is Map<String, dynamic> && data.containsKey('data'))
            ? data['data']
            : data;

        return VehicleDetails(
          registrationNumber: cleanRegNo,

          // Basic Info
          make: (info['make_name'] ?? info['make_name2'] ?? 'Unknown')
              .toString(),
          model: (info['model_name'] ?? info['model_name2'] ?? 'Unknown Model')
              .toString(),
          modelYear: (info['registration_year'] ?? DateTime.now().year)
              .toString(),
          fuelType: (info['fuel_type'] ?? 'Petrol').toString(),

          // Owner Info
          ownerName: (info['owner_name'] ?? '').toString(),
          rtoLocation: (info['registration_address'] ?? '').toString(),

          // Insurance Info (NEW!)
          insurer: (info['previous_insurer'] ?? '').toString(),
          policyExpiry: (info['previous_policy_expiry_date'] ?? '').toString(),

          // Technical
          chassisNumber: (info['chassis_number'] ?? '').toString(),
          engineNumber: (info['engine_number'] ?? '').toString(),
        );
      }
      return null;
    } catch (e) {
      print('❌ RTO Error: $e');
      return null;
    }
  }
}

class VehicleDetails {
  final String registrationNumber;
  final String make;
  final String model;
  final String modelYear;
  final String fuelType;
  final String ownerName;
  final String rtoLocation; // e.g. Mumbai Central
  final String insurer; // e.g. Future Generali
  final String policyExpiry; // e.g. 05-Sep-2027
  final String chassisNumber;
  final String engineNumber;

  VehicleDetails({
    required this.registrationNumber,
    required this.make,
    required this.model,
    required this.modelYear,
    required this.fuelType,
    required this.ownerName,
    required this.rtoLocation,
    required this.insurer,
    required this.policyExpiry,
    required this.chassisNumber,
    required this.engineNumber,
  });
}
