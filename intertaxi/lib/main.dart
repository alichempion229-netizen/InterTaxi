import 'package:intertaxi/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' show TickerCanceled;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'constants/light_glass_theme.dart';
import 'screens/passenger_home_screen.dart';
import 'screens/driver_earnings_screen.dart';
import 'screens/server_settings_screen.dart';
import 'screens/google_sign_in_screen.dart';
import 'screens/role_selection_screen.dart' as role_selection;
import 'models/car_brand.dart';
import 'services/api_service.dart';
import 'services/driver_car_info.dart';
import 'services/socket_service.dart';
import 'services/trip_voice_assistant.dart';
import 'widgets/intertaxi_logo.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/animated_tab_body.dart';
import 'widgets/city_selection_modal.dart';
import 'data/tajik_location_coordinates.dart';
import 'utils/app_route.dart';

const String _appSessionVersion = 'intertaxi_session_v2';

Map<String, Object>? _decodeCarPickerImage(String path) {
  try {
    final decoded = img.decodeImage(File(path).readAsBytesSync());
    if (decoded == null) return null;
    final oriented = img.bakeOrientation(decoded);
    final resized = oriented.width > 800
        ? img.copyResize(oriented, width: 800)
        : oriented;
    final rgbBytes = Uint8List(resized.width * resized.height * 3);
    var offset = 0;
    for (var y = 0; y < resized.height; y++) {
      for (var x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        rgbBytes[offset++] = pixel.r.round();
        rgbBytes[offset++] = pixel.g.round();
        rgbBytes[offset++] = pixel.b.round();
      }
    }
    return {
      'width': resized.width,
      'height': resized.height,
      'rgb': rgbBytes,
      'preview': Uint8List.fromList(img.encodePng(resized)),
    };
  } catch (_) {
    return null;
  }
}

class _AnimatedCarLoading extends StatefulWidget {
  final Color color;

  const _AnimatedCarLoading({this.color = Colors.white});

  @override
  State<_AnimatedCarLoading> createState() => _AnimatedCarLoadingState();
}

class _AnimatedCarLoadingState extends State<_AnimatedCarLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: Icon(
        AppIcons.directions_car_rounded,
        color: widget.color,
        size: 22,
      ),
      builder: (context, child) =>
          Transform.rotate(angle: _controller.value * 6.28318, child: child),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('Firebase initialization failed: $error');
  }
  runApp(const InterTaxiApp());
}

/* class InterTaxiApp extends StatelessWidget {
  const InterTaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InterTaxi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066FF),
          brightness: Brightness.light,
        ),
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isOnline
                                          ? const Color(0xFF22C55E)
                                          : Colors.grey,
                                      width: 3,
                                    ),
                                    image: _profileImage != null
                                        ? DecorationImage(
                                            image: MemoryImage(_profileImage!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _profileImage == null
                                      ? const Icon(
                                          AppIcons.person_rounded,
                                          size: 36,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0066FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      AppIcons.add,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 42),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['full_name'] ?? 'Ронанда',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.16,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.24,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Ронанда',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(
                                            alpha: 0.92,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          AppIcons.phone_rounded,
                                          size: 14,
                                          color: Colors.white.withValues(
                                            alpha: 0.82,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            data['phone'] ?? '—',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white.withValues(
                                                alpha: 0.82,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.16),
                            shape: const CircleBorder(),
                            child: IconButton(
                              onPressed: _openSettingsScreen,
                              tooltip: 'Танзимот',
                              icon: const Icon(
                                AppIcons.settings_rounded,
                                size: 23,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                      'InterTaxi',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Your ride, your way',
                                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 40),
                                        const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(0xFF0066FF),
                                          ),
                                        ),
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your ride, your way',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0066FF),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

*/

class InterTaxiApp extends StatelessWidget {
  const InterTaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InterTaxi',
      debugShowCheckedModeBanner: false,
      theme: buildLightGlassTheme(),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _introController,
    curve: Curves.easeOutBack,
  );

  @override
  void initState() {
    super.initState();
    // The Android launch screen already shows the app logo; start the Flutter
    // splash with the same visible mark on its very first frame.
    _introController.value = 0.86;
    _introController.forward();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    final splashStartedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final remaining =
        const Duration(milliseconds: 1450) -
        DateTime.now().difference(splashStartedAt);
    if (remaining > Duration.zero) await Future.delayed(remaining);
    if (!mounted) return;

    User? firebaseUser;
    try {
      firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        firebaseUser = await FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(const Duration(seconds: 8));
      }
    } catch (error) {
      debugPrint('Could not restore Firebase session: $error');
    }

    if (firebaseUser == null) {
      AppRoute.replace<void, void>(
        context,
        GoogleSignInScreen(onSignedIn: _navigateAuthenticatedUser),
      );
      return;
    }

    await _navigateAuthenticatedUser(context);
  }

  Future<void> _navigateAuthenticatedUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;
    final name = prefs.getString('user_name');
    final phone = prefs.getString('user_phone');
    final role = prefs.getString('user_role');

    if (name != null && name.isNotEmpty && phone != null && phone.isNotEmpty) {
      if (role == 'driver') {
        AppRoute.replaceAll<void>(
          context,
          DriverHomeScreen(driverName: name, driverPhone: phone),
        );
        return;
      } else if (role == 'passenger') {
        AppRoute.replaceAll<void>(
          context,
          PassengerHomeScreen(passengerName: name, passengerPhone: phone),
        );
        return;
      }
    }

    // Google authentication comes first; local profile setup follows it.
    AppRoute.replaceAll<void>(context, const RegistrationScreen());
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4F8FF), Color(0xFFE7F0FF), Color(0xFFDCEAFF)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _logoScale,
                child: Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .82),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A1557B8),
                        blurRadius: 32,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Center(
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _introController,
                        curve: Curves.easeOut,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.asset(
                          'assets/icon.png',
                          width: 112,
                          height: 112,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                AppIcons.local_taxi_rounded,
                                size: 96,
                                color: Color(0xFF1769E0),
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF1557B8).withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 22,
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: Colors.transparent,
                      color: Color(0xFF1557B8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _birthYearController;
  late final TextEditingController _phoneController;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _avatarBytes;
  bool _isLoading = false;
  String? _passengerName;
  String? _selectedGender;
  bool _hasSubmitted = false;
  late final FocusNode _firstNameFocus;
  late final FocusNode _lastNameFocus;
  late final FocusNode _genderFocus;
  late final FocusNode _birthYearFocus;
  late final FocusNode _phoneFocus;
  final _firstNameFieldKey = GlobalKey();
  final _lastNameFieldKey = GlobalKey();
  final _genderFieldKey = GlobalKey();
  final _birthYearFieldKey = GlobalKey();
  final _phoneFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _birthYearController = TextEditingController();
    _phoneController = TextEditingController();
    _firstNameFocus = FocusNode();
    _lastNameFocus = FocusNode();
    _genderFocus = FocusNode();
    _birthYearFocus = FocusNode();
    _phoneFocus = FocusNode();
    for (final focus in [
      _firstNameFocus,
      _lastNameFocus,
      _genderFocus,
      _birthYearFocus,
      _phoneFocus,
    ]) {
      focus.addListener(_onRegistrationFocusChanged);
    }
    final user = FirebaseAuth.instance.currentUser;
    final parts = (user?.displayName ?? '').trim().split(RegExp(r'\\s+'));
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      _firstNameController.text = parts.first;
      if (parts.length > 1) _lastNameController.text = parts.skip(1).join(' ');
    }
    if (user?.photoURL != null) _googlePhotoUrl = user!.photoURL;
  }

  String? _googlePhotoUrl;

  void _onRegistrationFocusChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nodes = [
        _firstNameFocus,
        _lastNameFocus,
        _genderFocus,
        _birthYearFocus,
        _phoneFocus,
      ];
      final keys = [
        _firstNameFieldKey,
        _lastNameFieldKey,
        _genderFieldKey,
        _birthYearFieldKey,
        _phoneFieldKey,
      ];
      final index = nodes.indexWhere((node) => node.hasFocus);
      if (index >= 0 && keys[index].currentContext != null) {
        Scrollable.ensureVisible(
          keys[index].currentContext!,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: .12,
        );
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthYearController.dispose();
    _phoneController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _genderFocus.dispose();
    _birthYearFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.isEmpty) return 'Номро ворид кунед';
    if (value.length < 2) return 'Ном бояд на камтар аз 2 ҳарф бошад';
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.isEmpty) return 'Насабро ворид кунед';
    if (value.length < 2) return 'Насаб бояд на камтар аз 2 ҳарф бошад';
    return null;
  }

  String? _validateBirthYear(String? value) {
    if (value == null || value.isEmpty) return 'Соли таваллудро ворид кунед';
    final year = int.tryParse(value);
    if (year == null) return 'Соли таваллуд бояд рақам бошад';
    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear) return 'Соли таваллуд нодуруст аст';
    final age = currentYear - year;
    if (age < 18) return 'Шумо бояд на камтар аз 18 сол дошта бошед';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Рақами телефонро ворид кунед';
    if (value.length < 9) {
      return 'Рақами телефон бояд на камтар аз 9 рақам бошад';
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

  Future<void> _saveUserBasicInfo(String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final birthYear = _birthYearController.text.trim();

    await prefs.setString('app_session_version', _appSessionVersion);
    await prefs.setString('user_name', name);
    await prefs.setString('user_phone', phone);
    await prefs.setString('user_first_name', firstName);
    await prefs.setString('user_last_name', lastName);
    await prefs.setString('user_birth_year', birthYear);
    await prefs.setString('user_gender', _selectedGender!);
  }

  void _handleSubmit() {
    setState(() => _hasSubmitted = true);
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ҷинсро интихоб кунед',
          ),
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _passengerName =
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      });
      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted) {
          setState(() => _isLoading = false);
          await _saveUserBasicInfo(_passengerName!, _phoneController.text);
          final roleName = _passengerName!;
          final rolePhone = _phoneController.text;
          AppRoute.replace<void, void>(
            context,
            role_selection.RoleSelectionScreen(
              passengerName: roleName,
              passengerPhone: rolePhone,
              onContinue: (role) async {
                final prefs = await SharedPreferences.getInstance();
                final fullName = roleName.trim();
                final nameParts = fullName.split(RegExp(r'\s+'));
                final firstName = nameParts.isNotEmpty ? nameParts.first : '';
                final lastName = nameParts.length > 1
                    ? nameParts.sublist(1).join(' ')
                    : '';

                await prefs.setString(
                  'app_session_version',
                  _appSessionVersion,
                );
                await prefs.setString(
                  'user_role',
                  role == role_selection.UserRole.passenger
                      ? 'passenger'
                      : 'driver',
                );
                await prefs.setString('user_name', roleName);
                await prefs.setString('user_phone', rolePhone);
                await prefs.setString('user_first_name', firstName);
                await prefs.setString('user_last_name', lastName);
              },
              destinationBuilder: (role) {
                if (role == role_selection.UserRole.passenger) {
                  return PassengerHomeScreen(
                    key: ValueKey(
                      'passenger-home-$rolePhone-'
                      '${DateTime.now().millisecondsSinceEpoch}',
                    ),
                    passengerName: roleName,
                    passengerPhone: rolePhone,
                  );
                }
                return DriverRegistrationScreen(
                  passengerName: roleName,
                  passengerPhone: rolePhone,
                );
              },
            ),
          );
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            const Positioned.fill(child: _AuthBackdrop()),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = MediaQuery.sizeOf(context).height;
                final scale = min(
                  width / 392,
                  height / 850,
                ).clamp(.8, 1.15).toDouble();
                final inset = width * .063;
                final fieldWidth = width - inset * 2;
                final normalFieldHeight = width * .141;
                final normalGap = width * .039;
                final theme = Theme.of(context).copyWith(
                  popupMenuTheme: const PopupMenuThemeData(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                );
                final firstError = _hasSubmitted
                    ? _validateFirstName(_firstNameController.text)
                    : null;
                final lastError = _hasSubmitted
                    ? _validateLastName(_lastNameController.text)
                    : null;
                final genderError = _hasSubmitted && _selectedGender == null
                    ? 'Ҷинсро интихоб кунед'
                    : null;
                final birthError = _hasSubmitted
                    ? _validateBirthYear(_birthYearController.text)
                    : null;
                final phoneError = _hasSubmitted
                    ? _validatePhone(_phoneController.text)
                    : null;

                Widget input({
                  required String label,
                  required IconData icon,
                  required FocusNode focus,
                  required String? error,
                  required Widget child,
                  Widget? trailing,
                }) => _AuthInput(
                  label: label,
                  icon: icon,
                  height: normalFieldHeight,
                  scale: scale,
                  hasFocus: focus.hasFocus,
                  errorText: error,
                  child: child,
                  trailing: trailing,
                );

                final fields = <Widget>[
                  input(
                    label: 'Ном',
                    icon: Icons.person_outline_rounded,
                    focus: _firstNameFocus,
                    error: firstError,
                    child: TextFormField(
                      controller: _firstNameController,
                      focusNode: _firstNameFocus,
                      validator: _validateFirstName,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      scrollPadding: const EdgeInsets.only(bottom: 120),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[A-Za-zА-Яа-яЁёӣӯқғҳҷІіӢӨөҒғҲҳҶҷ'’ -]"),
                        ),
                      ],
                      style: _registrationValueStyle(scale),
                      decoration: _registrationInputDecoration(scale),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  input(
                    label: 'Насаб',
                    icon: Icons.person_outline_rounded,
                    focus: _lastNameFocus,
                    error: lastError,
                    child: TextFormField(
                      controller: _lastNameController,
                      focusNode: _lastNameFocus,
                      validator: _validateLastName,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      scrollPadding: const EdgeInsets.only(bottom: 120),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[A-Za-zА-Яа-яЁёӣӯқғҳҷІіӢӨөҒғҲҳҶҷ'’ -]"),
                        ),
                      ],
                      style: _registrationValueStyle(scale),
                      decoration: _registrationInputDecoration(scale),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  input(
                    label: 'Ҷинс',
                    icon: Icons.male_rounded,
                    focus: _genderFocus,
                    error: genderError,
                    trailing: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22 * scale,
                      color: const Color(0xFF0B1B3F),
                    ),
                    child: Focus(
                      focusNode: _genderFocus,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        isDense: true,
                        validator: (value) =>
                            value == null ? 'Ҷинсро интихоб кунед' : null,
                        decoration: _registrationInputDecoration(scale),
                        style: _registrationValueStyle(scale),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        icon: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                            value: 'Мард',
                            child: Text(
                              'Мард',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Зан',
                            child: Text(
                              'Зан',
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedGender = value),
                      ),
                    ),
                  ),
                  input(
                    label: 'Соли таваллуд',
                    icon: Icons.calendar_month_outlined,
                    focus: _birthYearFocus,
                    error: birthError,
                    child: TextFormField(
                      controller: _birthYearController,
                      focusNode: _birthYearFocus,
                      validator: _validateBirthYear,
                      keyboardType: TextInputType.number,
                      scrollPadding: const EdgeInsets.only(bottom: 120),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      style: _registrationValueStyle(scale),
                      decoration: _registrationInputDecoration(
                        scale,
                        hintText: '2007',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  input(
                    label: 'Рақами телефон',
                    icon: Icons.phone_outlined,
                    focus: _phoneFocus,
                    error: phoneError,
                    child: TextFormField(
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      validator: _validatePhone,
                      keyboardType: TextInputType.phone,
                      scrollPadding: const EdgeInsets.only(bottom: 120),
                      style: _registrationValueStyle(scale),
                      decoration: _registrationInputDecoration(
                        scale,
                        hintText: '+992 90 123 45 67',
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ];

                Widget avatar(double diameter) => _RegistrationAvatar(
                  diameter: diameter,
                  scale: scale,
                  avatarBytes: _avatarBytes,
                  photoUrl: _googlePhotoUrl,
                  onTap: _pickImage,
                );

                final form = Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: height * .076,
                      left: (width - width * .27) / 2,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: 1,
                        child: avatar(width * .27),
                      ),
                    ),
                    Positioned(
                      top: height * .228 - 12 * scale,
                      left: inset,
                      right: inset,
                      height: 24 * scale,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: 1,
                        child: Text(
                          '\u0410\u043a\u0441\u0438\u0438 \u0445\u0443\u0434\u0440\u043e \u0438\u043b\u043e\u0432\u0430 \u043a\u0443\u043d\u0435\u0434',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14 * scale,
                            color: const Color(0xFF6B7BA0),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: height * .27,
                      left: inset,
                      right: inset,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: 1,
                        child: Text(
                          '\u0425\u0443\u0448 \u043e\u043c\u0430\u0434\u0435\u0434 \u0431\u0430\nInterTaxi',
                          style: TextStyle(
                            fontSize: 30 * scale,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0B1B3F),
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: height * .365,
                      left: inset,
                      right: inset,
                      height: height * .055,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: 1,
                        child: Text(
                          '\u0411\u0430\u0440\u043e\u0438 \u0438\u0441\u0442\u0438\u0444\u043e\u0434\u0430\u0438 \u0445\u0438\u0437\u043c\u0430\u0442\u0440\u0430\u0441\u043e\u043d\u0438\u0445\u043e,\n\u043c\u0430\u044a\u043b\u0443\u043c\u043e\u0442\u0438 \u0445\u0443\u0434\u0440\u043e \u0432\u043e\u0440\u0438\u0434 \u043a\u0443\u043d\u0435\u0434',
                          style: TextStyle(
                            fontSize: 15 * scale,
                            color: const Color(0xFF6B7BA0),
                          ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < fields.length; i++)
                      Positioned(
                        top:
                            height * .446 + i * (normalFieldHeight + normalGap),
                        left: inset,
                        width: fieldWidth,
                        height: normalFieldHeight,
                        child: KeyedSubtree(
                          key: [
                            _firstNameFieldKey,
                            _lastNameFieldKey,
                            _genderFieldKey,
                            _birthYearFieldKey,
                            _phoneFieldKey,
                          ][i],
                          child: fields[i],
                        ),
                      ),
                    Positioned(
                      top: height * .88,
                      left: inset,
                      right: inset,
                      height: width * .124,
                      child: _registrationButton(
                        scale,
                        _isLoading,
                        _handleSubmit,
                      ),
                    ),
                  ],
                );
                return Theme(
                  data: theme,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: SizedBox(
                      height: max(height, constraints.maxHeight),
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => FocusScope.of(context).unfocus(),
                        child: Form(key: _formKey, child: form),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  double _compactFieldHeight(
    double availableHeight,
    double width,
    double scale,
  ) {
    final avatar = min(64 * scale, max(48.0, availableHeight * .17));
    final button = min(48 * scale, max(40.0, availableHeight * .12));
    final gap = min(4 * scale, availableHeight * .012);
    final reserved = avatar + 42 * scale + button + 18 * scale + 4 * gap;
    return ((availableHeight - reserved) / 5)
        .clamp(32.0, width * .141)
        .toDouble();
  }

  Widget _registrationButton(
    double scale,
    bool loading,
    VoidCallback onPressed,
  ) => ElevatedButton(
    onPressed: loading ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0B6BFF),
      foregroundColor: Colors.white,
      elevation: 12,
      shadowColor: const Color(0x550B6BFF),
      shape: const StadiumBorder(),
    ),
    child: loading
        ? const _AnimatedCarLoading()
        : Center(
            child: Text(
              'Идома додан',
              style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
  );
}

TextStyle _registrationValueStyle(double scale) => TextStyle(
  fontSize: 17 * scale,
  fontWeight: FontWeight.w500,
  color: const Color(0xFF0B1B3F),
);

InputDecoration _registrationInputDecoration(
  double scale, {
  String? hintText,
}) => InputDecoration(
  filled: false,
  fillColor: Colors.transparent,
  isDense: true,
  hintText: hintText,
  hintStyle: TextStyle(
    fontSize: 17 * scale,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFA9B8D3),
  ),
  errorStyle: const TextStyle(
    fontSize: 0.01,
    height: 0.01,
    color: Colors.transparent,
  ),
  contentPadding: EdgeInsets.zero,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
);

class _AuthInput extends StatelessWidget {
  const _AuthInput({
    required this.label,
    required this.icon,
    required this.height,
    required this.scale,
    required this.hasFocus,
    required this.errorText,
    required this.child,
    this.trailing,
  });
  final String label;
  final IconData icon;
  final double height;
  final double scale;
  final bool hasFocus;
  final String? errorText;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final color = hasError
        ? const Color(0xFFE5484D)
        : hasFocus
        ? const Color(0xFF0B6BFF)
        : const Color(0xFF8CA0C4);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: height,
      padding: EdgeInsets.only(left: 12 * scale, right: 11 * scale),
      decoration: BoxDecoration(
        color: hasFocus ? Colors.white : const Color(0xFFF4F8FE),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: hasError
              ? const Color(0xFFE5484D)
              : hasFocus
              ? const Color(0xFF0B6BFF)
              : const Color(0xFFDCE8F8),
          width: hasFocus || hasError ? 2 : 1,
        ),
        boxShadow: hasFocus
            ? const [BoxShadow(color: Color(0x260B6BFF), blurRadius: 12)]
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22 * scale),
          SizedBox(width: 18.5 * scale),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 15 * scale,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: errorText == null
                        ? Text(
                            label,
                            style: TextStyle(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w400,
                              color: hasFocus
                                  ? const Color(0xFF0B6BFF)
                                  : const Color(0xFF7C8DB0),
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              errorText!,
                              style: TextStyle(
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFFE5484D),
                              ),
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 1 * scale),
                child,
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: 8 * scale), trailing!],
        ],
      ),
    );
  }
}

class _RegistrationAvatar extends StatelessWidget {
  const _RegistrationAvatar({
    required this.diameter,
    required this.scale,
    required this.avatarBytes,
    required this.photoUrl,
    required this.onTap,
  });

  final double diameter;
  final double scale;
  final Uint8List? avatarBytes;
  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? image = avatarBytes != null
        ? MemoryImage(avatarBytes!)
        : photoUrl != null
        ? NetworkImage(photoUrl!)
        : null;
    final badgeSize = diameter * 0.285;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: diameter + badgeSize * 0.16,
        height: diameter + badgeSize * 0.08,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEAF2FD),
                border: Border.all(
                  color: const Color(0xFF0B6BFF),
                  width: 2 * scale,
                ),
                image: image == null
                    ? null
                    : DecorationImage(image: image, fit: BoxFit.cover),
              ),
              alignment: Alignment.center,
              child: image == null
                  ? CustomPaint(
                      size: Size(diameter * 0.4, diameter * 0.4),
                      painter: const _ProfileSilhouettePainter(),
                    )
                  : null,
            ),
            Positioned(
              right: -badgeSize * 0.02,
              bottom: badgeSize * 0.20,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0B6BFF),
                  border: Border.all(color: Colors.white, width: 3 * scale),
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: badgeSize * 0.53,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSilhouettePainter extends CustomPainter {
  const _ProfileSilhouettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFB4C5E3);
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.25),
      size.width * .19,
      paint,
    );
    final shoulders = Path()
      ..moveTo(size.width * .06, size.height * .92)
      ..cubicTo(
        size.width * .08,
        size.height * .62,
        size.width * .31,
        size.height * .48,
        size.width / 2,
        size.height * .48,
      )
      ..cubicTo(
        size.width * .69,
        size.height * .48,
        size.width * .92,
        size.height * .62,
        size.width * .94,
        size.height * .92,
      )
      ..quadraticBezierTo(
        size.width * .94,
        size.height,
        size.width * .84,
        size.height,
      )
      ..lineTo(size.width * .16, size.height)
      ..quadraticBezierTo(
        size.width * .06,
        size.height,
        size.width * .06,
        size.height * .92,
      )
      ..close();
    canvas.drawPath(shoulders, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _AuthBackdropPainter());
}

