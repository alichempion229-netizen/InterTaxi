import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';
import 'role_selection_screen.dart';

/// InterTaxi Welcome Registration Screen
/// Glassmorphism (blue & white theme), fully self-contained
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _phoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _avatarBytes;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthYearController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Номро ворид кунед';
    }
    if (value.length < AppConstants.minNameLength) {
      return 'Ном бояд на камтар аз 2 ҳарф бошад';
    }
    if (value.length > AppConstants.maxNameLength) {
      return 'Ном бояд на зиёда аз 50 ҳарф бошад';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Насабро ворид кунед';
    }
    if (value.length < AppConstants.minNameLength) {
      return 'Насаб бояд на камтар аз 2 ҳарф бошад';
    }
    if (value.length > AppConstants.maxNameLength) {
      return 'Насаб бояд на зиёда аз 50 ҳарф бошад';
    }
    return null;
  }

  String? _validateBirthYear(String? value) {
    if (value == null || value.isEmpty) {
      return 'Соли таваллудро ворид кунед';
    }

    final year = int.tryParse(value);
    if (year == null) {
      return 'Соли таваллуд бояд рақам бошад';
    }

    final currentYear = DateTime.now().year;
    if (year < AppConstants.minBirthYear || year > currentYear) {
      return 'Соли таваллуд бояд миёни ${AppConstants.minBirthYear} ва $currentYear бошад';
    }

    final age = currentYear - year;
    if (age < 18) {
      return 'Шумо бояд на камтар аз 18 сол дошта бошед';
    }
    if (age > 120) {
      return 'Соли таваллуд нодуруст ворид шудааст';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Рақами телефонро ворид кунед';
    }
    if (value.length < AppConstants.minPhoneLength) {
      return 'Рақами телефон бояд на камтар аз 9 рақам бошад';
    }
    if (value.length > AppConstants.maxPhoneLength) {
      return 'Рақами телефон бояд на зиёда аз 15 рақам бошад';
    }
    return null;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _avatarBytes = bytes;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              final passengerName =
                  '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
              final passengerPhone = _phoneController.text.trim();

              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      RoleSelectionScreen(
                        passengerName: passengerName,
                        passengerPhone: passengerPhone,
                      ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Заминаи gradient-и кабуди тира
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A1930),
                  Color(0xFF123B6B),
                  Color(0xFF0A1930),
                ],
              ),
            ),
          ),
          // Блоби нурии кабуд-blur (glass "light source")
          Positioned(
            top: -80,
            left: -60,
            child: _GlowBlob(color: const Color(0xFF38BDF8), size: 240),
          ),
          Positioned(
            top: 220,
            right: -90,
            child: _GlowBlob(color: const Color(0xFF60A5FA), size: 260),
          ),
          Positioned(
            bottom: -100,
            left: -40,
            child: _GlowBlob(color: const Color(0xFF93C5FD), size: 220),
          ),
          // Контенти асосӣ
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: _GlassAvatarPicker(
                        avatarBytes: _avatarBytes,
                        onTap: _pickImage,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Акси худро илова кунед',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Карти шишагин
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Хуш омадед ба InterTaxi',
                            style: TextStyle(
                              fontSize: AppConstants.welcomeTitleSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Барои истифодаи хизматрасониҳо, маълумоти худро ворид кунед',
                            style: TextStyle(
                              fontSize: AppConstants.welcomeSubtitleSize,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.75),
                              letterSpacing: 0.2,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _GlassTextField(
                            label: 'Ном',
                            hintText: 'Номи худро ворид кунед',
                            controller: _firstNameController,
                            validator: _validateFirstName,
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: AppConstants.fieldSpacing),
                          _GlassTextField(
                            label: 'Насаб',
                            hintText: 'Насаби худро ворид кунед',
                            controller: _lastNameController,
                            validator: _validateLastName,
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: AppConstants.fieldSpacing),
                          _GlassTextField(
                            label: 'Соли таваллуд',
                            hintText: 'Масалан: 1995',
                            controller: _birthYearController,
                            keyboardType: TextInputType.number,
                            validator: _validateBirthYear,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: AppConstants.fieldSpacing),
                          _GlassTextField(
                            label: 'Рақами телефон',
                            hintText: 'Масалан: +992 90 123 45 67',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: _validatePhone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(15),
                            ],
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 32),
                          _GlassButton(
                            text: 'Идома додан',
                            onPressed: _handleSubmit,
                            isLoading: _isLoading,
                            enabled: !_isLoading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Ба давом додан, шумо қабул мекунед',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // TODO: Show terms and conditions
                        },
                        child: Text(
                          'Шартҳои истифода',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7DD3FC),
                            letterSpacing: 0.2,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Блоби нурии blur-шуда
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.5),
        ),
      ),
    );
  }
}

/// Панели шишагӣ: blur + шаффофияти сафед + канори равшан + соя
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withOpacity(0.10),
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassAvatarPicker extends StatelessWidget {
  final Uint8List? avatarBytes;
  final VoidCallback onTap;
  const _GlassAvatarPicker({required this.avatarBytes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.5,
                  ),
                  image: avatarBytes != null
                      ? DecorationImage(
                          image: MemoryImage(avatarBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarBytes == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 46,
                        color: Colors.white.withOpacity(0.9),
                      )
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Майдони воридоти шишагӣ — комилан мустақил, аз CustomTextField-и берунӣ вобаста нест
class _GlassTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;

  const _GlassTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.85),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: TextFormField(
                controller: controller,
                validator: validator,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                textInputAction: textInputAction,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: const Color(0xFF38BDF8),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  errorStyle: const TextStyle(
                    color: Color(0xFFFCA5A5),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Тугмаи шишагии асосӣ — gradient кабуд
class _GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;

  const _GlassButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: enabled
                  ? [const Color(0xFF38BDF8), const Color(0xFF3B82F6)]
                  : [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.2),
                    ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
