import 'package:intertaxi/l10n/app_localizations.dart';
import 'package:intertaxi/app_icons.dart';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../constants/light_glass_theme.dart';
import 'light_glass_widgets.dart';

const String kUserAvatarPathKey = 'user_avatar_path';

Future<ImageSource?> showAvatarSourcePicker(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: LightGlassColors.textPrimary.withValues(alpha: 0.35),
    builder: (sheetContext) => ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(LightGlassRadius.panel),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
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
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
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
                Padding(
                  padding: EdgeInsets.all(AppConstants.screenPadding),
                  child: Text(
                    AppLocalizations.translate('Расми профил'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: LightGlassColors.textPrimary,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.photo_library_rounded,
                    color: LightGlassColors.primaryBlue,
                  ),
                  title: Text(
                    AppLocalizations.translate('Галерея'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: LightGlassColors.textPrimary,
                    ),
                  ),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.photo_camera_rounded,
                    color: LightGlassColors.primaryBlue,
                  ),
                  title: Text(
                    AppLocalizations.translate('Камера'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: LightGlassColors.textPrimary,
                    ),
                  ),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<String?> pickAndSaveAvatar({
  required BuildContext context,
  required ImageSource source,
}) async {
  try {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kUserAvatarPathKey, file.path);
    return file.path;
  } catch (_) {
    return null;
  }
}

class ProfileEditResult {
  final String fullName;
  final String phone;
  final String gender;
  final String birthYear;
  final String avatarPath;

  const ProfileEditResult({
    required this.fullName,
    required this.phone,
    required this.gender,
    required this.birthYear,
    required this.avatarPath,
  });
}

Future<ProfileEditResult?> showProfileEditSheet({
  required BuildContext context,
  required String currentName,
  required String currentPhone,
  required String currentGender,
  required String currentBirthYear,
  required String currentAvatarPath,
}) {
  return showModalBottomSheet<ProfileEditResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: LightGlassColors.textPrimary.withValues(alpha: 0.35),
    builder: (sheetContext) => _ProfileEditSheet(
      currentName: currentName,
      currentPhone: currentPhone,
      currentGender: currentGender,
      currentBirthYear: currentBirthYear,
      currentAvatarPath: currentAvatarPath,
    ),
  );
}

class _ProfileEditSheet extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final String currentGender;
  final String currentBirthYear;
  final String currentAvatarPath;

  const _ProfileEditSheet({
    required this.currentName,
    required this.currentPhone,
    required this.currentGender,
    required this.currentBirthYear,
    required this.currentAvatarPath,
  });

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthYearController;

  String? _selectedGender;
  bool _isSaving = false;
  String _avatarPath = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _birthYearController = TextEditingController(text: widget.currentBirthYear);
    _selectedGender = widget.currentGender.isEmpty
        ? null
        : widget.currentGender;
    _avatarPath = widget.currentAvatarPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final source = await showAvatarSourcePicker(context);
    if (source == null || !mounted) return;
    final path = await pickAndSaveAvatar(context: context, source: source);
    if (path == null || !mounted) return;
    setState(() => _avatarPath = path);
  }

  Widget _buildAvatarHeader() {
    final hasAvatar = _avatarPath.isNotEmpty;
    return Center(
      child: GestureDetector(
        onTap: _pickAvatar,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LightGlassColors.lightBlue,
                border: Border.all(
                  color: LightGlassColors.glassBorderSubtle,
                  width: 1.5,
                ),
                image: hasAvatar
                    ? DecorationImage(
                        image: FileImage(File(_avatarPath)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: hasAvatar
                  ? null
                  : const Icon(
                      AppIcons.person_rounded,
                      size: 46,
                      color: LightGlassColors.primaryBlue,
                    ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  gradient: LightGlassGradients.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.photo_camera_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final birthYear = _birthYearController.text.trim();
      final gender = _selectedGender ?? '';
      final parts = name.split(' ');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      await prefs.setString('user_phone', phone);
      await prefs.setString('user_first_name', parts.first);
      await prefs.setString(
        'user_last_name',
        parts.length > 1 ? parts.sublist(1).join(' ') : '',
      );
      await prefs.setString('user_gender', gender);
      await prefs.setString('user_birth_year', birthYear);

      if (!mounted) return;
      Navigator.of(context).pop(
        ProfileEditResult(
          fullName: name,
          phone: phone,
          gender: gender,
          birthYear: birthYear,
          avatarPath: _avatarPath,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'Хатогӣ — маълумот нигоҳ дошта нашуд',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(LightGlassRadius.panel),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.97),
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
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      AppLocalizations.translate(
                        'Таҳрир кардани профил',
                      ),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: LightGlassColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildAvatarHeader(),
                    const SizedBox(height: 20),
                    LightGlassTextField(
                      controller: _nameController,
                      label: AppLocalizations.translate('Ному насаб'),
                      prefixIcon: const Icon(
                        AppIcons.person_rounded,
                        color: LightGlassColors.primaryBlue,
                      ),
                      validator: (v) =>
                          (v == null ||
                              v.trim().length < AppConstants.minNameLength)
                          ? 'Ном хеле кӯтоҳ аст'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    LightGlassTextField(
                      controller: _phoneController,
                      label: AppLocalizations.translate(
                        'Рақами телефон',
                      ),
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(
                        AppIcons.phone_rounded,
                        color: LightGlassColors.primaryBlue,
                      ),
                      validator: (v) =>
                          (v == null ||
                              v.trim().length < AppConstants.minPhoneLength)
                          ? 'Рақами телефон нодуруст аст'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: LightGlassColors.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.translate('Ҷинс'),
                        prefixIcon: const Icon(
                          AppIcons.wc_rounded,
                          color: LightGlassColors.primaryBlue,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'Мард',
                          child: Text(
                            AppLocalizations.translate('Мард'),
                            style: TextStyle(
                              color: LightGlassColors.textPrimary,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Зан',
                          child: Text(
                            AppLocalizations.translate('Зан'),
                            style: TextStyle(
                              color: LightGlassColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedGender = value),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Ҷинсро интихоб кунед'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    LightGlassTextField(
                      controller: _birthYearController,
                      label: AppLocalizations.translate(
                        'Соли таваллуд',
                      ),
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(
                        AppIcons.cake_rounded,
                        color: LightGlassColors.primaryBlue,
                      ),
                      validator: (v) {
                        final raw = v?.trim() ?? '';
                        if (raw.isEmpty)
                          return AppLocalizations.translate(
                            'Соли таваллудро ворид кунед',
                          );
                        final year = int.tryParse(raw);
                        if (year == null)
                          return AppLocalizations.translate(
                            'Соли таваллуд бояд рақам бошад',
                          );
                        final currentYear = DateTime.now().year;
                        if (year < 1900 || year > currentYear) {
                          return AppLocalizations.translate(
                            'Соли таваллуд нодуруст аст',
                          );
                        }
                        if (currentYear - year < 18) {
                          return AppLocalizations.translate(
                            'Шумо бояд на камтар аз 18 сол дошта бошед',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    LightGlassButton(
                      text: AppLocalizations.translate(
                        'Нигоҳ доштан',
                      ),
                      onPressed: _save,
                      isLoading: _isSaving,
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