class _AuthBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFDCE9FB).withValues(alpha: .56);
    final top = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .43, 0)
      ..cubicTo(
        size.width * .32,
        size.height * .14,
        size.width * .13,
        size.height * .16,
        0,
        size.height * .25,
      )
      ..close();
    canvas.drawPath(top, p);
    final bottom = Path()
      ..moveTo(size.width, size.height * .89)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * .76, size.height)
      ..cubicTo(
        size.width * .85,
        size.height * .96,
        size.width * .91,
        size.height * .92,
        size.width,
        size.height * .89,
      )
      ..close();
    canvas.drawPath(bottom, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PassengerTripScreen extends StatefulWidget {
  final String passengerName;
  final String passengerPhone;

  const PassengerTripScreen({
    super.key,
    required this.passengerName,
    required this.passengerPhone,
  });

  @override
  State<PassengerTripScreen> createState() => _PassengerTripScreenState();
}

class _PassengerTripScreenState extends State<PassengerTripScreen> {
  String? _selectedStartLocation;
  String? _selectedDestination;
  bool _isLoading = false;

  final List<String> _locations = [
    'Душанбе',
    'Кӯлоб',
    'Восеъ',
    'Хуҷанд',
    'Бохтар',
    'Конибодом',
    'Исфара',
    'Файзобод',
    'Турсунзода',
    'Панҷакент',
    'Истаравшан',
    'Ваҳдат',
    'Ҳисор',
    'Хоруғ',
    'Данғара',
    'Ёвон',
    'Рашт',
    'Шаҳритус',
    'Қубодиён',
    'Ҷаббор Расулов',
    'Спитамен',
    'Дарвоз',
  ];

  void _handleSearch() async {
    if (_selectedStartLocation == null || _selectedDestination == null) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _isLoading = false);
      // Navigate to order details with passenger info
      AppRoute.push<void>(
        context,
        OrderDetailsScreen(
          fromLocation: _selectedStartLocation!,
          toLocation: _selectedDestination!,
          price: '150 сомонӣ',
          duration: '2 соат 30 дақиқа',
          seats: 3,
          passengerPhone: widget.passengerPhone,
          passengerName: widget.passengerName,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Мусофир'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Хуш омадед, мусофир!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Биёед саёҳати худро оғоз кунем',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              _buildLocationCard(
                title: 'Аз куҷо меравед?',
                placeholder: 'Ҷойи оғозро интихоб кунед',
                selectedLocation: _selectedStartLocation,
                icon: AppIcons.trip_origin,
                onTap: () async {
                  final selected = await AppRoute.push<String>(
                    context,
                    LocationSelectionScreen(
                      title: 'Аз куҷо меравед?',
                      locations: _locations,
                      selectedLocation: _selectedStartLocation,
                    ),
                  );
                  if (selected != null) {
                    setState(() => _selectedStartLocation = selected);
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildLocationCard(
                title: 'Ба куҷо рафтан мехоҳед?',
                placeholder: 'Макони таъинотро интихоб кунед',
                selectedLocation: _selectedDestination,
                icon: AppIcons.location_on,
                onTap: () async {
                  final selected = await AppRoute.push<String>(
                    context,
                    LocationSelectionScreen(
                      title: 'Ба куҷо рафтан мехоҳед?',
                      locations: _locations,
                      selectedLocation: _selectedDestination,
                    ),
                  );
                  if (selected != null) {
                    setState(() => _selectedDestination = selected);
                  }
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ||
                          _selectedStartLocation == null ||
                          _selectedDestination == null
                      ? null
                      : _handleSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Ҷустуҷӯи мошин'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard({
    required String title,
    required String placeholder,
    required String? selectedLocation,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedLocation != null
                ? const Color(0xFF0066FF)
                : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: selectedLocation != null
                  ? const Color(0xFF0066FF)
                  : Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedLocation ?? placeholder,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selectedLocation != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: selectedLocation != null
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}

class LocationSelectionScreen extends StatefulWidget {
  final String title;
  final List<String> locations;
  final String? selectedLocation;

  const LocationSelectionScreen({
    super.key,
    required this.title,
    required this.locations,
    this.selectedLocation,
  });

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _placeType = 'Ҳама';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = switch (_placeType) {
      'Шаҳр' => tajikCityNames,
      'Ноҳия' => tajikDistrictNames,
      _ => tajikCities,
    };
    final query = _query.trim().toLowerCase();
    final filteredLocations = locations
        .where((location) => location.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFFF8FAFF),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Ҳама', label: Text('Ҳама')),
                ButtonSegment(value: 'Шаҳр', label: Text('Шаҳр')),
                ButtonSegment(value: 'Ноҳия', label: Text('Ноҳия')),
              ],
              selected: {_placeType},
              onSelectionChanged: (selection) =>
                  setState(() => _placeType = selection.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? const Color(0xFF1E56EC)
                      : const Color(0xFFEAF1FF),
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white
                      : const Color(0xFF2452B8),
                ),
                side: WidgetStateProperty.all(
                  const BorderSide(color: Color(0xFFD5E2FF)),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Ҷустуҷӯи шаҳр...',
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
                  borderSide: const BorderSide(color: Color(0xFFE4EAF4)),
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
          ),
          Expanded(
            child: filteredLocations.isEmpty
                ? Center(
                    child: Text(
                      'Шаҳр ёфт нашуд',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: filteredLocations.length,
                    itemBuilder: (context, index) {
                      final location = filteredLocations[index];
                      final isSelected = widget.selectedLocation == location;

                      return _LocationNameEntrance(
                        key: ValueKey('$_placeType-$location'),
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => Navigator.pop(context, location),
                              borderRadius: BorderRadius.circular(16),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFEAF2FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF0066FF)
                                        : const Color(0xFFE2E8F2),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0A173B73),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF0066FF,
                                        ).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        AppIcons.location_on_rounded,
                                        size: 19,
                                        color: Color(0xFF0066FF),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? const Color(0xFF0066FF)
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isSelected
                                          ? AppIcons.check_circle_rounded
                                          : AppIcons.chevron_right_rounded,
                                      color: isSelected
                                          ? const Color(0xFF0066FF)
                                          : Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Staggers location rows upward from the bottom when the driver changes the
/// city/district filter.
class _LocationNameEntrance extends StatefulWidget {
  const _LocationNameEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_LocationNameEntrance> createState() => _LocationNameEntranceState();
}

class _LocationNameEntranceState extends State<_LocationNameEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _entry;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    final reverseStagger = (6 - widget.index).clamp(0, 6);
    final start = (reverseStagger * 45 / 650).toDouble();
    _entry = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _entry,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.45),
        end: Offset.zero,
      ).animate(_entry),
      child: widget.child,
    ),
  );
}

class CarBrandSelectionScreen extends StatefulWidget {
  final List<CarBrand> brands;
  final String? selectedBrand;

  const CarBrandSelectionScreen({
    super.key,
    required this.brands,
    this.selectedBrand,
  });

  @override
  State<CarBrandSelectionScreen> createState() =>
      _CarBrandSelectionScreenState();
}

class _CarBrandSelectionScreenState extends State<CarBrandSelectionScreen> {
  String _query = '';

  List<CarBrand> get _filteredBrands => widget.brands
      .where(
        (brand) =>
            brand.name.toLowerCase().contains(_query.trim().toLowerCase()),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Маркаи мошин'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search car brand',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF4F6F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              itemCount: _filteredBrands.length,
              itemBuilder: (context, index) {
                final brand = _filteredBrands[index];
                final isSelected =
                    widget.selectedBrand != null &&
                    isSameCarBrand(widget.selectedBrand!, brand.name);
                return GestureDetector(
                  onTap: () => Navigator.pop(context, brand.name),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEAF2FF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0066FF)
                            : const Color(0xFFE4E8EF),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _CarBrandLogo(brand: brand),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            brand.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: const Color(0xFF1D2735),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            AppIcons.check_circle,
                            color: Color(0xFF0066FF),
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CarBrandLogo extends StatelessWidget {
  const _CarBrandLogo({required this.brand});

  final CarBrand brand;

  @override
  Widget build(BuildContext context) {
    if (brand.logoAsset.endsWith('.svg')) {
      return SvgPicture.asset(
        brand.logoAsset,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _BrandInitials(name: brand.name),
        errorBuilder: (_, _, _) => _BrandInitials(name: brand.name),
      );
    }
    return Image.asset(
      brand.logoAsset,
      fit: BoxFit.contain,
      cacheWidth: 96,
      cacheHeight: 96,
      errorBuilder: (_, _, _) => _BrandInitials(name: brand.name),
    );
  }
}

class _BrandInitials extends StatelessWidget {
  const _BrandInitials({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      name.characters.first.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF0066FF),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class CarColorSelectionScreen extends StatelessWidget {
  final List<String> colors;
  final String? selectedColor;

  const CarColorSelectionScreen({
    super.key,
    required this.colors,
    this.selectedColor,
  });

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'Сафед':
        return const Color(0xFFF5F5F5);
      case 'Сиёҳ':
        return const Color(0xFF141414);
      case 'Нуқрагӣ':
        return const Color(0xFFC0C4C8);
      case 'Металлик':
        return const Color(0xFF5A5F66);
      case 'Кабуд':
        return const Color(0xFF1E5AC8);
      case 'Зард':
        return const Color(0xFFF5C814);
      case 'Сабз':
        return const Color(0xFF1E9646);
      case 'Сурх':
        return const Color(0xFFC81E1E);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ранги мошин'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = selectedColor == color;
          final colorValue = _getColorFromName(color);

          return GestureDetector(
            onTap: () => Navigator.pop(context, color),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0066FF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0066FF)
                      : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  // Actual color circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorValue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      color,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(AppIcons.check_circle, color: Colors.white, size: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DriverRegistrationScreen extends StatefulWidget {
  final String passengerName;
  final String passengerPhone;

  const DriverRegistrationScreen({
    super.key,
    required this.passengerName,
    required this.passengerPhone,
  });

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class CreateOrderScreen extends StatefulWidget {
  final String driverName;
  final String driverPhone;

  const CreateOrderScreen({
    super.key,
    required this.driverName,
    required this.driverPhone,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  int _seats = 3;
  bool _isLoading = false;
  DateTime? _departureTime;
  String? _selectedFromLocation;
  String? _selectedToLocation;
  late final AnimationController _publishAnimationController;

  String get _driverName => widget.driverName;
  String get _driverPhone => widget.driverPhone;

  final List<String> _allLocations = [
    'Душанбе',
    'Кӯлоб',
    'Восеъ',
    'Хуҷанд',
    'Бохтар',
    'Конибодом',
    'Исфара',
    'Файзобод',
    'Турсунзода',
    'Панҷакент',
    'Истаравшан',
    'Ваҳдат',
    'Ҳисор',
    'Хоруғ',
    'Данғара',
    'Ёвон',
    'Рашт',
    'Шаҳритус',
    'Қубодиён',
    'Ҷаббор Расулов',
    'Спитамен',
    'Дарвоз',
  ];

  @override
  void dispose() {
    _publishAnimationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _publishAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  Future<void> _selectDepartureTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(
        () => _departureTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  Future<int> _calculateDurationMinutes() async {
    final from = locationCoordinatesFor(_selectedFromLocation);
    final to = locationCoordinatesFor(_selectedToLocation);
    if (from == null || to == null) return 0;
    try {
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}',
        {'overview': 'false'},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        final seconds = routes?.isNotEmpty == true
            ? (routes!.first['duration'] as num?)?.toDouble() ?? 0
            : 0;
        if (seconds > 0) return (seconds / 60).round();
      }
    } catch (_) {
      // Fall back to a local estimate when routing is temporarily offline.
    }
    return approximateDrivingDurationMinutes(_selectedFromLocation, _selectedToLocation)?.clamp(1, 24 * 60)?.toInt() ?? 0;
  }

  String _formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '$minutes дақиқа';
    if (minutes == 0) return '$hours соат';
    return '$hours соат $minutes дақиқа';
  }

  Future<void> _handleCreateOrder() async {
    if (_selectedFromLocation == null || _selectedToLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Лутфан макони оғоз ва таъинро интихоб кунед'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _publishAnimationController.repeat();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_route_from', _selectedFromLocation!);
      await prefs.setString('active_route_to', _selectedToLocation!);

      final now = DateTime.now();
      if (_departureTime == null) {
        throw const FormatException('Invalid departure time');
      }
      final durationTotalMinutes = await _calculateDurationMinutes();
      if (durationTotalMinutes <= 0) {
        throw const FormatException('Route duration is unavailable');
      }
      var carInfo = await loadDriverCarInfo();
      if (carInfo.color.trim().isEmpty) {
        final chooseColor = await _promptForMissingCarColor();
        if (chooseColor) carInfo = await loadDriverCarInfo();
      }

      // Publish to the server FIRST and capture the REAL server id (UUID).
      // Storing that id locally is what lets the delete button remove the
      // SAME announcement from the server afterwards (and from passengers).
      final serverResponse = await ApiService.createTrip({
        'driver_id': _driverPhone,
        'driver_name': _driverName,
        'driver_phone': _driverPhone,
        'from_location': _selectedFromLocation!,
        'to_location': _selectedToLocation!,
        'departure_time': _departureTime!.toIso8601String(),
        'duration_minutes': durationTotalMinutes,
        'car_brand': carInfo.brand,
        'car_model': carInfo.model,
        'car_color': carInfo.color,
        'car_plate': carInfo.plate,
        'price':
            int.tryParse(
              _priceController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0,
        'available_seats': _seats,
      }, returnEnvelope: true);
      if (serverResponse == null) {
        throw Exception(
          'Trip was not published. Check the internet connection and make sure you are signed in with Google.',
        );
      }

      final serverTrip = serverResponse['trip'] as Map<String, dynamic>? ?? {};
      final tripId = serverTrip['id']?.toString() ?? '';
      if (tripId.isNotEmpty) {
        unawaited(_uploadCreatedTripPhotos(carInfo.photoPaths, tripId));
      }

      // Save the announcement so it appears on the driver home screen AND in
      // the passenger route search (real data — no mock). Car info comes from
      // the driver registration data stored earlier.
      final order = Order(
        id:
            serverTrip['id']?.toString() ??
            now.millisecondsSinceEpoch.toString(),
        fromLocation: _selectedFromLocation!,
        toLocation: _selectedToLocation!,
        price: _priceController.text.trim(),
        duration: _formatDuration(durationTotalMinutes),
        durationMinutes: durationTotalMinutes,
        seats: _seats,
        notes: '',
        createdAt: now.toIso8601String(),
        departureTime: _departureTime!.toIso8601String(),
        driverName: _driverName,
        driverPhone: _driverPhone,
        carBrand: carInfo.brand,
        carModel: carInfo.model,
        carColor: carInfo.color,
        carPlate: carInfo.plate,
      );

      // Plain async I/O (SharedPreferences) — never blocks the UI thread.
      // Keeps the announcement on THIS device (driver home screen list).
      await saveOrder(order);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Хатогӣ — эълон нигоҳ дошта нашуд'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _publishAnimationController.stop();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadCreatedTripPhotos(
    List<String> paths,
    String tripId,
  ) async {
    if (paths.any((path) => path.isEmpty)) {
      if (kDebugMode) debugPrint('[DriverHome] photo upload skipped: no photo paths');
      return;
    }
    final files = paths.map(File.new).toList();
    final exists = await Future.wait(files.map((file) => file.exists()));
    if (!exists.every((value) => value)) {
      if (kDebugMode) debugPrint('[DriverHome] photo upload skipped: files missing');
      return;
    }
    if (kDebugMode) debugPrint('[DriverHome] photo upload started: ${files.length} files');
    final result = await ApiService.uploadTripPhotos(
      tripId,
      files[0],
      files[1],
      files[2],
    );
    if (result == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('\u0411\u043e\u0440\u043a\u0443\u043d\u0438\u0438 \u0430\u043a\u0441\u04b3\u043e \u043c\u0443\u0432\u0430\u0444\u0444\u0430\u049b \u043d\u0430\u0448\u0443\u0434')),
      );
    }
  }

  Future<bool> _promptForMissingCarColor() async {
    const colors = [
      '\u0421\u0430\u0444\u0435\u0434', '\u0421\u0438\u0451\u04b3', '\u041d\u0443\u049b\u0440\u0430\u0433\u04e3', '\u041c\u0435\u0442\u0430\u043b\u043b\u0438\u043a',
      '\u041a\u0430\u0431\u0443\u0434', '\u0417\u0430\u0440\u0434', '\u0421\u0430\u0431\u0437', '\u0421\u0443\u0440\u0445',
    ];
    final chooseColor = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('\u0420\u0430\u043d\u0433\u0438 \u043c\u043e\u0448\u0438\u043d \u04b3\u0430\u043d\u04ef\u0437 \u0438\u043d\u0442\u0438\u0445\u043e\u0431 \u043d\u0430\u0448\u0443\u0434\u0430\u0430\u0441\u0442'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('\u0418\u043d\u0442\u0438\u0445\u043e\u0431 \u043a\u0430\u0440\u0434\u0430\u043d'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('\u0411\u0435 \u0440\u0430\u043d\u0433 \u0438\u0434\u043e\u043c\u0430 \u0434\u043e\u0434\u0430\u043d'),
          ),
        ],
      ),
    );
    if (chooseColor != true || !mounted) return false;
    final color = await AppRoute.push<String>(
      context,
      CarColorSelectionScreen(colors: colors),
    );
    if (color == null) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_car_color', color);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Эълон кардан'),
        backgroundColor: const Color(0xFFF8FAFF),
        foregroundColor: Colors.black87,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // From Location Selection
              GestureDetector(
                onTap: () async {
                  final selected = await AppRoute.push<String>(
                    context,
                    LocationSelectionScreen(
                      title: 'Аз куҷо меравед?',
                      locations: _allLocations,
                      selectedLocation: _selectedFromLocation,
                    ),
                  );
                  if (selected != null) {
                    setState(() => _selectedFromLocation = selected);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE0E7F1)),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A173B73),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(AppIcons.trip_origin, size: 24, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedFromLocation ?? 'Аз куҷо меравед?',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedFromLocation != null
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      Icon(
                        AppIcons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // To Location Selection
              GestureDetector(
                onTap: () async {
                  final selected = await AppRoute.push<String>(
                    context,
                    LocationSelectionScreen(
                      title: 'Ба куҷо рафтан мехоҳед?',
                      locations: _allLocations,
                      selectedLocation: _selectedToLocation,
                    ),
                  );
                  if (selected != null) {
                    setState(() => _selectedToLocation = selected);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE0E7F1)),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A173B73),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(AppIcons.location_on, size: 24, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedToLocation ?? 'Ба куҷо рафтан мехоҳед?',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedToLocation != null
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      Icon(
                        AppIcons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Price input
              TextFormField(
                controller: _priceController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Нархро ворид кунед';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Нарх (сомонӣ)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    borderSide: BorderSide(color: Color(0xFFE0E7F1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    borderSide: BorderSide(color: Color(0xFFE0E7F1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    borderSide: BorderSide(
                      color: Color(0xFF0066FF),
                      width: 1.5,
                    ),
                  ),
                  hintText: 'Масалан: 150',
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _selectDepartureTime,
                icon: const Icon(AppIcons.event_rounded),
                label: Text(
                  _departureTime == null
                      ? 'Рӯз ва вақти рафтанро интихоб кунед'
                      : '${_departureTime!.hour.toString().padLeft(2, '0')}:${_departureTime!.minute.toString().padLeft(2, '0')} '
                            '${_departureTime!.day.toString().padLeft(2, '0')}.${_departureTime!.month.toString().padLeft(2, '0')}.${_departureTime!.year}',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF31548C),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF31548C)),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Seats selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ҷойҳои холӣ: $_seats',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSeatButton(
                        icon: AppIcons.remove_rounded,
                        onTap: _seats > 1
                            ? () => setState(() => _seats--)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // Seats display
                      Container(
                        width: 80,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0066FF), Color(0xFF3385FF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x330066FF),
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Text(
                              '$_seats',
                              key: ValueKey(_seats),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildSeatButton(
                        icon: AppIcons.add_rounded,
                        onTap: _seats < 8
                            ? () => setState(() => _seats++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Create order button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreateOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1769E0),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF9CC2FF),
                    elevation: 8,
                    shadowColor: const Color(0x660066FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _publishAnimationController,
                        builder: (context, child) => Transform.rotate(
                          angle: _isLoading
                              ? _publishAnimationController.value * 6.28318
                              : 0,
                          child: child,
                        ),
                        child: const Icon(AppIcons.directions_car_rounded),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Эълон кардан',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeatButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: const Color(0x22173B73),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            icon,
            color: onTap == null ? Colors.grey[300] : const Color(0xFF0066FF),
          ),
        ),
      ),
    );
  }
}

class OrderDetailsScreen extends StatelessWidget {
  final String fromLocation;
  final String toLocation;
  final String price;
  final String duration;
  final int seats;
  final String passengerPhone;
  final String passengerName;

  const OrderDetailsScreen({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    required this.price,
    required this.duration,
    required this.seats,
    required this.passengerPhone,
    this.passengerName = 'Мусофир',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Тафсилоти заказ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map placeholder
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.map_rounded, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Харита',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Route information
            Row(
              children: [
                // From location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Аз',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fromLocation,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  AppIcons.arrow_forward_rounded,
                  size: 24,
                  color: Colors.grey[400],
                ),
                // To location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Ба',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        toLocation,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Divider
            Divider(color: Colors.grey[300], height: 1),
            const SizedBox(height: 24),
            // Price
            _buildInfoRow(
              icon: AppIcons.attach_money_rounded,
              label: 'Нарх',
              value: price,
              iconColor: Colors.green,
            ),
            const SizedBox(height: 16),
            // Duration
            _buildInfoRow(
              icon: AppIcons.access_time_rounded,
              label: 'Вақт',
              value: duration,
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 16),
            // Seats
            _buildInfoRow(
              icon: AppIcons.airline_seat_recline_normal_rounded,
              label: 'Ҷойҳои холӣ',
              value: '$seats ҷой',
              iconColor: Colors.orange,
            ),
            const SizedBox(height: 24),
            // Divider
            Divider(color: Colors.grey[300], height: 1),
            const SizedBox(height: 24),
            // Passenger info
            Text(
              'Маълумоти мусофир',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        AppIcons.person_rounded,
                        size: 24,
                        color: const Color(0xFF0066FF),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ном:',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Text(
                      passengerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        AppIcons.phone_rounded,
                        size: 24,
                        color: const Color(0xFF0066FF),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Телефон:',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Text(
                      passengerPhone,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Accept button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Заказ қабул шуд!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Navigate back to driver home after delay
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (context.mounted) {
                      AppRoute.replaceAll<void>(
                        context,
                        const DriverHomeScreen(
                          driverName: 'Ронанда',
                          driverPhone: '',
                        ),
                      );
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Заказро қабул кардан',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Order model — represents a driver's ride announcement (эълон)
class Order {
  final String id;
  final String fromLocation;
  final String toLocation;
  final String price;
  final String duration;
  final int durationMinutes;
  final int seats;
  final String notes;
  final String createdAt;
  final String departureTime;
  final String driverName;
  final String driverPhone;
  final String carBrand;
  final String carModel;
  final String carColor;
  final String carPlate;

  Order({
    required this.id,
    required this.fromLocation,
    required this.toLocation,
    required this.price,
    required this.duration,
    this.durationMinutes = 0,
    required this.seats,
    required this.notes,
    required this.createdAt,
    this.departureTime = '',
    this.driverName = '',
    this.driverPhone = '',
    this.carBrand = '',
    this.carModel = '',
    this.carColor = '',
    this.carPlate = '',
  });

  Order copyWith({int? seats}) => Order(
    id: id,
    fromLocation: fromLocation,
    toLocation: toLocation,
    price: price,
    duration: duration,
    durationMinutes: durationMinutes,
    seats: seats ?? this.seats,
    notes: notes,
    createdAt: createdAt,
    departureTime: departureTime,
    driverName: driverName,
    driverPhone: driverPhone,
    carBrand: carBrand,
    carModel: carModel,
    carColor: carColor,
    carPlate: carPlate,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromLocation': fromLocation,
    'toLocation': toLocation,
    'price': price,
    'duration': duration,
    'durationMinutes': durationMinutes,
    'seats': seats,
    'notes': notes,
    'createdAt': createdAt,
    'departureTime': departureTime,
    'driverName': driverName,
    'driverPhone': driverPhone,
    'carBrand': carBrand,
    'carModel': carModel,
    'carColor': carColor,
    'carPlate': carPlate,
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String? ?? '',
    fromLocation: json['fromLocation'] as String? ?? '',
    toLocation: json['toLocation'] as String? ?? '',
    price: json['price'] as String? ?? '',
    duration: json['duration'] as String? ?? '',
    durationMinutes: json['durationMinutes'] as int? ?? 0,
    seats: json['seats'] as int? ?? 0,
    notes: json['notes'] as String? ?? '',
    createdAt: json['createdAt'] as String? ?? '',
    departureTime: json['departureTime'] as String? ?? '',
    driverName: json['driverName'] as String? ?? '',
    driverPhone: json['driverPhone'] as String? ?? '',
    carBrand: json['carBrand'] as String? ?? '',
    carModel: json['carModel'] as String? ?? '',
    carColor: json['carColor'] as String? ?? '',
    carPlate: json['carPlate'] as String? ?? '',
  );
}

/// Persists an order to SharedPreferences so it survives app restarts / refresh
Future<void> saveOrder(Order order) async {
  final prefs = await SharedPreferences.getInstance();
  final orders = await loadOrders();
  orders.add(order);
  await prefs.setString(
    'saved_orders',
    jsonEncode(orders.map((o) => o.toJson()).toList()),
  );
}

Future<void> updateOrderSeats(String orderId, int seats) async {
  final prefs = await SharedPreferences.getInstance();
  final orders = await loadOrders();
  final index = orders.indexWhere((order) => order.id == orderId);
  if (index < 0) return;
  orders[index] = orders[index].copyWith(seats: seats);
  await prefs.setString(
    'saved_orders',
    jsonEncode(orders.map((order) => order.toJson()).toList()),
  );
}

/// Loads all saved orders from SharedPreferences
Future<List<Order>> loadOrders() async {
  final prefs = await SharedPreferences.getInstance();
  final ordersJson = prefs.getString('saved_orders');
  if (ordersJson == null || ordersJson.isEmpty) return [];
  final List<dynamic> decoded = jsonDecode(ordersJson);
  return decoded
      .map((item) => Order.fromJson(item as Map<String, dynamic>))
      .toList();
}

/// Deletes a single order by id — from the SERVER (which also broadcasts
/// `trip_deleted` to every passenger device, so the announcement disappears
/// from the мусофир app too) AND from local storage.
Future<void> deleteOrder(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final orders = await loadOrders();
  Order? order;
  for (final candidate in orders) {
    if (candidate.id == id) {
      order = candidate;
      break;
    }
  }

  // Update local persistence first so the announcement cannot reappear if the
  // backend is slow or offline.
  if (prefs.getString('active_trip_id') == id) {
    await _clearPersistedActiveRoute(prefs);
  }
  orders.removeWhere((candidate) => candidate.id == id);
  await prefs.setString(
    'saved_orders',
    jsonEncode(orders.map((candidate) => candidate.toJson()).toList()),
  );

  // New announcements use the server UUID. Older local records are resolved
  // against the server list by route, driver, and price.
  final serverId = _looksLikeUuid(id) ? id : await _resolveServerTripId(order);
  if (serverId != null && serverId.isNotEmpty) {
    await ApiService.deleteTrip(serverId);
  }
}

Future<void> _clearPersistedActiveRoute(SharedPreferences prefs) async {
  for (final key in const [
    'active_trip_id',
    'trip_started',
    'active_route_from',
    'active_route_to',
    'active_route_duration_minutes',
    'active_route_distance_km',
    'route_osrm_duration_seconds',
    'route_osrm_distance_km',
    'route_fit_pending',
  ]) {
    await prefs.remove(key);
  }
}

bool _looksLikeUuid(String id) => RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
).hasMatch(id);

/// Finds the server trip matching the given local order by its content
/// (route + driver + price) so old announcements that only carry a local
/// timestamp id can still be removed from the server.
Future<String?> _resolveServerTripId(Order? order) async {
  if (order == null) return null;
  final trips = await ApiService.fetchTrips();
  final norm = (String? s) => (s ?? '').trim().toLowerCase();
  final priceNum = int.tryParse(order.price.replaceAll(RegExp(r'[^0-9]'), ''));
  final candidates = <Map<String, dynamic>>[];
  for (final t in trips) {
    if (norm(t['from_location']) != norm(order.fromLocation)) continue;
    if (norm(t['to_location']) != norm(order.toLocation)) continue;
    if (order.driverPhone.isNotEmpty &&
        norm(t['driver_phone']) != norm(order.driverPhone) &&
        norm(t['driver_id']) != norm(order.driverPhone)) {
      continue;
    }
    if (priceNum != null &&
        t['price'] is num &&
        (t['price'] as num) != priceNum) {
      continue;
    }
    candidates.add(t);
  }
  if (candidates.isEmpty) return null;
  if (candidates.length == 1) return candidates.first['id']?.toString();
  final depart = order.departureTime.trim();
  if (depart.isNotEmpty) {
    for (final t in candidates) {
      if (norm(t['departure_time']) == norm(depart)) {
        return t['id']?.toString();
      }
    }
  }
  return candidates.first['id']?.toString();
}

class DriverHomeScreen extends StatefulWidget {
  final String driverName;
  final String driverPhone;

  const DriverHomeScreen({
    super.key,
    required this.driverName,
    required this.driverPhone,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with WidgetsBindingObserver {
  static const _tripEndCountdownDuration = 5;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _profileImage;
  int _currentIndex = 0;
  bool _isOnline = true;
  List<Order> _orders = [];
  String? _activeTripId;
  final Set<String> _dismissingTripIds = <String>{};
  final Map<String, GlobalKey> _orderCardKeys = <String, GlobalKey>{};
  final List<Map<String, dynamic>> _passengerMessages = [];
  StreamSubscription<Map<String, dynamic>>? _passengerBookedSubscription;
  StreamSubscription<Map<String, dynamic>>? _tripUpdatedSubscription;
  StreamSubscription<Map<String, dynamic>>? _reviewCreatedSubscription;
  double _driverRating = 0;
  Timer? _bookingRefreshTimer;
  Timer? _tripEndCountdownTimer;
  int? _tripEndCountdown;
  bool _isEndingTripFromHome = false;
  late Future<List<String?>> _carPhotoPathsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadOrders();
    _loadActiveTripId();
    _connectDriverMessages();
    _carPhotoPathsFuture = _loadCarPhotoPaths();
  }

  Future<List<String?>> _loadCarPhotoPaths() async {
    final carInfo = await loadDriverCarInfo();
    if (kDebugMode) {
      // TEMP DEBUG
      debugPrint('[DriverProfile] photo keys=driver_car_photo_1, '
          'driver_car_photo_2, driver_car_photo_3; paths=${carInfo.photoPaths}');
    }
    return carInfo.photoPaths;
  }

  Color _profileCarColor(String name) {
    switch (name) {
      case 'Сафед': return const Color(0xFFF5F5F5);
      case 'Сиёҳ': return const Color(0xFF141414);
      case 'Нуқрагӣ': return const Color(0xFFC0C4C8);
      case 'Металлик': return const Color(0xFF5A5F66);
      case 'Кабуд': return const Color(0xFF1E5AC8);
      case 'Зард': return const Color(0xFFF5C814);
      case 'Сабз': return const Color(0xFF1E9646);
      case 'Сурх': return const Color(0xFFC81E1E);
      default: return Colors.grey;
    }
  }

  Widget _buildCarPhotosCard(String colorName) => FutureBuilder<List<String?>>(
    future: _carPhotoPathsFuture,
    builder: (context, snapshot) {
      final paths = snapshot.data ?? List<String?>.filled(3, null);
      const labels = ['Пеш', 'Қафо', 'Паҳлу'];
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Мошини ман', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1D2735))),
          const SizedBox(height: 12),
          const Text('Аксҳои мошин', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(children: List<Widget>.generate(3, (index) {
            final path = paths[index];
            final exists = path != null && File(path).existsSync();
            return Expanded(child: Padding(padding: EdgeInsets.only(right: index < 2 ? 8 : 0), child: Column(children: [
              GestureDetector(onTap: exists ? () => showDialog<void>(context: context, builder: (dialogContext) => Dialog(backgroundColor: Colors.black, insetPadding: EdgeInsets.zero, child: Stack(children: [Positioned.fill(child: InteractiveViewer(child: Image.file(File(path!), fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white)))), Positioned(top: 24, right: 12, child: IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close, color: Colors.white, size: 30)))]))) : null,
                child: ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(height: 76, width: double.infinity, child: exists ? Image.file(File(path!), fit: BoxFit.cover, errorBuilder: (_, _, _) => _carPhotoPlaceholder()) : _carPhotoPlaceholder())),
              ),
              const SizedBox(height: 5), Text(labels[index], style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ])));
          })),
          const SizedBox(height: 16),
          const Text('Ранги мошин', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [if (colorName.isEmpty || colorName == '') const Icon(Icons.image_not_supported_outlined, size: 22, color: Color(0xFF91A4C3)) else Container(width: 22, height: 22, decoration: BoxDecoration(color: _profileCarColor(colorName), shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300))), const SizedBox(width: 8), Text(colorName.isEmpty || colorName == '' ? 'Ҳанӯз илова нашудааст' : colorName, style: const TextStyle(fontSize: 14))]),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () async {
            await AppRoute.push<void>(context, DriverPhotoCollectionScreen(driverName: widget.driverName, driverPhone: widget.driverPhone, returnAfterSave: true));
            if (!mounted) return;
            setState(() => _carPhotoPathsFuture = _loadCarPhotoPaths());
          }, icon: const Icon(Icons.photo_camera_outlined), label: const Text('Аксҳоро иваз кардан')),
        ]),
      );
    },
  );

  Widget _carPhotoPlaceholder() => Container(color: const Color(0xFFF0F4F8), alignment: Alignment.center, child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image_outlined, color: Color(0xFF91A4C3)), Text('Ҳанӯз илова нашудааст', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Colors.black54))]));

  Future<void> _loadActiveTripId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _activeTripId = prefs.getString('active_trip_id'));
  }

  void _startEndTripCountdown() {
    if (_tripEndCountdown != null ||
        _isEndingTripFromHome ||
        _activeTripId == null) {
      return;
    }
    final tripId = _activeTripId!;
    setState(() {
      _currentIndex = 0;
      _tripEndCountdown = _tripEndCountdownDuration;
      final activeOrder = _orders.where((order) => order.id == tripId);
      if (activeOrder.isNotEmpty) {
        final order = activeOrder.first;
        _orders = [order, ..._orders.where((item) => item.id != tripId)];
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cardContext = _orderCardKeys[tripId]?.currentContext;
      if (cardContext != null) {
        Scrollable.ensureVisible(
          cardContext,
          duration: const Duration(milliseconds: 300),
          alignment: 0.2,
        );
      }
    });
    _tripEndCountdownTimer?.cancel();
    _tripEndCountdownTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      if (!mounted || _activeTripId != tripId) {
        timer.cancel();
        _tripEndCountdownTimer = null;
        if (mounted && _tripEndCountdown != null) {
          setState(() => _tripEndCountdown = null);
        }
        return;
      }
      final secondsLeft = _tripEndCountdown;
      if (secondsLeft == null) {
        timer.cancel();
        return;
      }
      if (secondsLeft > 1) {
        setState(() => _tripEndCountdown = secondsLeft - 1);
        return;
      }
      timer.cancel();
      _tripEndCountdownTimer = null;
      setState(() {
        _tripEndCountdown = null;
        _isEndingTripFromHome = true;
        _activeTripId = null;
        _dismissingTripIds.add(tripId);
      });
      TripVoiceAssistant.instance.stop();
      unawaited(_clearRouteAfterTripEnds(tripId));
      Timer(const Duration(milliseconds: 420), () {
        if (!mounted) return;
        setState(() {
          _orders.removeWhere((order) => order.id == tripId);
          _dismissingTripIds.remove(tripId);
        });
      });
      unawaited(_finishTripOnBackend(tripId));
    });
  }

  void _cancelEndTripCountdown() {
    if (_tripEndCountdown == null || _isEndingTripFromHome) return;
    _tripEndCountdownTimer?.cancel();
    _tripEndCountdownTimer = null;
    if (mounted) setState(() => _tripEndCountdown = null);
  }

  Future<void> _clearRouteAfterTripEnds(String tripId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _clearPersistedActiveRoute(prefs);
      final orders = await loadOrders();
      orders.removeWhere((order) => order.id == tripId);
      await prefs.setString(
        'saved_orders',
        jsonEncode(orders.map((order) => order.toJson()).toList()),
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[DriverHome] Could not clear local trip state: $error\n$stackTrace',
      );
    }
  }

  Future<void> _finishTripOnBackend(String tripId) async {
    String? requestError;
    try {
      // The deployed backend completes this flow by deleting the announcement.
      // It has no POST /api/trips/{id}/complete route.
      final deletion = await ApiService.deleteTripWithResult(tripId);
      if (deletion['ok'] != true) {
        requestError =
            deletion['error']?.toString() ??
            'Announcement deletion request failed';
      }
    } catch (error, stackTrace) {
      requestError = error.toString();
      debugPrint(
        '[DriverHome] End trip backend exception: $error\n$stackTrace',
      );
    } finally {
      _tripEndCountdownTimer?.cancel();
      _tripEndCountdownTimer = null;
      if (mounted) {
        setState(() {
          _tripEndCountdown = null;
          _isEndingTripFromHome = false;
        });
      }
    }

    if (requestError != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(requestError)));
    }
  }

  Future<void> _connectDriverMessages() async {
    _passengerBookedSubscription = SocketService.instance.onPassengerBooked
        .listen((message) {
          if (!_sameDriver(message['driver_id'])) return;
          if (!mounted) return;
          _mergeDriverBookings([message]);
        });
    _tripUpdatedSubscription = SocketService.instance.onTripUpdated.listen(
      (trip) => _applyUpdatedTripSeats(trip),
    );
    _reviewCreatedSubscription = SocketService.instance.onReviewCreated.listen((
      review,
    ) {
      if (!_sameDriver(review['driver_id']) || !mounted) return;
      final rating = double.tryParse(review['rating']?.toString() ?? '');
      if (rating != null) setState(() => _driverRating = rating);
    });
    await _refreshDriverBookings();
    await SocketService.instance.connect(
      userId: widget.driverPhone,
      role: 'driver',
    );
    await _refreshDriverBookings();
    _bookingRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshDriverBookings();
    });
  }

  bool _sameDriver(Object? value) {
    String digits(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');
    final received = digits(value?.toString() ?? '');
    final current = digits(widget.driverPhone);
    return received.isNotEmpty && current.isNotEmpty && received == current;
  }

  Future<void> _refreshDriverBookings() async {
    final bookings = await ApiService.fetchDriverBookings(widget.driverPhone);
    _mergeDriverBookings(bookings);
  }

  void _mergeDriverBookings(List<Map<String, dynamic>> bookings) {
    if (!mounted || bookings.isEmpty) return;
    setState(() {
      for (final message in bookings.reversed) {
        final messageId = message['id']?.toString();
        if (messageId == null ||
            !_passengerMessages.any(
              (existing) => existing['id']?.toString() == messageId,
            )) {
          _passengerMessages.add(message);
        }
      }
    });
  }

  Future<void> _applyUpdatedTripSeats(Map<String, dynamic> trip) async {
    final tripId = trip['id']?.toString();
    final seats = int.tryParse(trip['available_seats']?.toString() ?? '');
    if (tripId == null || seats == null) return;
    await updateOrderSeats(tripId, seats);
    if (!mounted) return;
    setState(() {
      final index = _orders.indexWhere((order) => order.id == tripId);
      if (index >= 0) _orders[index] = _orders[index].copyWith(seats: seats);
    });
  }

  Future<void> _loadOrders() async {
    final orders = await loadOrders();
    if (!mounted) return;
    setState(() => _orders = orders.reversed.toList());
  }

  void _deleteOrderImmediately(String orderId) {
    if (_activeTripId == orderId && _tripEndCountdown != null) {
      _cancelEndTripCountdown();
    }
    if (_activeTripId == orderId) {
      TripVoiceAssistant.instance.stop();
    }
    setState(() {
      _orders.removeWhere((order) => order.id == orderId);
      _dismissingTripIds.remove(orderId);
      if (_activeTripId == orderId) {
        _activeTripId = null;
        _currentIndex = 0;
      }
    });
    unawaited(deleteOrder(orderId));
  }

  @override
  void dispose() {
    TripVoiceAssistant.instance.stop();
    WidgetsBinding.instance.removeObserver(this);
    _passengerBookedSubscription?.cancel();
    _tripUpdatedSubscription?.cancel();
    _reviewCreatedSubscription?.cancel();
    _bookingRefreshTimer?.cancel();
    _tripEndCountdownTimer?.cancel();
    SocketService.instance.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isOnline = state == AppLifecycleState.resumed;
    if (mounted && _isOnline != isOnline) {
      setState(() => _isOnline = isOnline);
    }
    if (state == AppLifecycleState.resumed) {
      _refreshDriverBookings();
    }
  }

  Future<void> _pickProfileImage() async {
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
          _profileImage = bytes;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _resetProfileAndRestart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    AppRoute.replaceAll<void>(context, const RegistrationScreen());
  }

  void _openSettingsScreen() {
    AppRoute.pushModal<void>(context, const SettingsScreen());
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'DriverHomeScreen build: tab=$_currentIndex, '
      'animationsDisabled=${MediaQuery.of(context).disableAnimations}',
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('assets/background.png', fit: BoxFit.cover),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: AnimatedTabBody(
                    index: _currentIndex,
                    duration: const Duration(milliseconds: 200),
                    children: [
                      _buildHomeTab(),
                      _buildRouteTab(),
                      _buildMessagesTab(),
                      _buildProfileTab(),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Салом, Ронанда!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Барои кор омодаед?',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _openSettingsScreen,
                tooltip: 'Танзимот',
                icon: Icon(
                  AppIcons.settings_rounded,
                  size: 28,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // "Закази нав" button — compact card
          GestureDetector(
            onTap: () async {
              final wasCreated = await AppRoute.pushModal<bool>(
                context,
                CreateOrderScreen(
                  driverName: widget.driverName,
                  driverPhone: widget.driverPhone,
                ),
              );
              if (wasCreated == true && mounted) {
                _loadOrders();
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0066FF), Color(0xFF3399FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      AppIcons.directions_car_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Эълон кардан',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Барои эълон кардан зер кунед',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    AppIcons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section title: Эълонҳо
          Row(
            children: [
              const Icon(
                AppIcons.campaign_rounded,
                size: 20,
                color: Color(0xFF0066FF),
              ),
              const SizedBox(width: 8),
              Text(
                'Эълонҳои ман',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (_orders.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_orders.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Orders list
          Expanded(
            child: _orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AppIcons.inbox_rounded,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ҳанӯз эълон вуҷуд надорад',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Аввалин эълони худро созед',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(_orders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final isDismissing = _dismissingTripIds.contains(order.id);
    final isEndTripPending =
        _activeTripId == order.id && _tripEndCountdown != null;
    final isCardInteractionDisabled = isDismissing || isEndTripPending;
    return AnimatedSize(
      key: _orderCardKeys.putIfAbsent(order.id, () => GlobalKey()),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        opacity: isDismissing
            ? 0
            : isEndTripPending
            ? 0.45
            : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route row: from → to
              Row(
                children: [
                  // Route icons
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(width: 2, height: 28, color: Colors.grey[300]),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Locations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.fromLocation,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          order.toLocation,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Price badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          AppIcons.attach_money_rounded,
                          size: 18,
                          color: Color(0xFF0066FF),
                        ),
                        Text(
                          '${order.price} сом',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Bottom info row
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildOrderInfoChip(
                          icon: AppIcons.access_time_rounded,
                          label: order.duration.isNotEmpty
                              ? '${order.duration} дақ'
                              : '—',
                          color: Colors.blue,
                        ),
                        _buildOrderInfoChip(
                          icon: AppIcons.airline_seat_recline_normal_rounded,
                          label: '${order.seats} ҷой',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  GestureDetector(
                    onTap: isCardInteractionDisabled
                        ? null
                        : () => _deleteOrderImmediately(order.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        AppIcons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: isDismissing
                      ? const SizedBox.shrink(key: ValueKey('dismissing'))
                      : isEndTripPending
                      ? _buildOrderEndCountdown(_tripEndCountdown!)
                      : SizedBox(
                          key: ValueKey('trip-action-${order.id}'),
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_activeTripId == order.id) {
                                _startEndTripCountdown();
                              } else {
                                _startTrip(order);
                              }
                            },
                            icon: Icon(
                              _activeTripId == order.id
                                  ? AppIcons.stop_circle_outlined
                                  : AppIcons.play_arrow_rounded,
                              size: 20,
                            ),
                            label: Text(
                              _activeTripId == order.id
                                  ? 'End trip'
                                  : 'Start trip',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0066FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderEndCountdown(int secondsLeft) {
    return Align(
      key: const ValueKey('end-trip-cancel'),
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _cancelEndTripCountdown,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF1456B8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text('Бекор кардан ($secondsLeft)'),
      ),
    );
  }

  Future<void> _startTrip(Order order) async {
    final fromCity = order.fromLocation;
    final toCity = order.toLocation;
    final startResult = await ApiService.startTrip(tripId: order.id);
    if (!mounted) return;
    if (startResult['ok'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            startResult['error']?.toString() ?? 'Сафарро оғоз карда нашуд',
          ),
        ),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    // Clear estimates from the previous trip before this route is fetched.
    await prefs.remove('route_osrm_duration_seconds');
    await prefs.remove('route_osrm_distance_km');
    final distanceKm = _estimateDistanceKm(fromCity, toCity);
    final durationMinutes = order.durationMinutes > 0
        ? order.durationMinutes
        : (distanceKm > 0 ? (distanceKm / 50 * 60).round() : 0);
    await prefs.setString('active_route_from', order.fromLocation);
    await prefs.setString('active_route_to', order.toLocation);
    await prefs.setString('active_trip_id', order.id);
    await prefs.setString('user_phone', widget.driverPhone);
    await prefs.setBool('trip_started', true);
    await prefs.setInt('active_route_duration_minutes', durationMinutes);
    await prefs.setDouble('active_route_distance_km', distanceKm);
    // Start the camera introduction from the newly selected trip.
    await prefs.setBool('route_fit_pending', true);
    unawaited(
      TripVoiceAssistant.instance.playTripStart(
        destination: order.toLocation,
        durationMinutes: durationMinutes,
      ),
    );
    if (!mounted) return;
    setState(() {
      _activeTripId = order.id;
      _currentIndex = 1;
    });
  }

  /// Estimates the straight-line distance (km) between two known cities.
  double _estimateDistanceKm(String fromCity, String toCity) {
    final from = locationCoordinatesFor(fromCity);
    final to = locationCoordinatesFor(toCity);
    if (from == null || to == null) return 0;
    return approximateDrivingDistanceKm(fromCity, toCity) ?? 0;
  }

  Widget _buildOrderInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteTab() {
    return _RouteMapTab(onEndTripRequested: _startEndTripCountdown);
  }

  Widget _buildMessagesTab() {
    if (_passengerMessages.isNotEmpty) {
      return Column(
        children: [
          _buildMessageHeader(title: 'Паёмҳо', onClear: _clearDriverMessages),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: _passengerMessages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final message = _passengerMessages[index];
                final name = message['passenger_name']?.toString().trim();
                final passengerName = name == null || name.isEmpty
                    ? 'Мусофир'
                    : name;
                final requestedSeats =
                    int.tryParse(
                      message['requested_seats']?.toString() ?? '',
                    ) ??
                    1;
                final status = message['status']?.toString() ?? 'pending';
                final statusColor = status == 'approved'
                    ? const Color(0xFF159957)
                    : status == 'rejected'
                    ? const Color(0xFFD64545)
                    : const Color(0xFF1769E0);
                final statusText = status == 'approved'
                    ? 'Иҷозат дода шуд'
                    : status == 'rejected'
                    ? 'Рад карда шуд'
                    : 'Интизорӣ';
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final updated = await AppRoute.push<Map<String, dynamic>>(
                      context,
                      BookingDecisionScreen(
                        booking: message,
                        driverId: widget.driverPhone,
                      ),
                    );
                    if (!mounted || updated == null) return;
                    setState(() {
                      final messageId = updated['id']?.toString();
                      final messageIndex = _passengerMessages.indexWhere(
                        (item) => item['id']?.toString() == messageId,
                      );
                      if (messageIndex >= 0)
                        _passengerMessages[messageIndex] = updated;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.1),
                          child: Icon(
                            AppIcons.person_rounded,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$passengerName ҷойи сафарро брон кард',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$requestedSeats ҷой мехоҳад',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          AppIcons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.message_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Паёмҳо',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageHeader({
    required String title,
    required VoidCallback onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClear,
            tooltip: 'Ҳамаашро тоза кардан',
            icon: const Icon(
              AppIcons.delete_sweep_rounded,
              color: Color(0xFFD64545),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearDriverMessages() async {
    final deleted = await ApiService.deleteAllBookings(
      driverId: widget.driverPhone,
    );
    if (!mounted || !deleted) return;
    setState(() => _passengerMessages.clear());
  }

  String _cleanDebugText(String value) {
    if (value.contains('TextEditingController') ||
        value.contains('TextEditingValue')) {
      var match = RegExp(r'text:\s*-\|\s*([^|]+?)\s*\|').firstMatch(value);
      if (match != null) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty && !extracted.contains('selection')) {
          return extracted;
        }
      }

      match = RegExp(r"'([^']+)'").firstMatch(value);
      if (match != null) {
        final extracted = match.group(1)?.trim() ?? '';
        if (extracted.isNotEmpty &&
            !extracted.contains('TextEditing') &&
            !extracted.contains('selection') &&
            extracted.length < 50) {
          return extracted;
        }
      }
    }
    return value;
  }

  Future<Map<String, String>> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final carInfo = await loadDriverCarInfo();
    var firstName = prefs.getString('user_first_name') ?? '';
    var lastName = prefs.getString('user_last_name') ?? '';
    final phone = prefs.getString('user_phone') ?? widget.driverPhone;
    final birthYear = prefs.getString('user_birth_year') ?? '';
    final gender = prefs.getString('user_gender') ?? '—';
    final carBrand = carInfo.brand.isEmpty ? '—' : carInfo.brand;
    final carColor = carInfo.color.isEmpty ? '—' : carInfo.color;
    final carModel = carInfo.model.isEmpty ? '—' : carInfo.model;
    final plateNumber = carInfo.plate.isEmpty ? '—' : carInfo.plate;
    if (kDebugMode) {
      // TEMP DEBUG
      debugPrint('[DriverProfile] car keys=driver_car_color, '
          'driver_car_brand, driver_car_model, driver_plate_number; '
          'color=${carInfo.color}; photo keys=driver_car_photo_1, '
          'driver_car_photo_2, driver_car_photo_3; '
          'paths=${carInfo.photoPaths}');
    }

    firstName = _cleanDebugText(firstName);
    lastName = _cleanDebugText(lastName);

    final fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? [firstName, lastName].where((item) => item.isNotEmpty).join(' ')
        : (prefs.getString('user_name') ?? '—');

    return {
      'full_name': fullName,
      'phone': phone,
      'role': 'Ронанда',
      'birth_year': birthYear,
      'gender': gender,
      'car_brand': carBrand,
      'car_color': carColor,
      'car_model': carModel,
      'plate_number': plateNumber,
    };
  }

  Future<void> _showProfileEditor() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneController = TextEditingController(
      text: prefs.getString('user_phone') ?? widget.driverPhone,
    );
    final carModelController = TextEditingController(
      text: prefs.getString('driver_car_model') ?? '',
    );
    final plateController = TextEditingController(
      text: prefs.getString('driver_plate_number') ?? '',
    );
    String selectedBrand = prefs.getString('driver_car_brand') ?? '';
    String selectedColor = prefs.getString('driver_car_color') ?? '';

    final changed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Редактировать профиль'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Рақами телефон',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final result = await AppRoute.push<String>(
                          context,
                          CarBrandSelectionScreen(
                            brands: supportedCarBrands,
                            selectedBrand: selectedBrand.isNotEmpty
                                ? selectedBrand
                                : null,
                          ),
                        );
                        if (result != null) {
                          setDialogState(() => selectedBrand = result);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              AppIcons.directions_car,
                              color: Color(0xFF0066FF),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedBrand.isNotEmpty
                                    ? selectedBrand
                                    : 'Маркаи мошин',
                                style: TextStyle(
                                  color: selectedBrand.isNotEmpty
                                      ? Colors.black87
                                      : Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(AppIcons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: carModelController,
                      decoration: const InputDecoration(
                        labelText: 'Модели мошин',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final result = await AppRoute.push<String>(
                          context,
                          CarColorSelectionScreen(
                            colors: const [
                              'Сафед',
                              'Сиёҳ',
                              'Нуқрагӣ',
                              'Металлик',
                              'Кабуд',
                              'Зард',
                              'Сабз',
                              'Сурх',
                            ],
                            selectedColor: selectedColor.isNotEmpty
                                ? selectedColor
                                : null,
                          ),
                        );
                        if (result != null) {
                          setDialogState(() => selectedColor = result);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: selectedColor.isNotEmpty
                                    ? {
                                            'Сафед': const Color(0xFFF5F5F5),
                                            'Сиёҳ': const Color(0xFF141414),
                                            'Нуқрагӣ': const Color(0xFFC0C4C8),
                                            'Металлик': const Color(0xFF5A5F66),
                                            'Кабуд': const Color(0xFF1E5AC8),
                                            'Зард': const Color(0xFFF5C814),
                                            'Сабз': const Color(0xFF1E9646),
                                            'Сурх': const Color(0xFFC81E1E),
                                          }[selectedColor] ??
                                          Colors.grey
                                    : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey[400]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                selectedColor.isNotEmpty
                                    ? selectedColor
                                    : 'Ранги мошин',
                                style: TextStyle(
                                  color: selectedColor.isNotEmpty
                                      ? Colors.black87
                                      : Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(AppIcons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: plateController,
                      decoration: const InputDecoration(
                        labelText: 'Рақами давлатӣ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Бекор'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final phoneValue = phoneController.text.trim();
                    final brandValue = selectedBrand.trim();
                    final modelValue = carModelController.text.trim();
                    final colorValue = selectedColor.trim();
                    final plateValue = plateController.text.trim();

                    if (phoneValue.isNotEmpty) {
                      await prefs.setString('user_phone', phoneValue);
                    }
                    if (brandValue.isNotEmpty) {
                      await prefs.setString('driver_car_brand', brandValue);
                    }
                    if (modelValue.isNotEmpty) {
                      await prefs.setString('driver_car_model', modelValue);
                    }
                    if (colorValue.isNotEmpty) {
                      await prefs.setString('driver_car_color', colorValue);
                    }
                    if (plateValue.isNotEmpty) {
                      await prefs.setString('driver_plate_number', plateValue);
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (changed == true) {
      setState(() {});
    }
  }

  /* Widget _buildProfileTab() {
    return FutureBuilder<Map<String, String>>(
      future: _loadProfileData(),
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            {
              'full_name': widget.driverName,
              'phone': widget.driverPhone,
              'role': 'Ронанда',
              'birth_year': '—',
              'gender': '—',
              'car_brand': '—',
              'car_color': '—',
              'car_model': '—',
              'plate_number': '—',
            };

        final vehicleStats = [
          _DriverStat(
            icon: AppIcons.directions_car_filled_rounded,
            label: 'Модел',
            value: data['car_model'] ?? '—',
          ),
          _DriverStat(
            icon: AppIcons.confirmation_number_rounded,
            label: 'Рақами давлатӣ',
            value: data['plate_number'] ?? '—',
          ),
          _DriverStat(
            icon: AppIcons.palette_rounded,
            label: 'Ранги мошин',
            value: data['car_color'] ?? '—',
          ),
          _DriverStat(
            icon: AppIcons.calendar_month_rounded,
            label: 'Соли таваллуд',
            value: data['birth_year'] ?? '—',
          ),
        ];

        return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x331565C0),
                          blurRadius: 20,
                          offset: Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Row(
                          children: [
                        Stack(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isOnline
                                      ? const Color(0xFF22C55E)
                                      : Colors.grey,
                                  width: 3,
                                ),
                                image: _profileImage != null
                                    ? DecorationImage(
                                        image: MemoryImage(_profileImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _profileImage == null
                                  ? const Icon(
                                      AppIcons.person_rounded,
                                      size: 36,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0066FF),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  AppIcons.add,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 42),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                              Text(
                                data['full_name'] ?? 'Ронанда',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.24),
                                  ),
                                ),
                                child: Text(
                                  'Ронанда',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                                ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            AppIcons.phone_rounded,
                                            size: 14,
                                            color: Colors.white.withValues(
                                              alpha: 0.82,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              data['phone'] ?? '—',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white.withValues(
                                                  alpha: 0.82,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.16),
                              shape: const CircleBorder(),
                              child: IconButton(
                                onPressed: _openSettingsScreen,
                                tooltip: 'Танзимот',
                                icon: const Icon(
                                  AppIcons.settings_rounded,
                                  size: 23,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: double.infinity,
                  child: _ProfileRatingCard(),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: vehicleStats
                      .map((stat) => _buildDriverStatBadge(stat))
                      .toList(),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _showProfileEditor,
                    icon: const Icon(AppIcons.edit_rounded, size: 18),
                    label: const Text('Таҳрир кардан'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0066FF),
                      side: const BorderSide(color: Color(0xFF0066FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildProfileActions(),
              ],
            ),
        );
      },
    );
  }

  */

  Widget _buildProfileTab() {
    return FutureBuilder<Map<String, String>>(
      future: _loadProfileData(),
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            {
              'full_name': widget.driverName,
              'phone': widget.driverPhone,
              'birth_year': '—',
              'car_color': '—',
              'car_model': '—',
              'plate_number': '—',
            };
        final vehicleStats = [
          _DriverStat(
            icon: AppIcons.directions_car_filled_rounded,
            label: 'Модел',
            value: data['car_model'] ?? '—',
          ),
          _DriverStat(
            icon: AppIcons.confirmation_number_rounded,
            label: 'Рақами давлатӣ',
            value: data['plate_number'] ?? '—',
          ),
          _DriverStat(
            icon: AppIcons.palette_rounded,
            label: 'Ранги мошин',
            value: data['car_color'] ?? '—',
          ),
          _DriverStat(
            icon: AppIcons.calendar_month_rounded,
            label: 'Соли таваллуд',
            value: data['birth_year'] ?? '—',
          ),
        ];

        return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x331565C0),
                        blurRadius: 20,
                        offset: Offset(0, 9),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _pickProfileImage,
                            child: Stack(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isOnline
                                          ? const Color(0xFF22C55E)
                                          : Colors.grey,
                                      width: 3,
                                    ),
                                    image: _profileImage == null
                                        ? null
                                        : DecorationImage(
                                            image: MemoryImage(_profileImage!),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  child: _profileImage == null
                                      ? const Icon(
                                          AppIcons.person_rounded,
                                          size: 36,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0066FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      AppIcons.add,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 42),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['full_name'] ?? 'Ронанда',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.16,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Ронанда',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        AppIcons.phone_rounded,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          data['phone'] ?? '—',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: _openSettingsScreen,
                            tooltip: 'Танзимот',
                            icon: const Icon(
                              AppIcons.settings_rounded,
                              size: 23,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 0,
                        child: _ProfileRatingBadge(rating: _driverRating),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vehicleStats.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 116,
                  ),
                  itemBuilder: (context, index) =>
                      _buildDriverStatBadge(vehicleStats[index]),
                ),
                const SizedBox(height: 20),
                _buildCarPhotosCard(data['car_color'] ?? ''),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _showProfileEditor,
                    icon: const Icon(AppIcons.edit_rounded, size: 18),
                    label: const Text('Таҳрир кардан'),
                  ),
                ),
                const SizedBox(height: 16),
                _buildProfileActions(),
              ],
            ),
        );
      },
    );
  }

  Widget _buildProfileActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EBF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A173B73),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileActionTile(
            icon: AppIcons.payments_rounded,
            label: 'Даромад',
            onTap: _openDriverEarnings,
          ),
          _buildProfileActionDivider(),
          _buildProfileActionTile(
            icon: AppIcons.history_rounded,
            label: 'Таърихи сафарҳо',
            onTap: _showRideHistory,
          ),
          _buildProfileActionDivider(),
          _buildProfileActionTile(
            icon: AppIcons.info_rounded,
            label: 'Дар бораи барнома',
            onTap: _showAboutApp,
          ),
          _buildProfileActionDivider(),
          _buildProfileActionTile(
            icon: AppIcons.settings_rounded,
            label: 'Танзимот',
            onTap: _openSettingsScreen,
          ),
        ],
      ),
    );
  }

  void _openDriverEarnings() {
    AppRoute.push<void>(context, const DriverEarningsScreen());
  }

  Widget _buildProfileActionDivider() {
    return const Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: Color(0xFFF0F2F5),
    );
  }

  Widget _buildProfileActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFF0066FF), size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(
                AppIcons.chevron_right_rounded,
                color: Color(0xFF9AA5B5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAboutApp() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _DriverAboutSheet(),
    );
  }

  Future<void> _showRideHistory() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _DriverRideHistorySheet(),
    );
  }

  Widget _buildDriverStatBadge(_DriverStat stat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A173B73),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: const Color(0xFF0066FF), size: 19),
          ),
          const SizedBox(height: 9),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 3),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return AppBottomNav(
      currentIndex: _currentIndex,
      onTap: (index) {
        debugPrint('DriverHomeScreen tab switch: $_currentIndex -> $index');
        setState(() => _currentIndex = index);
      },
      items: const [
        AppNavItem(icon: LucideIcons.house, label: 'Асосӣ'),
        AppNavItem(icon: LucideIcons.route, label: 'Масир'),
        AppNavItem(
          icon: LucideIcons.messageCircle,
          label: 'Паёмҳо',
        ),
        AppNavItem(icon: LucideIcons.userRound, label: 'Профил'),
      ],
    );
  }
}

class BookingDecisionScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final String driverId;

  const BookingDecisionScreen({
    super.key,
    required this.booking,
    required this.driverId,
  });

  @override
  State<BookingDecisionScreen> createState() => _BookingDecisionScreenState();
}

class _BookingDecisionScreenState extends State<BookingDecisionScreen> {
  bool _sending = false;

  Future<void> _decide(bool approved) async {
    if (_sending) return;
    setState(() => _sending = true);
    final result = await ApiService.decideBooking(
      bookingId: widget.booking['id']?.toString() ?? '',
      approved: approved,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (result['ok'] == true) {
      final booking = result['booking'];
      Navigator.of(
        context,
      ).pop(booking is Map<String, dynamic> ? booking : widget.booking);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['error']?.toString() ?? 'Хатогӣ рӯй дод'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passengerName = widget.booking['passenger_name']?.toString().trim();
    final from = widget.booking['from_location']?.toString() ?? '';
    final to = widget.booking['to_location']?.toString() ?? '';
    final pending = widget.booking['status']?.toString() ?? 'pending';
    final requestedSeats =
        int.tryParse(widget.booking['requested_seats']?.toString() ?? '') ?? 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Дархости брон')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              AppIcons.person_pin_circle_rounded,
              size: 72,
              color: Color(0xFF0066FF),
            ),
            const SizedBox(height: 16),
            Text(
              passengerName == null || passengerName.isEmpty
                  ? 'Мусофир'
                  : passengerName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              '$from → $to',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              '$requestedSeats ҷой гирифтан мехоҳад',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              pending == 'pending'
                  ? 'Мусофир ҷойро брон кардан мехоҳад.'
                  : 'Ин дархост аллакай ҷавоб гирифтааст.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: pending == 'pending' && !_sending
                  ? () => _decide(true)
                  : null,
              child: const Text(
                'Иҷозат',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: pending == 'pending' && !_sending
                  ? () => _decide(false)
                  : null,
              child: const Text(
                'Не',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteMapTab extends StatefulWidget {
  final VoidCallback onEndTripRequested;

  const _RouteMapTab({required this.onEndTripRequested});

  @override
  State<_RouteMapTab> createState() => _RouteMapTabState();
}

class _SpeedDisplay {
  const _SpeedDisplay({this.speedKmh});

  final int? speedKmh;
}

class _RouteMapTabState extends State<_RouteMapTab>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _initialLocation = LatLng(38.5598, 68.7870);
  static const _cameraMoveDuration = Duration(milliseconds: 1800);
  static const _cameraFocusDuration = Duration(milliseconds: 700);
  static const _cameraPauseDuration = Duration(seconds: 1);
  final _mapController = MapController();
  late final AnimationController _cameraAnimationController =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      );
  late final AnimationController _routeDrawController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  final _searchController = TextEditingController();
  double _zoom = 13;
  LatLng _selectedLocation = _initialLocation;
  LatLng? _routeStart;
  LatLng? _routeEnd;
  String? _routeStartName;
  String? _routeEndName;
  List<_PlaceSearchResult> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  List<LatLng> _routePoints = [];
  String? _routeDistance;
  String? _routeDuration;
  bool _tripStarted = false;
  final ValueNotifier<LatLng?> _carPosition = ValueNotifier<LatLng?>(null);
  final ValueNotifier<double> _traveledDistance = ValueNotifier<double>(0);
  final ValueNotifier<_SpeedDisplay> _speedDisplay =
      ValueNotifier<_SpeedDisplay>(const _SpeedDisplay(speedKmh: 0));
  Position? _previousGoodPosition;
  bool _isTrackingLocation = false;
  bool _isStartingLocationTracking = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _speedStaleTimer;
  Timer? _focusCheckTimer;
  bool _routeAnimationPending = false;
  bool _routeIntroComplete = false;
  bool _animateRouteLine = false;
  bool _routeIntroPlaying = false;
  String? _loadedTripId;
  int _routeRequestId = 0;
  int _routeIntroGeneration = 0;
  http.Client? _routeHttpClient;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadActiveRoute();
    _checkTripStarted();
    // Live GPS only — the car icon never moves by itself.
    unawaited(_startLocationTracking(requestPermission: true));
    // Watch for the "start trip" flag and introduce the route on the map.
    _focusCheckTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted) {
        _focusCheckTimer?.cancel();
        return;
      }
      unawaited(_syncActiveRouteAndFocus());
    });
  }

  Future<void> _checkTripStarted() async {
    final prefs = await SharedPreferences.getInstance();
    final started = prefs.getBool('trip_started') ?? false;
    if (started && prefs.getString('active_trip_id') != null && mounted) {
      setState(() => _tripStarted = true);
    }
  }

  Future<void> _loadActiveRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final tripId = prefs.getString('active_trip_id');
    final started = prefs.getBool('trip_started') ?? false;
    if (tripId == null || !started) {
      _clearMapRoute();
      _loadedTripId = null;
      return;
    }
    final fromName = prefs.getString('active_route_from');
    final toName = prefs.getString('active_route_to');
    final from = locationCoordinatesFor(fromName);
    final to = locationCoordinatesFor(toName);

    if (!mounted) return;
    _loadedTripId = tripId;
    _cancelRouteRequest();
    final requestId = _routeRequestId;
    setState(() {
      _routeStartName = fromName;
      _routeEndName = toName;
      _routeStart = from;
      _routeEnd = to;
      _routePoints = [];
      // The map (OSRM) fills distance/duration in once its route arrives.
      _routeDistance = null;
      _routeDuration = null;
    });

    if (from != null && to != null) {
      // Fetch real road route from OSRM API
      await _fetchRoute(from, to, requestId);
    }
  }

  Future<void> _syncActiveRouteAndFocus() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final tripId = prefs.getString('active_trip_id');
    final started = prefs.getBool('trip_started') ?? false;
    if (!started || tripId == null) {
      if (_loadedTripId != null || _routeStart != null) {
        _loadedTripId = null;
        _clearMapRoute();
      }
      return;
    }
    if (tripId != _loadedTripId) await _loadActiveRoute();
    await _checkPendingRouteFocus();
  }

  void _resetMapAfterTrip() {
    _loadedTripId = null;
    _cancelRouteRequest();
    _routeIntroGeneration++;
    _cameraAnimationController.stop(canceled: true);
    _routeDrawController.stop(canceled: true);
    _routeIntroPlaying = false;
    if (!mounted) return;
    setState(() {
      _routePoints = [];
      _routeDistance = null;
      _routeDuration = null;
      _routeStart = null;
      _routeEnd = null;
      _routeStartName = null;
      _routeEndName = null;
      _traveledDistance.value = 0;
    });
    final position = _carPosition.value;
    final target = position ?? _initialLocation;
    try {
      _mapController.move(target, 15);
    } catch (_) {
      // The map controller is not attached until FlutterMap's first frame.
    }
  }

  void _clearMapRoute() {
    _cancelRouteRequest();
    _routeIntroGeneration++;
    _cameraAnimationController.stop(canceled: true);
    _routeDrawController.stop(canceled: true);
    if (!mounted) return;
    setState(() {
      _routePoints = [];
      _routeDistance = null;
      _routeDuration = null;
      _routeStart = null;
      _routeEnd = null;
      _routeStartName = null;
      _routeEndName = null;
      _tripStarted = false;
      _animateRouteLine = false;
      _routeIntroPlaying = false;
    });
  }

  void _cancelRouteRequest() {
    _routeRequestId++;
    _routeHttpClient?.close();
    _routeHttpClient = null;
  }

  /// Fetches real road route points from OSRM (Open Source Routing Machine)
  Future<void> _fetchRoute(LatLng from, LatLng to, int requestId) async {
    final client = http.Client();
    _routeHttpClient?.close();
    _routeHttpClient = client;
    try {
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}',
        {'overview': 'full', 'geometries': 'geojson', 'steps': 'false'},
      );
      final response = await client.get(uri);
      if (!mounted || requestId != _routeRequestId) return;

      if (response.statusCode != 200) {
        throw Exception('Роҳ дастнорас аст');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List? ?? [];
      if (routes.isEmpty) throw Exception('OSRM returned no routes');

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List? ?? [];

      final points = coordinates
          .map((coord) {
            final pair = coord as List<dynamic>;
            return LatLng(
              (pair[1] as num).toDouble(),
              (pair[0] as num).toDouble(),
            );
          })
          .where((point) => point.latitude.isFinite && point.longitude.isFinite)
          .toList();

      if (points.length < 2) {
        throw Exception('OSRM route geometry is empty');
      }

      // Extract distance (meters) and duration (seconds) from OSRM
      final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0;
      final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0;

      final distanceKm = distanceMeters / 1000;
      final distanceText = distanceKm >= 100
          ? '${distanceKm.toStringAsFixed(0)} км'
          : '${distanceKm.toStringAsFixed(1)} км';

      final hours = (durationSeconds / 3600).floor();
      final minutes = ((durationSeconds % 3600) / 60).round();
      final durationText = hours > 0
          ? '$hours соат $minutes дақ'
          : '$minutes дақ';

      if (!mounted) return;
      if (requestId != _routeRequestId) return;
      setState(() {
        _routePoints = points;
        // The map itself (OSRM) is the single source of truth for the duration
        // and distance that the screen shows.
        _routeDuration = durationText;
        _routeDistance = distanceText;
        _traveledDistance.value = 0;
      });
      if (_routeAnimationPending && _routeIntroComplete) {
        _startRouteLineAnimation();
      }
      // Persist the OSRM estimate for the driver's start button and map card.
      unawaited(_saveOsrmEstimate(distanceKm, durationSeconds, requestId));
    } catch (_) {
      // If OSRM fails, fall back to a straight line
      if (!mounted) return;
      if (requestId != _routeRequestId) return;
      final distanceKm = approximateDrivingDistanceKm(
        _routeStartName,
        _routeEndName,
      );
      final durationMinutes = approximateDrivingDurationMinutes(
        _routeStartName,
        _routeEndName,
      );
      setState(() {
        _routePoints = [from, to];
        if (distanceKm != null && durationMinutes != null) {
          _routeDistance = '≈${distanceKm.toStringAsFixed(1)} км';
          _routeDuration = '≈$durationMinutes дақ.';
        }
        _traveledDistance.value = 0;
      });
      if (_routeAnimationPending && _routeIntroComplete) {
        _startRouteLineAnimation();
      }
    } finally {
      if (identical(_routeHttpClient, client)) _routeHttpClient = null;
      client.close();
    }
  }

  Future<void> _saveOsrmEstimate(
    double distanceKm,
    double durationSeconds,
    int requestId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (requestId != _routeRequestId ||
        prefs.getString('active_trip_id') != _loadedTripId)
      return;
    await prefs.setDouble('route_osrm_distance_km', distanceKm);
    await prefs.setInt('route_osrm_duration_seconds', durationSeconds.round());
    await prefs.setInt(
      'active_route_duration_minutes',
      (durationSeconds / 60).round(),
    );
    await prefs.setDouble('active_route_distance_km', distanceKm);
  }

  Future<void> _startLocationTracking({bool requestPermission = false}) async {
    if (_isStartingLocationTracking || !mounted) return;
    _isStartingLocationTracking = true;
    try {
      var permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      final permissionGranted =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      if (!permissionGranted) {
        _positionSubscription?.cancel();
        _positionSubscription = null;
        _isTrackingLocation = false;
        _speedStaleTimer?.cancel();
        _speedDisplay.value = const _SpeedDisplay();
        return;
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        _positionSubscription?.cancel();
        _positionSubscription = null;
        _isTrackingLocation = false;
        _speedStaleTimer?.cancel();
        _speedDisplay.value = const _SpeedDisplay();
        return;
      }
      if (!mounted || _isTrackingLocation) return;

      final LocationSettings settings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        settings = AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          intervalDuration: const Duration(milliseconds: 500),
          forceLocationManager: true,
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        settings = AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          activityType: ActivityType.automotiveNavigation,
        );
      } else {
        settings = const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        );
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        _onPositionUpdate,
        onError: (Object error, StackTrace stackTrace) {
          _isTrackingLocation = false;
          _positionSubscription?.cancel();
          _positionSubscription = null;
          _speedStaleTimer?.cancel();
          if (kDebugMode) {
            debugPrint('Route map location stream error: $error');
          }
          if (mounted) _speedDisplay.value = const _SpeedDisplay();
        },
      );
      _isTrackingLocation = true;
      _speedDisplay.value = const _SpeedDisplay(speedKmh: 0);
      _armSpeedTimeout();
    } catch (_) {
      _isTrackingLocation = false;
      _positionSubscription?.cancel();
      _positionSubscription = null;
      if (mounted) _speedDisplay.value = const _SpeedDisplay(speedKmh: 0);
    } finally {
      _isStartingLocationTracking = false;
    }
  }

  void _armSpeedTimeout() {
    _speedStaleTimer?.cancel();
    _speedStaleTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      _speedDisplay.value = const _SpeedDisplay(speedKmh: 0);
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_startLocationTracking());
  }

  void _onPositionUpdate(Position position) {
    if (!mounted) return;

    final previous = _previousGoodPosition;
    var speedKmh = position.speed.isFinite && position.speed >= 0
        ? position.speed * 3.6
        : 0.0;
    if (position.speed == 0 && previous != null) {
      final elapsedSeconds =
          position.timestamp.difference(previous.timestamp).inMilliseconds /
          1000;
      if (elapsedSeconds > 0) {
        final distanceSpeedKmh =
            Geolocator.distanceBetween(
              previous.latitude,
              previous.longitude,
              position.latitude,
              position.longitude,
            ) /
            elapsedSeconds *
            3.6;
        if (distanceSpeedKmh > 3) speedKmh = distanceSpeedKmh;
      }
    }
    final displayedSpeed = speedKmh < 1.5 ? 0 : speedKmh;

    _speedDisplay.value = _SpeedDisplay(speedKmh: displayedSpeed.round());
    _armSpeedTimeout();
    _previousGoodPosition = position;
    if (_tripStarted) {
      final point = LatLng(position.latitude, position.longitude);
      final previousPoint = _carPosition.value;
      if (previousPoint != null) {
        _traveledDistance.value += const Distance().as(
          LengthUnit.Kilometer,
          previousPoint,
          point,
        );
      }
      _carPosition.value = point;
      setState(() {});
    }
  }
  Widget _buildSpeedIndicator() => ValueListenableBuilder<_SpeedDisplay>(
    valueListenable: _speedDisplay,
    builder: (context, display, _) {
      final speedText = display.speedKmh?.toString() ?? '--';
      const primary = Color(0xFF0066FF);
      return Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.speed_rounded, size: 18, color: primary),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Суръат',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            speedText,
                            style: const TextStyle(
                              fontSize: 23,
                              color: Colors.black87,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'км/ч',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusCheckTimer?.cancel();
    _speedStaleTimer?.cancel();
    _cancelRouteRequest();
    _routeIntroGeneration++;
    _cameraAnimationController.stop(canceled: true);
    _positionSubscription?.cancel();
    _carPosition.dispose();
    _traveledDistance.dispose();
    _speedDisplay.dispose();
    _searchController.dispose();
    _cameraAnimationController.dispose();
    _routeDrawController.dispose();
    super.dispose();
  }

  /// After "Оғози сафар": frame A+B on screen, then zoom in on A once the
  /// the route introduction is ready to begin.
  Future<void> _checkPendingRouteFocus() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool('route_fit_pending') ?? false;
    if (!pending || !mounted || _routeIntroPlaying) return;
    final from = _routeStart;
    final to = _routeEnd;
    if (from == null || to == null || !mounted) return;
    _routeIntroPlaying = true;
    await prefs.setBool('route_fit_pending', false);
    unawaited(_playRouteIntroduction(from, to));
  }

  Future<void> _playRouteIntroduction(LatLng a, LatLng b) async {
    final generation = ++_routeIntroGeneration;
    _routeAnimationPending = true;
    _routeIntroComplete = false;
    _animateRouteLine = true;
    _routeDrawController.stop();
    _routeDrawController.value = 0;
    await _animateCamera(
      _mapController.camera.center,
      a,
      _zoom,
      15,
      duration: _cameraFocusDuration,
    );
    if (!mounted || generation != _routeIntroGeneration) return;
    await Future<void>.delayed(_cameraPauseDuration);
    if (!mounted || generation != _routeIntroGeneration) return;
    await _animateCamera(a, b, 15, 15, duration: _cameraMoveDuration);
    if (!mounted || generation != _routeIntroGeneration) return;
    await Future<void>.delayed(_cameraPauseDuration);
    if (!mounted || generation != _routeIntroGeneration) return;

    final halfKm = const Distance().as(LengthUnit.Kilometer, a, b) / 2;
    final fitZoom = halfKm <= 8
        ? 14.0
        : halfKm <= 20
        ? 12.0
        : halfKm <= 45
        ? 10.0
        : halfKm <= 110
        ? 8.0
        : 6.0;
    final center = LatLng(
      (a.latitude + b.latitude) / 2,
      (a.longitude + b.longitude) / 2,
    );
    await _animateCamera(b, center, 15, fitZoom, duration: _cameraMoveDuration);
    if (mounted && generation == _routeIntroGeneration) {
      _routeIntroComplete = true;
      _startRouteLineAnimation();
      _routeIntroPlaying = false;
    }
  }

  Future<void> _animateCamera(
    LatLng from,
    LatLng to,
    double fromZoom,
    double toZoom, {
    Duration duration = _cameraMoveDuration,
  }) async {
    final controller = _cameraAnimationController;
    controller.duration = duration;
    controller.reset();
    void moveCamera() {
      final t = Curves.easeInOutCubic.transform(controller.value);
      final center = LatLng(
        from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t,
      );
      _zoom = fromZoom + (toZoom - fromZoom) * t;
      _mapController.move(center, _zoom);
    }

    controller.addListener(moveCamera);
    try {
      await controller.forward().orCancel;
    } on TickerCanceled {
      return;
    } finally {
      controller.removeListener(moveCamera);
    }
  }

  void _startRouteLineAnimation() {
    if (_routePoints.length < 2) return;
    _routeAnimationPending = false;
    _routeDrawController.forward(from: 0);
  }

  List<LatLng> get _visibleRoutePoints {
    if (_routePoints.length < 2) return _routePoints;
    if (!_animateRouteLine) return _routePoints;
    final progress = _routeDrawController.value;
    if (progress >= 1) return _routePoints;
    final segments = _routePoints.length - 1;
    final visibleSegments = (progress * segments).floor();
    final points = _routePoints.take(visibleSegments + 1).toList();
    final nextIndex = visibleSegments + 1;
    if (nextIndex < _routePoints.length) {
      final current = _routePoints[visibleSegments];
      final next = _routePoints[nextIndex];
      final fraction = progress * segments - visibleSegments;
      points.add(
        LatLng(
          current.latitude + (next.latitude - current.latitude) * fraction,
          current.longitude + (next.longitude - current.longitude) * fraction,
        ),
      );
    }
    return points;
  }

  /// Picks a zoom that keeps both cities visible while getting as close as
  /// possible (the route never disappears from the edges of the map).
  void _fitRouteBounds(LatLng a, LatLng b) {
    final halfKm = const Distance().as(LengthUnit.Kilometer, a, b) / 2;
    final double zoom = halfKm <= 8
        ? 14
        : halfKm <= 20
        ? 12
        : halfKm <= 45
        ? 10
        : halfKm <= 110
        ? 8
        : 6;
    _zoom = zoom;
    _mapController.move(
      LatLng((a.latitude + b.latitude) / 2, (a.longitude + b.longitude) / 2),
      _zoom,
    );
  }

  /// Zooms the camera right onto the start city (marker A).
  void _focusOnStart(LatLng start) {
    _zoom = 15;
    _mapController.move(start, 15);
  }

  void _changeZoom(double difference) {
    _zoom = (_zoom + difference).clamp(3, 18).toDouble();
    _mapController.move(_mapController.camera.center, _zoom);
  }

  void _goToInitialLocation() {
    _zoom = 13;
    setState(() => _selectedLocation = _initialLocation);
    _mapController.move(_initialLocation, _zoom);
  }

  Future<void> _searchPlace([String? value]) async {
    final query = (value ?? _searchController.text).trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResults = [];
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'limit': '5',
        'countrycodes': 'tj',
        'q': query,
      });
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'InterTaxi/1.0 (com.intertaxi.intertaxi)',
          'Accept-Language': 'tg,ru;q=0.9,en;q=0.8',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Ҷустуҷӯ дастнорас аст');
      }

      final places = (jsonDecode(response.body) as List)
          .map(
            (item) => _PlaceSearchResult.fromJson(item as Map<String, dynamic>),
          )
          .where((item) => item.location != null)
          .toList();

      if (!mounted) return;
      setState(() => _searchResults = places);
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchError = 'Ҷой ёфт нашуд. Аз нав кӯшиш кунед.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(_PlaceSearchResult result) {
    final location = result.location!;
    _searchController.text = result.name;
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedLocation = location;
      _searchResults = [];
    });
    _zoom = 15;
    _mapController.move(location, _zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialLocation,
            initialZoom: 13,
            maxZoom: 18,
            minZoom: 3,
            onTap: (_, point) => setState(() => _selectedLocation = point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.intertaxi.app',
              maxNativeZoom: 19,
            ),
            if (_routePoints.isNotEmpty)
              AnimatedBuilder(
                animation: _routeDrawController,
                builder: (context, _) {
                  final visiblePoints = _visibleRoutePoints;
                  if (visiblePoints.length < 2) return const SizedBox.shrink();
                  return PolylineLayer(
                    polylines: [
                      Polyline(
                        points: visiblePoints,
                        color: const Color(0xFF0066FF),
                        strokeWidth: 6,
                        borderColor: Colors.white,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  );
                },
              ),
            MarkerLayer(
              markers: _routeStart != null && _routeEnd != null
                  ? [
                      _routeMarker(_routeStart!, Colors.green, 'А'),
                      _routeMarker(_routeEnd!, Colors.red, 'Б'),
                      if (_carPosition.value != null)
                        Marker(
                          point: _carPosition.value!,
                          width: 48,
                          height: 48,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0066FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 5),
                              ],
                            ),
                            child: const Icon(
                              AppIcons.local_taxi_rounded,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ]
                  : [
                      Marker(
                        point: _selectedLocation,
                        width: 54,
                        height: 54,
                        child: const Icon(
                          AppIcons.location_on_rounded,
                          size: 54,
                          color: Color(0xFF0066FF),
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 5),
                          ],
                        ),
                      ),
                    ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(top: 18, right: 16, child: _buildSpeedIndicator()),
        if (_routeStartName != null &&
            _routeEndName != null &&
            (_routeStart == null || _routeEnd == null))
          const Positioned(
            left: 16,
            right: 16,
            bottom: 90,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(14)),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Координатаи ин макон ҳанӯз илова нашудааст'),
              ),
            ),
          ),
        if (_searchResults.isNotEmpty || _searchError != null)
          Positioned(
            top: 82,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              elevation: 5,
              child: _searchError != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _searchError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(
                            AppIcons.location_on_outlined,
                            color: Color(0xFF0066FF),
                          ),
                          title: Text(
                            result.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
            ),
          ),

        // Route info card: distance & duration
        if (_routeDistance != null && _routeDuration != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 90,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Distance
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0066FF,
                                ).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                AppIcons.straighten_rounded,
                                size: 20,
                                color: Color(0xFF0066FF),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Масофа',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  _routeDistance!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Divider
                      Container(width: 1, height: 32, color: Colors.grey[300]),
                      const SizedBox(width: 12),
                      // Duration
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                AppIcons.access_time_rounded,
                                size: 20,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Вақт',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  _routeDuration!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Traveled distance (only when trip started)
                  if (_tripStarted)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              AppIcons.route_rounded,
                              size: 20,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Масофаи тайкарда',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${_traveledDistance.value.toStringAsFixed(1)} км',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (_routeStartName != null && _routeEndName != null)
          Positioned(
            left: 16,
            right: 84,
            bottom: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.trip_origin,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _routeStartName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(AppIcons.arrow_forward_rounded, size: 18),
                  ),
                  const Icon(
                    AppIcons.location_on_rounded,
                    size: 18,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _routeEndName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_tripStarted)
          Positioned(
            right: 16,
            bottom: 104,
            child: SizedBox(
              width: 148,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: widget.onEndTripRequested,
                icon: const Icon(AppIcons.stop_circle_outlined),
                label: const Text('Анҷоми сафар'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 28,
          child: _MapControlButton(
            icon: AppIcons.my_location_rounded,
            onPressed: _goToInitialLocation,
          ),
        ),
      ],
    );
  }

  Marker _routeMarker(LatLng point, Color color, String label) {
    return Marker(
      point: point,
      width: 42,
      height: 42,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5)],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _PlaceSearchResult {
  final String name;
  final LatLng? location;

  const _PlaceSearchResult({required this.name, required this.location});

  factory _PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    return _PlaceSearchResult(
      name: json['display_name'] as String? ?? 'Ҷойи номаълум',
      location:
          double.tryParse(json['lat']?.toString() ?? '') != null &&
              double.tryParse(json['lon']?.toString() ?? '') != null
          ? LatLng(
              double.parse(json['lat'].toString()),
              double.parse(json['lon'].toString()),
            )
          : null,
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: const Color(0xFF0066FF)),
        ),
      ),
    );
  }
}

