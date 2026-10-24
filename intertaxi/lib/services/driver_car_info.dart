import 'package:shared_preferences/shared_preferences.dart';

class DriverCarInfo {
  final String brand;
  final String model;
  final String plate;
  final String color;
  final List<String> photoPaths;

  const DriverCarInfo({
    required this.brand,
    required this.model,
    required this.plate,
    required this.color,
    required this.photoPaths,
  });
}

Future<DriverCarInfo> loadDriverCarInfo() async {
  final prefs = await SharedPreferences.getInstance();
  return DriverCarInfo(
    brand: prefs.getString('driver_car_brand') ?? '',
    model: prefs.getString('driver_car_model') ?? '',
    plate: prefs.getString('driver_plate_number') ?? '',
    color: prefs.getString('driver_car_color') ?? '',
    photoPaths: List<String>.generate(
      3,
      (index) => prefs.getString('driver_car_photo_${index + 1}') ?? '',
    ),
  );
}
