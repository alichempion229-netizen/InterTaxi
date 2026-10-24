import 'package:intertaxi/l10n/app_localizations.dart';
import 'package:intertaxi/app_icons.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../constants/light_glass_theme.dart';
import 'light_glass_widgets.dart';

/// The supported Tajik cities / districts available for route selection.
const List<String> tajikCities = [
  'Душанбе',
  'Кӯлоб',
  'Восеъ',
  'Хуҷанд',
  'Бохтар',
  'Канибодом',
  'Исфара',
  'Файзобод',
  'Турсунзода',
  'Панҷакент',
  'Истаравшан',
  'Ваҳдат',
  'ТІРёСЃРѕСЂ',
  'РҐРѕСЂСѓТ“',
  'Данғара',
  'РЇРІРѕРЅ',
  'Рашт',
  'Шаҳритус',
  'Қубодиён',
  'Ҷаббор Расулов',
  'Спитамен',
  'Дарвоз',
];

/// Shows a Modal Bottom Sheet with the list of Tajik cities in Glassmorphism style.
Future<String?> showCitySelectionSheet({
  required BuildContext context,
  required String title,
  List<String> cities = tajikCities,
  String? selectedCity,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: LightGlassColors.textPrimary.withValues(alpha: 0.35),
    isScrollControlled: true,
    builder: (_) => _CitySelectionSheet(
      title: title,
      cities: cities,
      selectedCity: selectedCity,
    ),
  );
}

class _CitySelectionSheet extends StatefulWidget {
  final String title;
  final List<String> cities;
  final String? selectedCity;

  const _CitySelectionSheet({
    required this.title,
    required this.cities,
    this.selectedCity,
  });

  @override
  State<_CitySelectionSheet> createState() => _CitySelectionSheetState();
}

class _CitySelectionSheetState extends State<_CitySelectionSheet> {
  String _query = '';

  List<String> get _filteredCities {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.cities;
    return widget.cities
        .where((city) => city.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(LightGlassRadius.panel),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(LightGlassRadius.panel),
            ),
            border: Border(
              top: BorderSide(
                color: LightGlassColors.glassBorderSubtle,
                width: 1.2,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                // Drag handle pill
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: LightGlassColors.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPadding,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: LightGlassColors.primaryBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: LightGlassColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppLocalizations.translate(
                                'Шаҳр ё ноҳияро интихоб кунед',
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                color: LightGlassColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          foregroundColor: LightGlassColors.primaryBlue,
                          backgroundColor: LightGlassColors.lightBlue,
                        ),
                        icon: const Icon(AppIcons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPadding,
                  ),
                  child: LightGlassTextField(
                    hintText: AppLocalizations.translate(
                      'Ҷустуҷӯи шаҳр...',
                    ),
                    prefixIcon: const Icon(
                      AppIcons.search_rounded,
                      color: LightGlassColors.primaryBlue,
                    ),
                    onChanged: (value) => setState(() => _query = value),
                    dense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(child: _buildCitiesList(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCitiesList(BuildContext context) {
    final filteredCities = _filteredCities;

    if (filteredCities.isEmpty) {
      return ListView(
        shrinkWrap: true,
        padding: EdgeInsets.only(
          left: AppConstants.screenPadding,
          right: AppConstants.screenPadding,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(
                  AppIcons.search_off_rounded,
                  size: 48,
                  color: LightGlassColors.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.translate('Шаҳр ёфт нашуд'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: LightGlassColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.only(
        left: AppConstants.screenPadding,
        right: AppConstants.screenPadding,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      itemCount: filteredCities.length,
      itemBuilder: (context, index) {
        final city = filteredCities[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _CityTile(
            city: city,
            isSelected: city == widget.selectedCity,
            onTap: () => Navigator.of(context).pop(city),
          ),
        );
      },
    );
  }
}

class _CityTile extends StatelessWidget {
  final String city;
  final bool isSelected;
  final VoidCallback onTap;

  const _CityTile({
    required this.city,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LightGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 16,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? LightGlassColors.lightBlue
                  : LightGlassColors.surfaceTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.location_on_rounded,
              size: 20,
              color: LightGlassColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              city,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: LightGlassColors.textPrimary,
              ),
            ),
          ),
          if (isSelected)
            const Icon(
              AppIcons.check_circle_rounded,
              size: 20,
              color: LightGlassColors.primaryBlue,
            ),
        ],
      ),
    );
  }
}
