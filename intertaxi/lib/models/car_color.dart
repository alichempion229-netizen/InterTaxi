import 'package:flutter/material.dart';

/// Shared color-name resolver for vehicle cards and trip details.
Color carColorSwatch(String value, {Color fallback = const Color(0xFFB8C0CC)}) {
  final color = value.trim().toLowerCase();
  if (color.isEmpty) return fallback;
  if (['silver', 'gray', 'grey', 'хокистарӣ', 'хокистари', 'нуқрагун', 'серебристый', 'серебряный', 'серый'].contains(color)) return const Color(0xFFB8C0CC);
  if (['white', 'сафед', 'белый'].contains(color)) return const Color(0xFFE8EDF5);
  if (['black', 'сиёҳ', 'черный', 'чёрный'].contains(color)) return const Color(0xFF252A34);
  if (['blue', 'кабуд', 'синий'].contains(color)) return const Color(0xFF1769E0);
  if (['red', 'сурх', 'красный'].contains(color)) return const Color(0xFFE53935);
  if (['purple', 'нилфари', 'фиолетовый'].contains(color)) return const Color(0xFF8E44AD);
  if (['orange', 'норанҷӣ', 'оранжевый'].contains(color)) return const Color(0xFFF5A623);
  if (['green', 'сабз', 'зеленый', 'зелёный'].contains(color)) return const Color(0xFF35A66F);
  if (['yellow', 'зард', 'желтый', 'жёлтый'].contains(color)) return const Color(0xFFFFC107);
  // Values used by the older color picker were saved as mojibake text.
  if (color == 'РљСѓР»'.toLowerCase()) return const Color(0xFFB8C0CC);
  if (color == 'РЎР°С„РµРґ'.toLowerCase()) return const Color(0xFFE8EDF5);
  if (color == 'РЎРёС‘Ті'.toLowerCase()) return const Color(0xFF252A34);
  if (color == 'РљР°Р±СѓРґ'.toLowerCase()) return const Color(0xFF1769E0);
  if (color == 'РЎСѓСЂС…'.toLowerCase()) return const Color(0xFFE53935);
  if (color == 'РЎР°Р±Р·'.toLowerCase()) return const Color(0xFF35A66F);
  if (color == 'Р—Р°СЂРґ'.toLowerCase()) return const Color(0xFFFFC107);
  // Legacy mojibake values stay neutral rather than misleadingly blue.
  if (color.contains('РЅСѓ')) return const Color(0xFFB8C0CC);
  return fallback;
}
