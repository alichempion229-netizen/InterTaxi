import 'package:latlong2/latlong.dart';

import '../widgets/city_selection_modal.dart';

/// Coordinates follow the exact order of [tajikCities], so every selectable
/// location always has a coordinate under its canonical picker name.
final Map<String, LatLng> tajikLocationCoordinates = Map.unmodifiable({
  for (var i = 0; i < tajikCities.length; i++)
    tajikCities[i]: _locationPoints[i],
});

String normalizeLocationName(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('ӯ', 'у')
    .replaceAll('ӣ', 'и')
    .replaceAll('ҳ', 'х')
    .replaceAll('ҷ', 'ч')
    .replaceAll('қ', 'к')
    .replaceAll('ғ', 'г')
    .replaceAll('ё', 'е')
    .replaceAll(RegExp("['’‘ʼ`´]"), '')
    .split(RegExp(r'\s+'))
    .where((word) => !const {'нохияи', 'шахри', 'район'}.contains(word))
    .join(' ');

LatLng? locationCoordinatesFor(String? locationName) {
  if (locationName == null || locationName.trim().isEmpty) return null;
  var normalizedName = normalizeLocationName(locationName);
  if (normalizedName == 'канибодом') normalizedName = 'конибодом';
  if (normalizedName == 'явон') normalizedName = 'евон';
  for (final entry in tajikLocationCoordinates.entries) {
    if (normalizeLocationName(entry.key) == normalizedName) return entry.value;
  }
  return null;
}

double? approximateDrivingDistanceKm(String? from, String? to) {
  final fromPoint = locationCoordinatesFor(from);
  final toPoint = locationCoordinatesFor(to);
  if (fromPoint == null || toPoint == null) return null;
  return const Distance().as(LengthUnit.Kilometer, fromPoint, toPoint) * 1.3;
}

int? approximateDrivingDurationMinutes(String? from, String? to) {
  final distanceKm = approximateDrivingDistanceKm(from, to);
  return distanceKm == null ? null : (distanceKm / 50 * 60).round();
}

const List<LatLng> _locationPoints = [
  // Cities
  LatLng(38.5598, 68.7870), LatLng(40.2826, 69.6222),
  LatLng(37.8368, 68.7802), LatLng(37.9146, 69.7847),
  LatLng(37.4893, 71.5532), LatLng(38.5126, 68.2312),
  LatLng(38.5563, 69.0135), LatLng(38.5256, 68.5512),
  LatLng(39.4952, 67.6093), LatLng(39.9142, 69.0033),
  LatLng(40.1228, 70.5983), LatLng(40.2833, 70.4333),
  LatLng(40.3000, 69.6333), LatLng(40.5228, 69.3331),
  LatLng(40.5689, 69.6403), // Истиқлол // ADDED
  LatLng(38.3892, 69.3227),
  LatLng(37.8714, 68.9223), // Левакант // ADDED
  LatLng(38.6933, 69.7369),
  // Districts (approximate administrative-center coordinates)
  LatLng(39.4000, 68.5333), LatLng(39.8333, 69.9667),
  LatLng(40.2167, 68.8333), LatLng(39.5167, 68.3333),
  LatLng(39.6500, 68.9500), LatLng(39.1000, 69.5500),
  LatLng(39.1167, 69.5333), LatLng(40.2208, 69.3400),
  LatLng(39.7833, 68.8167), LatLng(40.2458, 69.5000),
  LatLng(38.9500, 70.2500), LatLng(38.4578, 70.7816),
  LatLng(36.7167, 71.6167), LatLng(38.1667, 73.9667),
  LatLng(37.3167, 71.4833), LatLng(37.5333, 71.5000),
  LatLng(37.5000, 71.5000), LatLng(38.3167, 69.6667),
  LatLng(37.7000, 68.8333), LatLng(37.8042, 69.6442),
  LatLng(38.0983, 69.3384), LatLng(37.3500, 68.6667),
  LatLng(37.2667, 68.1500), LatLng(37.4667, 68.5333),
  LatLng(37.6333, 68.5333), LatLng(37.2833, 68.1333),
  LatLng(37.2333, 68.1333), LatLng(37.4308, 68.0839),
  LatLng(37.7667, 68.8167), LatLng(38.1083, 70.0325),
  LatLng(38.2500, 69.5833), LatLng(37.4922, 69.4036),
  LatLng(38.3417, 69.9667), LatLng(37.5333, 68.7667),
  LatLng(37.2625, 68.1381), LatLng(37.2667, 68.1500),
  LatLng(38.3090, 69.0558), LatLng(38.4667, 70.6500),
  LatLng(38.7833, 68.8167), LatLng(39.0500, 70.4667),
  LatLng(38.8167, 70.1833), LatLng(39.0286, 70.3733),
  LatLng(38.5500, 68.7667), LatLng(38.7167, 70.1667),
  LatLng(38.1833, 70.0333), LatLng(38.5473, 69.2132),
  LatLng(38.5667, 68.3333),
];