class _DriverStat {
  final IconData icon;
  final String label;
  final String value;

  const _DriverStat({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _ProfileRatingBadge extends StatelessWidget {
  final double rating;

  const _ProfileRatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.star_rounded, color: Color(0xFFFFD166), size: 19),
          const SizedBox(width: 4),
          Text(
            rating == 0 ? '—' : rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverAboutSheet extends StatelessWidget {
  const _DriverAboutSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFD5DCE7),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
            const SizedBox(height: 20),
            const InterTaxiLogo(size: 82, showTagline: true),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'v1.0.0',
                style: TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'InterTaxi — Барномаи муосири такси ва сафарҳои байнишаҳрӣ дар Тоҷикистон.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1D2735),
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _AboutFeature(
              icon: AppIcons.route_rounded,
              text: 'Эълон ва идоракунии сафарҳои байнишаҳрӣ',
            ),
            _AboutFeature(
              icon: AppIcons.map_rounded,
              text: 'Харитаи зинда ва масири воқеии роҳ',
            ),
            _AboutFeature(
              icon: AppIcons.people_alt_rounded,
              text: 'Пайвасти мустақими ронанда ва мусофир',
            ),
            const SizedBox(height: 12),
            const Text(
              'Developed by InterTaxi Team',
              style: TextStyle(
                color: Color(0xFF7A8798),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  side: const BorderSide(color: Color(0xFF1565C0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Пӯшидан'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AboutFeature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4F5D6F),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverRideHistorySheet extends StatelessWidget {
  const _DriverRideHistorySheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFD5DCE7),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Таърихи сафарҳо',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172235),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.58,
            child: FutureBuilder<List<Order>>(
              future: loadOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data ?? const <Order>[];
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.route_rounded,
                          size: 52,
                          color: Colors.grey[350],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Ҳанӯз сафар сабт нашудааст',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final departure = DateTime.tryParse(order.departureTime);
                    final isCompleted =
                        departure != null && departure.isBefore(DateTime.now());
                    final status = isCompleted ? 'Анҷом ёфт' : 'Фаъол';
                    final statusColor = isCompleted
                        ? const Color(0xFF718096)
                        : const Color(0xFF168A52);
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5EAF1)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A173B73),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              AppIcons.route_rounded,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${order.fromLocation} → ${order.toLocation}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D2735),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${order.price} • ${order.seats} ҷой',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _resetProfileAndRestart(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;

    AppRoute.replaceAll<void>(context, const RegistrationScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Танзимот'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Танзимоти ҳисоби корбар',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Бо зер кардани тугмаи зерин, ҳамаи маълумоти профил аз нав оғоз карда мешавад.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _resetProfileAndRestart(context),
                icon: const Icon(AppIcons.restart_alt_rounded),
                label: const Text('Аз нав оғоз кардан'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => AppRoute.pushModal<void>(
                  context,
                  const ServerSettingsScreen(),
                ),
                icon: const Icon(AppIcons.dns_rounded),
                label: const Text('Сервер'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0066FF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF0066FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carModelController = TextEditingController();
  final _licensePlateController = TextEditingController();
  String? _selectedCarBrand;
  bool _isLoading = false;
  bool _submitButtonPressed = false;

  @override
  void dispose() {
    _carModelController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  Widget _buildLicensePlateBox({
    required TextEditingController controller,
    required int startIndex,
    required int length,
    required bool isNumber,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        maxLength: length,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        inputFormatters: [
          TextInputFormatter.withFunction((oldValue, newValue) {
            // Only allow numbers for first and last sections
            if (isNumber) {
              final filtered = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
              return TextEditingValue(
                text: filtered.substring(0, min(filtered.length, length)),
                selection: newValue.selection,
              );
            } else {
              // Only allow letters for middle section
              final filtered = newValue.text.replaceAll(
                RegExp(r'[^A-Za-z]'),
                '',
              );
              return TextEditingValue(
                text: filtered
                    .substring(0, min(filtered.length, length))
                    .toUpperCase(),
                selection: newValue.selection,
              );
            }
          }),
        ],
      ),
    );
  }

  Future<void> _saveDriverProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final originalFirstName = prefs.getString('user_first_name') ?? '';
    final originalLastName = prefs.getString('user_last_name') ?? '';
    final originalBirthYear = prefs.getString('user_birth_year') ?? '';

    await prefs.setString('app_session_version', _appSessionVersion);
    await prefs.setString('user_name', widget.passengerName);
    await prefs.setString('user_phone', widget.passengerPhone);
    await prefs.setString('user_role', 'driver');
    await prefs.setString(
      'user_first_name',
      originalFirstName.isNotEmpty
          ? originalFirstName
          : widget.passengerName.split(RegExp(r'\s+')).first,
    );
    await prefs.setString(
      'user_last_name',
      originalLastName.isNotEmpty
          ? originalLastName
          : widget.passengerName.split(RegExp(r'\s+')).skip(1).join(' '),
    );
    await prefs.setString('user_birth_year', originalBirthYear);

    if (_selectedCarBrand != null) {
      await prefs.setString('driver_car_brand', _selectedCarBrand!);
    }
    if (_carModelController.text.trim().isNotEmpty) {
      await prefs.setString(
        'driver_car_model',
        _carModelController.text.trim(),
      );
    }
    if (_licensePlateController.text.trim().isNotEmpty) {
      await prefs.setString(
        'driver_plate_number',
        _licensePlateController.text.trim(),
      );
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted) {
          setState(() => _isLoading = false);
          await _saveDriverProfile();
          if (!mounted) return;
          AppRoute.replace<void, void>(
            context,
            DriverPhotoCollectionScreen(
              driverName: widget.passengerName,
              driverPhone: widget.passengerPhone,
            ),
          );
        }
      });
    }
  }

  Widget _buildAnimatedSubmitButton(bool enabled) => Listener(
    onPointerDown: enabled
        ? (_) => setState(() => _submitButtonPressed = true)
        : null,
    onPointerUp: enabled
        ? (_) => setState(() => _submitButtonPressed = false)
        : null,
    onPointerCancel: enabled
        ? (_) => setState(() => _submitButtonPressed = false)
        : null,
    child: AnimatedScale(
      scale: _submitButtonPressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      child: AppButton(
        text: 'Идома додан',
        enabled: enabled,
        onPressed: _handleSubmit,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final allFilled =
        (_selectedCarBrand?.isNotEmpty ?? false) &&
        _carModelController.text.trim().isNotEmpty &&
        RegExp(r'^\d{4}[A-Z]{2}\d{2}$').hasMatch(_licensePlateController.text);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) => Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 16),
            child: child,
          ),
        ),
        child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/informationcar.png',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Маълумоти мошин',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F1B3D),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Маълумоти мошини худро ворид кунед',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF4B5B7C),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Маркаи мошин',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7690),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      AppField(
                                        hint: '',
                                        icon: Icons.directions_car_rounded,
                                        logoBrand: _selectedCarBrand,
                                        isPicker: true,
                                        value: _selectedCarBrand ?? '',
                                        onTap: () async {
                                          final selected =
                                              await showModalBottomSheet<String>(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor: Colors.transparent,
                                                builder: (_) => _PickerSheet(
                                                  title: 'Маркаи мошин',
                                                  child: CarBrandSelectionScreen(
                                                    brands: supportedCarBrands,
                                                    selectedBrand: _selectedCarBrand,
                                                  ),
                                                ),
                                              );
                                          if (selected != null && mounted) {
                                            setState(
                                              () => _selectedCarBrand = selected,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Модел',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7690),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        height: 48,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(.97),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: const Color(0xFFDCE6F5),
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: _carModelController,
                                          onChanged: (_) => setState(() {}),
                                          validator: (value) =>
                                              value == null || value.trim().isEmpty
                                              ? 'Модели мошинро ворид кунед'
                                              : null,
                                          textInputAction: TextInputAction.next,
                                          textAlignVertical: TextAlignVertical.center,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF0F1B3D),
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            filled: false,
                                            fillColor: Colors.transparent,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 0,
                                                  vertical: 12,
                                                ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder: InputBorder.none,
                                          ),
                                      ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Рақами давлатӣ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7690),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _LicensePlateCard(
                              controller: _licensePlateController,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: _buildAnimatedSubmitButton(
                      allFilled && !_isLoading,
                    ),
                    ),
                  ],
              ),
            ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class DriverPhotoCollectionScreen extends StatefulWidget {
  final String driverName;
  final String driverPhone;
  final bool returnAfterSave;

  const DriverPhotoCollectionScreen({
    super.key,
    required this.driverName,
    required this.driverPhone,
    this.returnAfterSave = false,
  });

  @override
  State<DriverPhotoCollectionScreen> createState() =>
      _DriverPhotoCollectionScreenState();
}

