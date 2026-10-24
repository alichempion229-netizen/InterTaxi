/// Driver vehicle brands and their bundled local logo assets.
///
/// Logos are loaded from the app bundle, so the picker never waits on a network
/// request. SVGs stay crisp and small; raster assets are decoded at icon size.
class CarBrand {
  final String name;
  final String logoAsset;

  const CarBrand(this.name, this.logoAsset);
}

const List<CarBrand> supportedCarBrands = [
  CarBrand('Toyota', 'assets/logos/cars/toyota-logo.svg'),
  CarBrand('Mercedes-Benz', 'assets/logos/cars/mercedes-benz-logo.svg'),
  CarBrand('BMW', 'assets/logos/cars/bmw-logo.svg'),
  CarBrand('Lexus', 'assets/logos/cars/lexus-logo.png'),
  CarBrand('Hyundai', 'assets/logos/cars/hyundai-logo.svg'),
  CarBrand('Kia', 'assets/logos/cars/kia-logo.svg'),
  CarBrand('Chevrolet', 'assets/logos/cars/chevrolet-logo.png'),
  CarBrand('Opel', 'assets/logos/cars/opel-logo.svg'),
  CarBrand('Daewoo', 'assets/logos/cars/daewoo-logo.png'),
  CarBrand('Volkswagen', 'assets/logos/cars/volkswagen-logo.svg'),
  CarBrand('Audi', 'assets/logos/cars/audi-logo.svg'),
  CarBrand('Ford', 'assets/logos/cars/ford-logo.png'),
  CarBrand('Honda', 'assets/logos/cars/honda-logo.png'),
  CarBrand('Nissan', 'assets/logos/cars/nissan-logo.svg'),
  CarBrand('Mazda', 'assets/logos/cars/mazda-logo.svg'),
  CarBrand('Mitsubishi', 'assets/logos/cars/mitsubishi-logo.svg'),
  CarBrand('Subaru', 'assets/logos/cars/subaru-logo.png'),
  CarBrand('Suzuki', 'assets/logos/cars/suzuki-logo.svg'),
  CarBrand('Renault', 'assets/logos/cars/renault-logo.svg'),
  CarBrand('Peugeot', 'assets/logos/cars/peugeot-logo.svg'),
  CarBrand('Citroën', 'assets/logos/cars/citroen-logo.svg'),
  CarBrand('Skoda', 'assets/logos/cars/skoda-logo.svg'),
  CarBrand('Volvo', 'assets/logos/cars/volvo-logo.svg'),
  CarBrand('Land Rover', 'assets/logos/cars/land-rover-logo.svg'),
  CarBrand('Range Rover', 'assets/logos/cars/range-rover-logo.svg'),
  CarBrand('Porsche', 'assets/logos/cars/porsche-logo.svg'),
  CarBrand('Tesla', 'assets/logos/cars/tesla-logo.svg'),
  CarBrand('BYD', 'assets/logos/cars/byd-logo.svg'),
  CarBrand('Chery', 'assets/logos/cars/chery-logo.png'),
  CarBrand('Geely', 'assets/logos/cars/geely-logo.svg'),
  CarBrand('Haval', 'assets/logos/cars/haval-logo.png'),
  CarBrand('GAC', 'assets/logos/cars/gac-logo.png'),
  CarBrand('Changan', 'assets/logos/cars/changan-logo.png'),
  CarBrand('Jetour', 'assets/logos/cars/jetour-logo.svg'),
  CarBrand('JAC', 'assets/logos/cars/jac-logo.png'),
  CarBrand('Great Wall', 'assets/logos/cars/great-wall-logo.png'),
  CarBrand('FAW', 'assets/logos/cars/faw-logo.svg'),
  CarBrand('Dongfeng', 'assets/logos/cars/dongfeng-logo.png'),
  CarBrand('Foton', 'assets/logos/cars/foton-logo.svg'),
  CarBrand('Lifan', 'assets/logos/cars/lifan-logo.svg'),
  CarBrand('Neta', 'assets/logos/cars/neta-logo.svg'),
  CarBrand('Aion', 'assets/logos/cars/aion-logo.svg'),
  CarBrand('Exeed', 'assets/logos/cars/exeed-logo.png'),
  CarBrand('MG', 'assets/logos/cars/mg-logo.svg'),
  CarBrand('Genesis', 'assets/logos/cars/genesis-logo.svg'),
  CarBrand('Cadillac', 'assets/logos/cars/cadillac-logo.png'),
  CarBrand('Jeep', 'assets/logos/cars/jeep-logo.svg'),
  CarBrand('Dodge', 'assets/logos/cars/dodge-logo.svg'),
  CarBrand('Infiniti', 'assets/logos/cars/infiniti-logo.svg'),
];

String? carBrandLogoAsset(String brand) {
  final normalized = brand.trim().toLowerCase();
  final canonical = switch (normalized) {
    'mercedes' => 'mercedes-benz',
    _ => normalized,
  };
  for (final item in supportedCarBrands) {
    if (item.name.toLowerCase() == canonical) return item.logoAsset;
  }
  return null;
}

bool isSameCarBrand(String first, String second) =>
    (carBrandLogoAsset(first) ?? first.trim().toLowerCase()) ==
    (carBrandLogoAsset(second) ?? second.trim().toLowerCase());
