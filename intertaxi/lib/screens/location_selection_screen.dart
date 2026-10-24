import 'package:intertaxi/app_icons.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// InterTaxi Location Selection Screen
/// Simple screen for selecting cities
class LocationSelectionScreen extends StatefulWidget {
  final String title;
  final List<String> locations;
  final String? selectedLocation;
  final ValueChanged<String>? onSelect;

  const LocationSelectionScreen({
    super.key,
    required this.title,
    required this.locations,
    this.selectedLocation,
    this.onSelect,
  });

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = widget.locations
        .where(
          (location) =>
              location.toLowerCase().contains(_query.trim().toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0052CC), Color(0xFF4D94FF)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            AppIcons.location_on_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Масирро дақиқ интихоб кунед',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.title.contains('Аз куҷо')
                          ? 'Нуқтаи оғози сафарро интихоб кунед'
                          : 'Нуқтаи расидани сафарро интихоб кунед',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text(
                    'Шаҳрҳо',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${locations.length} шаҳр',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Шаҳрро ҷустуҷӯ кунед',
                  prefixIcon: const Icon(AppIcons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(AppIcons.close_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5EAF2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF0066FF),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Location List
              Expanded(
                child: ListView.builder(
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final location = locations[index];
                    final isSelected = widget.selectedLocation == location;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          widget.onSelect?.call(location);
                          Navigator.of(context).pop(location);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.cardBorder,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Location icon with background
                              Container(
                                width: 44,
                                height: 44,
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.white.withValues(alpha: 0.2)
                                      : AppColors.lightBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  AppIcons.location_on_rounded,
                                  size: 20,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Location name
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              // Check icon
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    AppIcons.check_rounded,
                                    color: AppColors.primaryBlue,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