class _DriverPhotoCollectionScreenState
    extends State<DriverPhotoCollectionScreen> {
  static const _photoLabels = ['Пеши мошин', 'Қафои мошин', 'Паҳлуи мошин'];
  final ImagePicker _imagePicker = ImagePicker();
  final List<String?> _photoPaths = List<String?>.filled(3, null);
  bool _isSaving = false;
  bool _isPickingColor = false;
  bool _continuePressed = false;

  static const _carColors = [
    'Сафед', 'Сиёҳ', 'Нуқрагӣ', 'Металлик',
    'Кабуд', 'Зард', 'Сабз', 'Сурх',
  ];

  Color _colorValue(String name) {
    switch (name) {
      case 'Сафед': return const Color(0xFFF5F5F5);
      case 'Сиёҳ': return const Color(0xFF141414);
      case 'Нуқрагӣ': return const Color(0xFFC0C4C8);
      case 'Металлик': return const Color(0xFF5A5F66);
      case 'Кабуд': return const Color(0xFF1E5AC8);
      case 'Зард': return const Color(0xFFF5C814);
      case 'Сабз': return const Color(0xFF1E9646);
      case 'Сурх': return const Color(0xFFC81E1E);
      default: return Colors.grey;
    }
  }

  ({Color color, double uniformity, List<double> rgb})? _samplePatch(
    img.Image image,
    int centerX,
    int centerY,
  ) {
    final startX = (centerX - 10).clamp(0, max(0, image.width - 21)).toInt();
    final startY = (centerY - 10).clamp(0, max(0, image.height - 21)).toInt();
    final endX = min(image.width, startX + 21);
    final endY = min(image.height, startY + 21);
    final pixels = <({double red, double green, double blue, double value, double saturation})>[];
    var hasBrightPixels = false;
    for (var y = startY; y < endY; y++) {
      for (var x = startX; x < endX; x++) {
        final pixel = image.getPixel(x, y);
        final red = pixel.rNormalized.toDouble();
        final green = pixel.gNormalized.toDouble();
        final blue = pixel.bNormalized.toDouble();
        final high = max(red, max(green, blue)).toDouble();
        final low = min(red, min(green, blue)).toDouble();
        final saturation = high == 0 ? 0.0 : (high - low) / high;
        pixels.add((red: red, green: green, blue: blue, value: high, saturation: saturation));
        if (high >= 0.70) hasBrightPixels = true;
      }
    }
    final usablePixels = pixels.where((pixel) {
      final specular = pixel.value > 0.97 && pixel.saturation < 0.08;
      final shadow = hasBrightPixels && pixel.value < 0.15;
      return !specular && !shadow;
    }).toList();
    if (usablePixels.isEmpty) return null;
    double medianChannel(List<double> values) {
      values.sort();
      final middle = values.length ~/ 2;
      return values.length.isOdd
          ? values[middle]
          : (values[middle - 1] + values[middle]) / 2;
    }
    final reds = usablePixels.map((pixel) => pixel.red).toList();
    final greens = usablePixels.map((pixel) => pixel.green).toList();
    final blues = usablePixels.map((pixel) => pixel.blue).toList();
    final red = medianChannel(reds);
    final green = medianChannel(greens);
    final blue = medianChannel(blues);
    double standardDeviation(List<double> values) {
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance = values
              .map((value) => (value - mean) * (value - mean))
              .reduce((a, b) => a + b) /
          values.length;
      return sqrt(variance) * 255;
    }

    final uniformity = max(
      standardDeviation(reds),
      max(standardDeviation(greens), standardDeviation(blues)),
    ).toDouble();
    return (
      color: Color.fromARGB(255, (red * 255).round(), (green * 255).round(), (blue * 255).round()),
      uniformity: uniformity,
      rgb: [red, green, blue],
    );
  }

  String _classifySample(List<double> rgb) {
    final red = rgb[0];
    final green = rgb[1];
    final blue = rgb[2];
    final high = max(red, max(green, blue)).toDouble();
    final low = min(red, min(green, blue)).toDouble();
    final delta = high - low;
    final saturation = high == 0 ? 0.0 : delta / high;
    var hue = 0.0;
    if (delta != 0) {
      if (high == red) {
        hue = 60 * (((green - blue) / delta) % 6);
      } else if (high == green) {
        hue = 60 * ((blue - red) / delta + 2);
      } else {
        hue = 60 * ((red - green) / delta + 4);
      }
      if (hue < 0) hue += 360;
    }
    if (high < 0.15) return 'Сиёҳ';
    if (saturation < 0.18) {
      final nearBoundary = (high - 0.80).abs() <= 0.03 ||
          (high - 0.55).abs() <= 0.03 ||
          (high - 0.22).abs() <= 0.03;
      if (!nearBoundary) {
        if (high >= 0.80) return 'Сафед';
        if (high >= 0.55) return 'Нуқрагӣ';
        if (high >= 0.22) return 'Металлик';
        return 'Сиёҳ';
      }
      List<double> lab(List<double> channels) {
        double linear(double channel) => channel <= 0.04045
            ? channel / 12.92
            : pow((channel + 0.055) / 1.055, 2.4).toDouble();
        final r = linear(channels[0]);
        final g = linear(channels[1]);
        final b = linear(channels[2]);
        final x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047;
        final y = r * 0.2126 + g * 0.7152 + b * 0.0722;
        final z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883;
        double pivot(double value) => value > 0.008856
            ? pow(value, 1 / 3).toDouble()
            : 7.787 * value + 16 / 116;
        final fx = pivot(x);
        final fy = pivot(y);
        final fz = pivot(z);
        return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
      }

      final sampleLab = lab(rgb);
      var closestName = 'Сиёҳ';
      var closestDistance = double.infinity;
      for (final name in const ['Сафед', 'Сиёҳ', 'Нуқрагӣ', 'Металлик']) {
        final display = _colorValue(name);
        final candidateLab = lab([
          display.red / 255,
          display.green / 255,
          display.blue / 255,
        ]);
        final distance = sqrt(
          pow(sampleLab[0] - candidateLab[0], 2) +
              pow(sampleLab[1] - candidateLab[1], 2) +
              pow(sampleLab[2] - candidateLab[2], 2),
        );
        if (distance < closestDistance) {
          closestDistance = distance;
          closestName = name;
        }
      }
      return closestName;
    }
    if (hue >= 345 || hue < 20 || (hue >= 310 && hue < 345)) return 'Сурх';
    if (hue < 70) return 'Зард';
    if (hue < 165) return 'Сабз';
    if (hue < 310) return 'Кабуд';
    return 'Кабуд';
  }

  Future<String?> _showCarColorPicker() async {
    final imageCache = List<img.Image?>.filled(3, null);
    final previewCache = List<Uint8List?>.filled(3, null);
    final loadingIndexes = <int>{};
    var selectedIndex = 2;
    img.Image? selectedImage;
    Uint8List? selectedPreview;
    Uint8List? loupePreview;
    bool loadingImage = true;
    String? selectedColor;
    String? sampledName;
    Color? sampledColor;
    double? sampledUniformity;
    Offset? marker;
    var initialLoadStarted = false;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> loadPhoto(int index) async {
            setSheetState(() {
              selectedIndex = index;
              selectedImage = imageCache[index];
              selectedPreview = previewCache[index];
              loadingImage = selectedImage == null;
              marker = null;
              loupePreview = null;
              sampledColor = null;
              sampledName = null;
              sampledUniformity = null;
              selectedColor = null;
            });
            if (imageCache[index] != null || !loadingIndexes.add(index)) return;
            final path = _photoPaths[index];
            if (path == null) {
              loadingIndexes.remove(index);
              if (selectedIndex == index) {
                setSheetState(() => loadingImage = false);
              }
              return;
            }
            Map<String, Object>? data;
            try {
              data = await compute(_decodeCarPickerImage, path);
            } catch (_) {
              loadingIndexes.remove(index);
              if (!mounted || !sheetContext.mounted) return;
              if (selectedIndex == index) {
                setSheetState(() => loadingImage = false);
              }
              return;
            }
            loadingIndexes.remove(index);
            if (!mounted || !sheetContext.mounted) return;
            if (data == null) {
              if (selectedIndex == index) {
                setSheetState(() => loadingImage = false);
              }
              return;
            }
            try {
              final imageBytes = data['rgb'] as Uint8List;
              final image = img.Image.fromBytes(
                width: data['width'] as int,
                height: data['height'] as int,
                bytes: imageBytes.buffer,
                numChannels: 3,
                order: img.ChannelOrder.rgb,
              );
              imageCache[index] = image;
              previewCache[index] = data['preview'] as Uint8List;
              if (selectedIndex != index) return;
              setSheetState(() {
                selectedImage = image;
                selectedPreview = previewCache[index];
                loadingImage = false;
              });
            } catch (_) {
              if (selectedIndex == index) {
                setSheetState(() => loadingImage = false);
              }
            }
          }

          void sampleAt(Offset point, Size size) {
            final image = selectedImage;
            if (image == null || size.isEmpty) return;
            final scale = min(size.width / image.width, size.height / image.height);
            final drawnWidth = image.width * scale;
            final drawnHeight = image.height * scale;
            final imageLeft = (size.width - drawnWidth) / 2;
            final imageTop = (size.height - drawnHeight) / 2;
            if (point.dx < imageLeft || point.dx > imageLeft + drawnWidth ||
                point.dy < imageTop || point.dy > imageTop + drawnHeight) {
              return;
            }
            final imageX = ((point.dx - imageLeft) / scale)
                .floor()
                .clamp(0, image.width - 1)
                .toInt();
            final imageY = ((point.dy - imageTop) / scale)
                .floor()
                .clamp(0, image.height - 1)
                .toInt();
            final sample = _samplePatch(image, imageX, imageY);
            if (sample == null) return;
            final colorName = _classifySample(sample.rgb);
            final red = sample.rgb[0];
            final green = sample.rgb[1];
            final blue = sample.rgb[2];
            final high = max(red, max(green, blue)).toDouble();
            final low = min(red, min(green, blue)).toDouble();
            final delta = high - low;
            var hue = 0.0;
            if (delta != 0) {
              if (high == red) {
                hue = 60 * (((green - blue) / delta) % 6);
              } else if (high == green) {
                hue = 60 * ((blue - red) / delta + 2);
              } else {
                hue = 60 * ((red - green) / delta + 4);
              }
              if (hue < 0) hue += 360;
            }
            final saturation = high == 0 ? 0.0 : delta / high;
            final value = high;
            final cropX = (imageX - 10).clamp(0, image.width - 1).toInt();
            final cropY = (imageY - 10).clamp(0, image.height - 1).toInt();
            final cropWidth = min(21, image.width - cropX);
            final cropHeight = min(21, image.height - cropY);
            final crop = img.copyCrop(
              image,
              x: cropX,
              y: cropY,
              width: cropWidth,
              height: cropHeight,
            );
            final loupe = img.copyResize(crop, width: 84, height: 84);
            setSheetState(() {
              marker = point;
              sampledColor = sample.color;
              sampledName = colorName;
              sampledUniformity = sample.uniformity;
              loupePreview = Uint8List.fromList(img.encodePng(loupe));
              selectedColor = colorName;
            });
            // TEMP DEBUG
            if (kDebugMode) {
              debugPrint(
                'TEMP DEBUG color sample: RGB='
                '${sample.rgb.map((channel) => (channel * 255).round()).toList()}, '
                'HSV=(${hue.toStringAsFixed(1)}, ${saturation.toStringAsFixed(3)}, ${value.toStringAsFixed(3)}), '
                'std=${sample.uniformity.toStringAsFixed(2)}, result=$colorName',
              );
            }
          }

          if (!initialLoadStarted) {
            initialLoadStarted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (sheetContext.mounted) unawaited(loadPhoto(2));
            });
          }

          return SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Ба ҷисми мошин ангушт монед',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10264F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Қисми ҳамвори дарро интихоб кунед, на шиша ва на инъикосро',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7690)),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: SizedBox(
                          height: 300,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final canvasSize = Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              );
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (details) =>
                                    sampleAt(details.localPosition, canvasSize),
                                onPanStart: (details) =>
                                    sampleAt(details.localPosition, canvasSize),
                                onPanUpdate: (details) =>
                                    sampleAt(details.localPosition, canvasSize),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: loadingImage
                                          ? const Center(
                                              child: CircularProgressIndicator(),
                                            )
                                          : selectedPreview == null
                                              ? const Center(
                                                  child: Icon(
                                                    Icons.broken_image_outlined,
                                                    size: 54,
                                                    color: Color(0xFF91A4C3),
                                                  ),
                                                )
                                              : Image.memory(
                                                  selectedPreview!,
                                                  fit: BoxFit.contain,
                                                ),
                                    ),
                                    if (marker != null && sampledColor != null) ...[
                                      Positioned(
                                        left: marker!.dx - 16,
                                        top: marker!.dy - 16,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.black.withValues(alpha: 0.38),
                                              width: 5,
                                            ),
                                          ),
                                          child: Container(
                                            margin: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (loupePreview != null)
                                        Positioned(
                                          left: (marker!.dx - 36)
                                              .clamp(0, max(0, canvasSize.width - 72))
                                              .toDouble(),
                                          top: max(0, marker!.dy - 100).toDouble(),
                                          child: Container(
                                            width: 72,
                                            height: 72,
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.16),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child: Image.memory(
                                                loupePreview!,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF0FE),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: List<Widget>.generate(3, (index) {
                          const labels = ['Пеш', 'Қафо', 'Паҳлу'];
                          final selected = selectedIndex == index;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                unawaited(HapticFeedback.selectionClick());
                                unawaited(loadPhoto(index));
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF0066FF)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    labels[index],
                                    style: TextStyle(
                                      color: selected ? Colors.white : const Color(0xFF53627A),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: selectedColor == null
                                  ? Colors.white
                                  : sampledName == selectedColor && sampledColor != null
                                      ? sampledColor!
                                      : _colorValue(selectedColor!),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ранги мошин',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7690),
                                  ),
                                ),
                                Text(
                                  selectedColor ?? '—',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10264F),
                                  ),
                                ),
                                if (sampledName == selectedColor &&
                                    sampledUniformity != null &&
                                    sampledUniformity! > 35)
                                  const Text(
                                    'Ҷои ҳамвортарро интихоб кунед',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF8994A6),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 14,
                      runSpacing: 14,
                      children: _carColors.map((color) {
                        final selected = selectedColor == color;
                        return SizedBox(
                          width: 66,
                          child: GestureDetector(
                            onTap: () {
                              unawaited(HapticFeedback.selectionClick());
                              setSheetState(() => selectedColor = color);
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: selected
                                        ? Border.all(
                                            color: const Color(0xFF0066FF),
                                            width: 3,
                                          )
                                        : null,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _colorValue(color),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                            width: selected ? 0.5 : 0.75,
                                          ),
                                        ),
                                      ),
                                      if (selected)
                                        const Icon(
                                          Icons.check_rounded,
                                          size: 20,
                                          color: Color(0xFF0066FF),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  color,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7690),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: selectedColor == null
                            ? null
                            : () => Navigator.pop(sheetContext, selectedColor),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          disabledBackgroundColor: const Color(0xFFD7DEE9),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Тасдиқ кардан',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  Future<void> _takePhoto(int index) async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Камера'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Галерея'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (!mounted || source == null) return;
      final photo = await _imagePicker.pickImage(source: source);
      if (!mounted || photo == null) return;
      setState(() => _photoPaths[index] = photo.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Кушодани камера муяссар нашуд')),
      );
    }
  }

  Future<void> _continue() async {
    if (_photoPaths.any((path) => path == null) || _isSaving) return;
    setState(() {
      _isSaving = true;
      _isPickingColor = true;
    });
    try {
      final confirmedColor = await _showCarColorPicker();
      if (!mounted) return;
      setState(() => _isPickingColor = false);
      if (confirmedColor == null) {
        setState(() => _isSaving = false);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final documentsDirectory = await getApplicationDocumentsDirectory();
      if (!mounted) return;
      final carPhotosDirectory = Directory('${documentsDirectory.path}${Platform.pathSeparator}car_photos');
      await carPhotosDirectory.create(recursive: true);
      if (!mounted) return;
      const fileNames = ['front.jpg', 'rear.jpg', 'side.jpg'];
      for (var index = 0; index < _photoPaths.length; index++) {
        final permanentFile = File('${carPhotosDirectory.path}${Platform.pathSeparator}${fileNames[index]}');
        await File(_photoPaths[index]!).copy(permanentFile.path);
        if (!mounted) return;
        await prefs.setString('driver_car_photo_${index + 1}', permanentFile.path);
        if (!mounted) return;
      }
      await prefs.setString('driver_car_color', confirmedColor);
      if (!mounted) return;
      if (widget.returnAfterSave) {
        Navigator.pop(context);
        return;
      }
      AppRoute.replace<void, void>(
        context,
        DriverHomeScreen(
          driverName: widget.driverName,
          driverPhone: widget.driverPhone,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isPickingColor = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нигоҳдории аксҳо муяссар нашуд')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allPhotosTaken = _photoPaths.every((path) => path != null);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FBFF), Color(0xFFEAF4FF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -105,
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCEBFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -125,
              left: -125,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCEBFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardGap = constraints.maxHeight < 680 ? 5.0 : 8.0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Лутфан мошинро аз 3 тараф аксбардорӣ кунед',
                          style: TextStyle(
                            fontSize: 22,
                            height: 1.12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F1B3D),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Expanded(
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < _photoLabels.length;
                                index++
                              ) ...[
                                Expanded(child: _buildPhotoCard(index)),
                                if (index < _photoLabels.length - 1)
                                  SizedBox(height: cardGap),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 7),
                        _buildAnimatedContinueButton(
                          allPhotosTaken && !_isSaving,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedContinueButton(bool enabled) => Listener(
    onPointerDown: enabled
        ? (_) => setState(() => _continuePressed = true)
        : null,
    onPointerUp: enabled
        ? (_) => setState(() => _continuePressed = false)
        : null,
    onPointerCancel: enabled
        ? (_) => setState(() => _continuePressed = false)
        : null,
    child: AnimatedScale(
      scale: _continuePressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      child: AppButton(
        text: _isPickingColor
            ? 'Интихоби ранги мошин...'
            : 'Идома додан',
        enabled: enabled,
        onPressed: _continue,
      ),
    ),
  );

  Widget _buildPhotoCard(int index) {
    final path = _photoPaths[index];
    return InkWell(
      onTap: () => _takePhoto(index),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1C6A9DD9),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -68,
              right: -12,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -68,
              left: -66,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F7FF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF42B5FF), Color(0xFF1674F5)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _photoLabels[index],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10264F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: path == null ? 5 : 7,
                          child: path == null
                              ? Image.asset(
                                  'assets/position${index + 1}.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.directions_car_filled_rounded,
                                    size: 76,
                                    color: Color(0xFFB8C2D1),
                                  ),
                                )
                              : SizedBox.expand(
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: ColoredBox(
                                            color: Colors.white,
                                            child: Image.file(
                                              File(path),
                                              fit: BoxFit.contain,
                                              alignment: Alignment.center,
                                              errorBuilder: (_, __, ___) =>
                                                  const Center(
                                                    child: Icon(
                                                      Icons.broken_image_outlined,
                                                      color: Colors.black38,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Color(0xFF16A34A),
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: path == null ? 6 : 4,
                          child: InkWell(
                            onTap: () => _takePhoto(index),
                            borderRadius: BorderRadius.circular(40),
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(horizontal: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F7FF),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFDDEEFF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      path == null
                                          ? Icons.photo_camera_outlined
                                          : Icons.refresh_rounded,
                                      size: 19,
                                      color: const Color(0xFF0878FF),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      path == null
                                          ? 'Акс'
                                          : 'Дубора',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0878FF),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: Color(0xFF91A4C3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final String brand;
  const _BrandMark({required this.brand});

  @override
  Widget build(BuildContext context) {
    final path = carBrandLogoAsset(brand);
    if (path == null) return const _GenericCarIcon();
    final image = path.toLowerCase().endsWith('.svg')
        ? SvgPicture.asset(
            path,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => const _GenericCarIcon(),
            errorBuilder: (_, __, ___) => const _GenericCarIcon(),
          )
        : Image.asset(
            path,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const _GenericCarIcon(),
          );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: KeyedSubtree(key: ValueKey(brand), child: image),
    );
  }
}

class _GenericCarIcon extends StatelessWidget {
  const _GenericCarIcon();
  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(24, 24), painter: _CarOutlinePainter());
}

class _CarOutlinePainter extends CustomPainter {
  const _CarOutlinePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(3, 14)
      ..lineTo(4.2, 10.5)
      ..quadraticBezierTo(4.6, 9.2, 6, 9.2)
      ..lineTo(8.2, 5.8)
      ..quadraticBezierTo(8.6, 5.2, 9.4, 5.2)
      ..lineTo(15.3, 5.2)
      ..quadraticBezierTo(16.1, 5.2, 16.6, 5.9)
      ..lineTo(19, 9.2)
      ..lineTo(20.1, 9.7)
      ..quadraticBezierTo(21, 10.1, 21, 11.2)
      ..lineTo(21, 15)
      ..quadraticBezierTo(21, 16, 20, 16)
      ..lineTo(18, 16);
    canvas.drawPath(path, p);
    final lower = Path()
      ..moveTo(6.2, 16)
      ..lineTo(3.8, 16)
      ..quadraticBezierTo(3, 16, 3, 15)
      ..lineTo(3, 14);
    canvas.drawPath(lower, p);
    canvas.drawLine(const Offset(7, 9.2), const Offset(17.8, 9.2), p);
    canvas.drawCircle(const Offset(7.2, 16), 2, p);
    canvas.drawCircle(const Offset(15.8, 16), 2, p);
  }

  @override
  bool shouldRepaint(covariant _CarOutlinePainter oldDelegate) => false;
}

class _LicensePlateCard extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _LicensePlateCard({required this.controller, required this.onChanged});

  @override
  State<_LicensePlateCard> createState() => _LicensePlateCardState();
}

class _LicensePlateCardState extends State<_LicensePlateCard> {
  final FocusNode _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_refresh);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    padding: EdgeInsets.zero,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: _focus.hasFocus ? const Color(0xFF2563EB) : Colors.transparent,
        width: _focus.hasFocus ? 2 : 0,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x100F1B3D),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, box) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 2131 / 410,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/tojik_plate.png', fit: BoxFit.contain),
              Positioned(
                left: box.maxWidth * .21,
                right: box.maxWidth * .03,
                top: 0,
                bottom: 0,
                child: Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      controller: widget.controller,
                      focusNode: _focus,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      maxLength: 8,
                      maxLines: 1,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(
                        color: const Color(0xFF111111),
                        fontWeight: FontWeight.w800,
                        fontSize: box.maxWidth * .11,
                        letterSpacing: 2,
                        height: 1,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '0000AA00',
                        hintStyle: TextStyle(color: Color(0x55111111)),
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp('[A-Za-z0-9]'),
                        ),
                        _PlateFormat(),
                      ],
                      onChanged: widget.onChanged,
                      validator: (value) =>
                          value != null &&
                              RegExp(r'^\d{4}[A-Z]{2}\d{2}$').hasMatch(value)
                          ? null
                          : 'Формат: 0000AA00',
                    ),
                  ),
                ),
              ),
            ],
                        ),
                      ),
      ),
      ),
    );
  }

class _PlateFormat extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var out = newValue.text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    final chars = <String>[];
    for (var i = 0; i < out.length && chars.length < 8; i++) {
      final c = out[i];
      if (chars.length < 4
          ? RegExp('[0-9]').hasMatch(c)
          : chars.length < 6
          ? RegExp('[A-Z]').hasMatch(c)
          : RegExp('[0-9]').hasMatch(c))
        chars.add(c);
    }
    out = chars.join();
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _PickerSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    height: MediaQuery.sizeOf(context).height * .82,
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFC7CEDB),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Semantics(label: title, child: const SizedBox.shrink()),
        Expanded(child: child),
      ],
    ),
  );
}

class AppField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final String? value;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final bool isPicker;
  final TextInputAction? action;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool showIcon;
  final bool showChevron;
  final String? logoBrand;

  const AppField({
    super.key,
    required this.hint,
    required this.icon,
    this.value,
    this.onTap,
    this.controller,
    this.isPicker = false,
    this.action,
    this.capitalization = TextCapitalization.none,
    this.onChanged,
    this.validator,
    this.inputFormatters = const [],
    this.showIcon = true,
    this.showChevron = false,
    this.logoBrand,
  });

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  final FocusNode _focus = FocusNode();
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
    widget.controller?.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant AppField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_refresh);
      widget.controller?.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_refresh);
    _focus.removeListener(_refresh);
    _focus.dispose();
    super.dispose();
  }

  bool get _filled => widget.isPicker
      ? (widget.value?.isNotEmpty ?? false)
      : (widget.controller?.text.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);
    final active = _focus.hasFocus || _pressed;
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.97),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? blue : const Color(0xFFDCE6F5),
            width: 1,
          ),
          boxShadow: active
              ? [BoxShadow(color: blue.withOpacity(.15), blurRadius: 12)]
              : const [],
        ),
        child: Row(
          children: [
            if (widget.showIcon)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: widget.logoBrand == null
                    ? const SizedBox.shrink()
                    : carBrandLogoAsset(widget.logoBrand!) == null
                    ? const _GenericCarIcon()
                    : Padding(
                        padding: const EdgeInsets.all(4),
                        child: _BrandMark(brand: widget.logoBrand!),
                      ),
              ),
            if (widget.showIcon) const SizedBox(width: 12),
            Expanded(
              child: widget.isPicker
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onTap,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_filled && widget.hint.isNotEmpty)
                            Text(
                              widget.hint,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.value ?? widget.hint,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _filled
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: _filled
                                    ? const Color(0xFF0F1B3D)
                                    : const Color(0xFF9AA3B5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_filled || active)
                          Text(
                            widget.hint,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        SizedBox(
                          height: 22,
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              if (!_filled && !active)
                                Text(
                                  widget.hint,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF9AA3B5),
                                  ),
                                ),
                              Positioned.fill(
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    inputDecorationTheme:
                                        const InputDecorationTheme(),
                                  ),
                                  child: TextFormField(
                                    controller: widget.controller,
                                    focusNode: _focus,
                                    validator: widget.validator,
                                    inputFormatters: widget.inputFormatters,
                                    textInputAction: widget.action,
                                    textCapitalization: widget.capitalization,
                                    onChanged: widget.onChanged,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0F1B3D),
                                    ),
                                    decoration: const InputDecoration(
                                      isCollapsed: true,
                                      filled: false,
                                      fillColor: Colors.transparent,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            if (widget.isPicker || widget.showChevron)
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF9AA3B5),
              ),
          ],
        ),
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final VoidCallback onPressed;
  const AppButton({
    super.key,
    required this.text,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onPressed : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 56,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF2563EB) : const Color(0xFFC7CEDB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
