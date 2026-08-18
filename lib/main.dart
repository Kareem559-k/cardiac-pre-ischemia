import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionStore.instance.init();
  runApp(const CardiacApp());
}

String _apiBaseUrl() {
  const envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (envBaseUrl.isNotEmpty) return envBaseUrl;
  if (kIsWeb) return Uri.base.origin;
  if (Platform.isAndroid) return 'http://10.0.2.2:8001';
  return 'http://127.0.0.1:8001';
}

class AppColors {
  static const primary = Color(0xFF0B1F33);
  static const primaryDark = Color(0xFF07131F);
  static const secondary = Color(0xFF123E63);
  static const accent = Color(0xFF36C6FF);
  static const accentSoft = Color(0xFFE6F8FF);
  static const accentDeep = Color(0xFF1994C7);
  static const info = Color(0xFF6FE7FF);
  static const success = Color(0xFF33D69F);
  static const danger = Color(0xFFFF6B81);
  static const warning = Color(0xFFFFC66D);
  static const background = Color(0xFFF3F7FB);
  static const ink = Color(0xFF091722);
  static const textSecondary = Color(0xFF607387);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF7FBFF);
  static const surfaceDark = Color(0xFF0E1824);
  static const backgroundDark = Color(0xFF040B14);
  static const border = Color(0xFFD8E5EF);
  static const borderDark = Color(0xFF1D3145);
  static const glass = Color(0xCCFFFFFF);
  static const glassDark = Color(0xA6111E2C);
}

class AppRadii {
  static const double xl = 20;
  static const double lg = 16;
  static const double md = 12;
  static const double sm = 8;
}

class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withAlpha(14),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> lift = [
    BoxShadow(
      color: Colors.black.withAlpha(24),
      blurRadius: 34,
      offset: const Offset(0, 20),
    ),
  ];
}

class AppGradients {
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF07131F), Color(0xFF123E63), Color(0xFF36C6FF)],
  );

  static const LinearGradient lightHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF4F9FD), Color(0xFFE9F3FB), Color(0xFFD8ECF8)],
  );

  static const LinearGradient accentGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x6636C6FF), Color(0x19FFFFFF)],
  );

  static const LinearGradient darkBackdrop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF06111B), Color(0xFF091927), Color(0xFF040A12)],
  );
}

class AppTheme {
  static ThemeData light({required bool isArabic}) {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accentDeep,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
    );
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    final baseTextTheme = isArabic
        ? GoogleFonts.cairoTextTheme(base.textTheme)
        : GoogleFonts.manropeTextTheme(base.textTheme);
    final textTheme = baseTextTheme
        .apply(bodyColor: AppColors.primary, displayColor: AppColors.primary)
        .copyWith(
          bodyLarge: isArabic
              ? GoogleFonts.cairo(fontSize: 14, height: 1.45)
              : GoogleFonts.manrope(fontSize: 14, height: 1.45),
          bodyMedium: isArabic
              ? GoogleFonts.cairo(fontSize: 12, height: 1.4)
              : GoogleFonts.manrope(fontSize: 12, height: 1.4),
          bodySmall: isArabic
              ? GoogleFonts.cairo(fontSize: 11, height: 1.35)
              : GoogleFonts.manrope(fontSize: 11, height: 1.35),
          headlineMedium: isArabic
              ? GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w700)
              : GoogleFonts.sora(fontSize: 28, fontWeight: FontWeight.w700),
          titleLarge: isArabic
              ? GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w700)
              : GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700),
          titleMedium: isArabic
              ? GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600)
              : GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall: isArabic
              ? GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600)
              : GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600),
          labelLarge: isArabic
              ? GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)
              : GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
        );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primary),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.primary, size: 20),
      cardTheme: CardThemeData(
        color: AppColors.surface.withAlpha(222),
        elevation: 0,
        surfaceTintColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.border.withAlpha(220)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 2,
          minimumSize: const Size(64, 52),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentDeep,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 20,
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        iconColor: AppColors.primary,
        textColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.accentSoft,
        labelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.accentSoft,
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: Colors.grey);
        }),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface.withAlpha(224),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        labelStyle: const TextStyle(color: AppColors.primary),
        floatingLabelStyle: const TextStyle(color: AppColors.accent),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.primary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
    );
  }

  static ThemeData dark({required bool isArabic}) {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.info,
      onPrimary: AppColors.primaryDark,
      secondary: AppColors.accent,
      onSecondary: AppColors.primaryDark,
      error: AppColors.danger,
      onError: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: Colors.white,
    );
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
    final baseTextTheme = isArabic
        ? GoogleFonts.cairoTextTheme(base.textTheme)
        : GoogleFonts.manropeTextTheme(base.textTheme);
    final textTheme = baseTextTheme
        .apply(bodyColor: Colors.white, displayColor: Colors.white)
        .copyWith(
          headlineMedium: isArabic
              ? GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w700)
              : GoogleFonts.sora(fontSize: 28, fontWeight: FontWeight.w700),
          titleLarge: isArabic
              ? GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w700)
              : GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700),
          titleMedium: isArabic
              ? GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600)
              : GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600),
          labelLarge: isArabic
              ? GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)
              : GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700),
        );
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white, size: 20),
      cardTheme: CardThemeData(
        color: AppColors.glassDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.info,
          foregroundColor: AppColors.primaryDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.borderDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        labelStyle: const TextStyle(color: AppColors.primary),
        floatingLabelStyle: const TextStyle(color: AppColors.info),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.primary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.info, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.white12,
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.borderDark, thickness: 1),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: AppColors.primary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class AppHeroBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;

  const AppHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.lift,
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppDoctor {
  final int id;
  final String name;
  final String specialty;
  final String clinic;
  final String phone;
  final String email;
  final String about;

  AppDoctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.clinic,
    required this.phone,
    required this.email,
    required this.about,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'clinic': clinic,
      'phone': phone,
      'email': email,
      'about': about,
    };
  }

  factory AppDoctor.fromJson(Map<String, dynamic> json) {
    return AppDoctor(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      clinic: json['clinic'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      about: json['about'] as String? ?? '',
    );
  }
}

class SessionSnapshot {
  final String token;
  final String role;
  final String username;
  final String workspace;
  final AppDoctor? currentDoctor;
  final AppDoctor? selectedDoctor;

  const SessionSnapshot({
    required this.token,
    required this.role,
    required this.username,
    required this.workspace,
    this.currentDoctor,
    this.selectedDoctor,
  });
}

class SessionStore {
  SessionStore._();
  static final SessionStore instance = SessionStore._();

  static const _tokenKey = 'session_token';
  static const _roleKey = 'session_role';
  static const _usernameKey = 'session_username';
  static const _workspaceKey = 'session_workspace';
  static const _currentDoctorKey = 'session_current_doctor';
  static const _selectedDoctorKey = 'session_selected_doctor';
  static const _isArabicKey = 'pref_is_arabic';
  static const _isDarkModeKey = 'pref_is_dark';
  static const _developerModeKey = 'pref_dev_mode';
  static const _apiBaseUrlKey = 'pref_api_base_url';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveSettings({
    required bool isArabic,
    required bool isDarkMode,
    required bool developerMode,
    required String apiBaseUrl,
  }) async {
    await _prefs.setBool(_isArabicKey, isArabic);
    await _prefs.setBool(_isDarkModeKey, isDarkMode);
    await _prefs.setBool(_developerModeKey, developerMode);
    await _prefs.setString(_apiBaseUrlKey, apiBaseUrl);
  }

  void restoreSettings() {
    AppState.isArabic.value = _prefs.getBool(_isArabicKey) ?? false;
    AppState.isDarkMode.value = _prefs.getBool(_isDarkModeKey) ?? false;
    AppState.developerMode.value = _prefs.getBool(_developerModeKey) ?? false;
    final savedUrl = _prefs.getString(_apiBaseUrlKey);
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      AppState.apiBaseUrl.value = savedUrl.trim();
    }
  }

  Future<void> saveSession({
    required String token,
    required String role,
    required String username,
    required String workspace,
    AppDoctor? currentDoctor,
    AppDoctor? selectedDoctor,
  }) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_roleKey, role);
    await _prefs.setString(_usernameKey, username);
    await _prefs.setString(_workspaceKey, workspace);
    if (currentDoctor != null) {
      await _prefs.setString(
          _currentDoctorKey, jsonEncode(currentDoctor.toJson()));
    } else {
      await _prefs.remove(_currentDoctorKey);
    }
    if (selectedDoctor != null) {
      await _prefs.setString(
          _selectedDoctorKey, jsonEncode(selectedDoctor.toJson()));
    } else {
      await _prefs.remove(_selectedDoctorKey);
    }
  }

  SessionSnapshot? restoreSession() {
    final token = _prefs.getString(_tokenKey);
    final role = _prefs.getString(_roleKey);
    final username = _prefs.getString(_usernameKey);
    final workspace = _prefs.getString(_workspaceKey);
    if (token == null ||
        role == null ||
        username == null ||
        workspace == null) {
      return null;
    }
    AppDoctor? parseDoctor(String key) {
      final raw = _prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) return null;
      try {
        return AppDoctor.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }

    return SessionSnapshot(
      token: token,
      role: role,
      username: username,
      workspace: workspace,
      currentDoctor: parseDoctor(_currentDoctorKey),
      selectedDoctor: parseDoctor(_selectedDoctorKey),
    );
  }

  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_roleKey);
    await _prefs.remove(_usernameKey);
    await _prefs.remove(_workspaceKey);
    await _prefs.remove(_currentDoctorKey);
    await _prefs.remove(_selectedDoctorKey);
  }
}

class AppState {
  static int _nextDoctorId = 4;
  static AppDoctor? currentDoctorProfile;
  static AppDoctor? selectedDoctor;
  static String currentWorkspace = 'guest';
  static final ValueNotifier<bool> isArabic = ValueNotifier(false);
  static final ValueNotifier<bool> isDarkMode = ValueNotifier(false);
  static final ValueNotifier<bool> developerMode = ValueNotifier(false);
  static final ValueNotifier<String> apiBaseUrl = ValueNotifier(_apiBaseUrl());
  static const String projectName = 'Cardiac Pre-Ischemia';
  static const String projectTagline =
      'AI-assisted ischemia screening and wearable ECG monitoring';

  static final List<AppDoctor> doctors = [];

  static void upsertDoctor(AppDoctor doctor) {
    final idx = doctors.indexWhere((d) => d.email == doctor.email);
    if (idx == -1) {
      doctors.add(doctor);
    } else {
      doctors[idx] = doctor;
    }
    if (doctor.id >= _nextDoctorId) {
      _nextDoctorId = doctor.id + 1;
    }
  }

  static AppDoctor createDoctor({
    required String name,
    required String specialty,
    required String clinic,
    required String phone,
    required String email,
    required String about,
  }) {
    final doctor = AppDoctor(
      id: _nextDoctorId++,
      name: name,
      specialty: specialty,
      clinic: clinic,
      phone: phone,
      email: email,
      about: about,
    );
    upsertDoctor(doctor);
    currentDoctorProfile = doctor;
    unawaited(persistSession());
    return doctor;
  }

  static Future<void> persistSettings() {
    return SessionStore.instance.saveSettings(
      isArabic: isArabic.value,
      isDarkMode: isDarkMode.value,
      developerMode: developerMode.value,
      apiBaseUrl: apiBaseUrl.value,
    );
  }

  static Future<void> persistSession({
    String? token,
    String? role,
    String? username,
    String? workspace,
  }) async {
    final activeToken = token ?? ApiService.currentToken;
    final activeRole = role ?? ApiService.currentRole;
    final activeUsername = username ?? ApiService.currentUsername;
    final activeWorkspace = workspace ?? currentWorkspace;
    if (activeToken == null ||
        activeRole == null ||
        activeUsername == null ||
        activeWorkspace.trim().isEmpty) {
      return;
    }
    await SessionStore.instance.saveSession(
      token: activeToken,
      role: activeRole,
      username: activeUsername,
      workspace: activeWorkspace,
      currentDoctor: currentDoctorProfile,
      selectedDoctor: selectedDoctor,
    );
  }

  static void restoreDoctorContext({
    AppDoctor? currentDoctor,
    AppDoctor? selectedDoctorValue,
  }) {
    if (currentDoctor != null) {
      upsertDoctor(currentDoctor);
      currentDoctorProfile = currentDoctor;
    }
    if (selectedDoctorValue != null) {
      upsertDoctor(selectedDoctorValue);
      selectedDoctor = selectedDoctorValue;
    }
  }

  static Future<void> clearSessionState() async {
    currentDoctorProfile = null;
    selectedDoctor = null;
    currentWorkspace = 'guest';
    await SessionStore.instance.clearSession();
  }
}

String _authIdentityToEmail(String rawMobile) {
  final cleaned = rawMobile.replaceAll(RegExp(r'[^0-9+]'), '');
  final safe = cleaned.isEmpty ? 'user' : cleaned.replaceAll('+', 'plus');
  return '$safe@cardiac-preischemia.app';
}

String _friendlyApiError(Object error) {
  final text = error.toString();
  if (text.contains('401')) {
    return _t('Invalid mobile number or password.',
        'رقم الهاتف أو كلمة المرور غير صحيحين.');
  }
  if (text.contains('409')) {
    return _t(
        'This mobile number is already registered.', 'رقم الهاتف مسجل بالفعل.');
  }
  if (text.contains('Network error')) {
    return _t('Network connection failed. Check Wi-Fi and server status.',
        'فشل الاتصال بالشبكة. تأكد من الواي فاي وحالة الخادم.');
  }
  if (text.contains('timed out')) {
    return _t('The request timed out. Please try again.',
        'انتهت مهلة الطلب. حاول مرة أخرى.');
  }
  return _t('Unable to complete the request right now. Please try again.',
      'تعذر إكمال الطلب الآن. حاول مرة أخرى.');
}

class AnalysisSessionDraft {
  final String patientName;
  final String patientAge;
  final String patientSex;
  final String doctorName;
  final String notes;
  final String analysisSource;

  const AnalysisSessionDraft({
    required this.patientName,
    required this.patientAge,
    required this.patientSex,
    required this.doctorName,
    required this.notes,
    required this.analysisSource,
  });

  bool get hasPatientIdentity => patientName.trim().isNotEmpty;

  String get patientIdentityLabel {
    final age = patientAge.trim().isEmpty ? '-' : patientAge.trim();
    final sex = patientSex.trim().isEmpty ? '-' : patientSex.trim();
    return '$patientName â€¢ Age: $age â€¢ Sex: $sex';
  }
}

class ReportLibraryEntry {
  final PatientModel patient;
  final ReportModel report;
  final String latestRisk;
  final String latestBpm;
  final String latestLabel;
  final String latestDate;

  const ReportLibraryEntry({
    required this.patient,
    required this.report,
    required this.latestRisk,
    required this.latestBpm,
    required this.latestLabel,
    required this.latestDate,
  });
}

class DoctorHomeSnapshot {
  final StatsModel stats;
  final List<PatientModel> patients;
  final List<AppointmentModel> appointments;
  final List<ReportLibraryEntry> reports;
  final bool onboardingComplete;

  const DoctorHomeSnapshot({
    required this.stats,
    required this.patients,
    required this.appointments,
    required this.reports,
    required this.onboardingComplete,
  });
}

class PatientHistorySnapshot {
  final PatientModel? patient;
  final ReportModel? report;
  final List<AppointmentModel> appointments;

  const PatientHistorySnapshot({
    required this.patient,
    required this.report,
    required this.appointments,
  });
}

class PipelineStage {
  final String title;
  final String subtitle;
  final bool done;
  final bool active;

  const PipelineStage({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.active,
  });
}

class AiInsightBundle {
  final String triage;
  final Color triageColor;
  final String clinicianSummary;
  final String patientSummary;
  final String qualitySummary;
  final String confidenceSummary;
  final List<String> watchItems;
  final List<String> nextSteps;

  const AiInsightBundle({
    required this.triage,
    required this.triageColor,
    required this.clinicianSummary,
    required this.patientSummary,
    required this.qualitySummary,
    required this.confidenceSummary,
    required this.watchItems,
    required this.nextSteps,
  });
}

class AiTrendComparison {
  final String headline;
  final Color color;
  final String summary;
  final String bpmDeltaLabel;
  final String riskShiftLabel;
  final List<String> bullets;

  const AiTrendComparison({
    required this.headline,
    required this.color,
    required this.summary,
    required this.bpmDeltaLabel,
    required this.riskShiftLabel,
    required this.bullets,
  });
}

class DoctorCopilotBrief {
  final String headline;
  final String summary;
  final Color color;
  final List<String> priorities;

  const DoctorCopilotBrief({
    required this.headline,
    required this.summary,
    required this.color,
    required this.priorities,
  });
}

class ChatAiGuide {
  final String headline;
  final String summary;
  final String statusLabel;
  final Color color;
  final List<String> suggestions;

  const ChatAiGuide({
    required this.headline,
    required this.summary,
    required this.statusLabel,
    required this.color,
    required this.suggestions,
  });
}

class LiveMonitoringAiBrief {
  final String headline;
  final String summary;
  final String urgencyLabel;
  final String signalLabel;
  final String recommendedAction;
  final Color color;
  final List<String> bullets;

  const LiveMonitoringAiBrief({
    required this.headline,
    required this.summary,
    required this.urgencyLabel,
    required this.signalLabel,
    required this.recommendedAction,
    required this.color,
    required this.bullets,
  });
}

class MessagingOpsBrief {
  final String headline;
  final String summary;
  final String queueLabel;
  final String responseLabel;
  final Color color;
  final List<String> bullets;

  const MessagingOpsBrief({
    required this.headline,
    required this.summary,
    required this.queueLabel,
    required this.responseLabel,
    required this.color,
    required this.bullets,
  });
}

class PatientAiCompanionBrief {
  final String headline;
  final String summary;
  final String readinessLabel;
  final String doctorStateLabel;
  final Color color;
  final List<String> bullets;

  const PatientAiCompanionBrief({
    required this.headline,
    required this.summary,
    required this.readinessLabel,
    required this.doctorStateLabel,
    required this.color,
    required this.bullets,
  });
}

class LiveAlertEvent {
  final String timeLabel;
  final String title;
  final String detail;
  final Color color;

  const LiveAlertEvent({
    required this.timeLabel,
    required this.title,
    required this.detail,
    required this.color,
  });
}

String _safeDateLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'No date';
  final cleaned = raw.trim();
  if (cleaned.contains('T')) {
    return cleaned.split('T').first;
  }
  return cleaned;
}

String _safeTimeLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '--:--';
  final cleaned = raw.trim();
  if (cleaned.contains('T')) {
    final parts = cleaned.split('T');
    if (parts.length > 1) {
      return parts[1].split('.').first;
    }
  }
  return cleaned;
}

Color _riskColor(String risk) {
  final lower = risk.toLowerCase();
  if (lower.contains('high')) return AppColors.danger;
  if (lower.contains('medium')) return AppColors.warning;
  return AppColors.success;
}

Widget _emptyState(String text) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

int _riskRank(String risk) {
  final lower = risk.toLowerCase();
  if (lower.contains('high')) return 2;
  if (lower.contains('medium')) return 1;
  return 0;
}

String _displayMeasurement(double? value, String unit, {int digits = 0}) {
  if (value == null) return 'Unavailable';
  return '${value.toStringAsFixed(digits)} $unit'.trim();
}

AiInsightBundle _buildAiInsightBundle(AnalysisResult result) {
  final qtc = result.measurements['qtc']?.value;
  final qrs = result.measurements['qrs_duration']?.value;
  final st = result.measurements['st_deviation']?.value;
  final sdnn = result.measurements['sdnn']?.value;
  final quality = result.signalQualityLabel?.toLowerCase() ?? 'unknown';
  final qualityPct = result.signalQuality == null
      ? null
      : (result.signalQuality! <= 1
          ? result.signalQuality! * 100.0
          : result.signalQuality!);

  String triage;
  Color triageColor;
  if (result.riskLevel == 'High' ||
      (qtc != null && qtc >= 500) ||
      (st != null && st.abs() >= 0.20)) {
    triage = 'Escalate now';
    triageColor = AppColors.danger;
  } else if (result.riskLevel == 'Medium' ||
      quality != 'high' ||
      (qrs != null && qrs >= 120)) {
    triage = 'Review soon';
    triageColor = AppColors.warning;
  } else {
    triage = 'Routine review';
    triageColor = AppColors.success;
  }

  final watchItems = <String>[
    if (qtc != null && qtc >= 500)
      'QTc appears prolonged at ${qtc.toStringAsFixed(0)} ms.',
    if (qrs != null && qrs >= 120)
      'QRS duration is widened at ${qrs.toStringAsFixed(0)} ms.',
    if (st != null && st.abs() >= 0.20)
      'ST deviation estimate is ${st.toStringAsFixed(2)}.',
    if (sdnn != null && sdnn >= 140)
      'Heart-rate variability is elevated (SDNN ${sdnn.toStringAsFixed(0)} ms).',
    if (quality != 'high')
      'Signal quality is not high, so repeat acquisition may be useful.',
    if (result.bpm >= 120 || result.bpm <= 50)
      'Heart rate is outside a typical resting range at ${result.bpm} bpm.',
  ];

  final nextSteps = <String>[
    if (triage == 'Escalate now')
      'Prioritize physician review before relying on a single screening output.',
    if (triage != 'Escalate now')
      'Compare this ECG with symptoms, history, and previous reports.',
    if (quality != 'high')
      'Repeat the acquisition with better lead or image quality if possible.',
    if (watchItems.isEmpty)
      'Continue longitudinal monitoring and keep the next screening for comparison.',
  ];

  final clinicianSummary =
      'Risk ${result.riskLevel} with ${result.classification.isEmpty ? 'AI screening output available' : result.classification}. '
      'Heart rate ${result.bpm} bpm, signal quality ${result.signalQualityLabel ?? 'unavailable'}, '
      'confidence ${(result.confidence * 100).toStringAsFixed(1)}%.';

  final patientSummary = triage == 'Escalate now'
      ? 'Your result needs medical review soon. This does not confirm a diagnosis, but it should not be ignored.'
      : triage == 'Review soon'
          ? 'Your result shows changes that should be reviewed and compared with your recent ECG history.'
          : 'Your current screening result looks lower priority, but it should still be tracked over time.';

  final qualitySummary = qualityPct == null
      ? 'Signal quality score is unavailable in this session.'
      : 'Signal quality is ${qualityPct.toStringAsFixed(0)}% and labeled ${result.signalQualityLabel ?? quality}.';

  final confidenceSummary =
      'Analysis reliability is ${(result.confidence * 100).toStringAsFixed(1)}% with threshold ${result.threshold.toStringAsFixed(3)}.';

  return AiInsightBundle(
    triage: triage,
    triageColor: triageColor,
    clinicianSummary: clinicianSummary,
    patientSummary: patientSummary,
    qualitySummary: qualitySummary,
    confidenceSummary: confidenceSummary,
    watchItems: watchItems.isEmpty
        ? [
            'No major watch item was flagged from the currently available computed metrics.'
          ]
        : watchItems,
    nextSteps: nextSteps,
  );
}

AiTrendComparison _buildTrendComparison(ReportModel? report) {
  if (report == null || report.bpm.length < 2 || report.riskLevels.length < 2) {
    return const AiTrendComparison(
      headline: 'Trend baseline pending',
      color: AppColors.primary,
      summary:
          'At least two stored ECG results are needed before the app can compare change over time.',
      bpmDeltaLabel: 'Insufficient data',
      riskShiftLabel: 'Insufficient data',
      bullets: [
        'Store another analyzed ECG to activate AI comparison.',
        'Use future sessions to detect whether risk and heart-rate patterns are changing.'
      ],
    );
  }

  final lastBpm = report.bpm.last;
  final previousBpm = report.bpm[report.bpm.length - 2];
  final bpmDelta = lastBpm - previousBpm;
  final lastRisk = report.riskLevels.last;
  final previousRisk = report.riskLevels[report.riskLevels.length - 2];
  final riskShift = _riskRank(lastRisk) - _riskRank(previousRisk);

  String headline;
  Color color;
  String summary;
  if (riskShift > 0 || bpmDelta.abs() >= 20) {
    headline = 'Meaningful change detected';
    color = AppColors.warning;
    summary =
        'The most recent stored ECG looks meaningfully different from the previous one and deserves comparison review.';
  } else if (riskShift < 0) {
    headline = 'Lower recent screening concern';
    color = AppColors.success;
    summary =
        'The latest stored ECG appears less concerning than the previous saved session.';
  } else {
    headline = 'Pattern appears relatively stable';
    color = AppColors.primary;
    summary =
        'The last two stored ECG summaries look broadly similar in risk band and heart-rate behavior.';
  }

  final bullets = <String>[
    'Latest risk: $lastRisk. Previous risk: $previousRisk.',
    'Latest BPM: $lastBpm. Previous BPM: $previousBpm.',
    if (riskShift > 0)
      'Risk band increased across the last two stored reports.',
    if (riskShift < 0)
      'Risk band decreased across the last two stored reports.',
    if (bpmDelta.abs() >= 20)
      'Heart rate changed by ${bpmDelta.abs()} bpm between the two most recent reports.',
  ];

  return AiTrendComparison(
    headline: headline,
    color: color,
    summary: summary,
    bpmDeltaLabel: bpmDelta == 0
        ? 'No BPM change'
        : '${bpmDelta > 0 ? '+' : ''}$bpmDelta bpm',
    riskShiftLabel: riskShift == 0
        ? 'Risk unchanged'
        : riskShift > 0
            ? 'Risk increased'
            : 'Risk decreased',
    bullets: bullets,
  );
}

DoctorCopilotBrief _buildDoctorCopilotBrief(DoctorHomeSnapshot home) {
  final highRiskCount =
      home.reports.where((r) => _riskRank(r.latestRisk) >= 2).length;
  final mediumRiskCount =
      home.reports.where((r) => _riskRank(r.latestRisk) == 1).length;
  final nextVisit = home.appointments.isEmpty ? null : home.appointments.first;

  String headline;
  Color color;
  if (highRiskCount > 0) {
    headline = 'High-priority review queue active';
    color = AppColors.danger;
  } else if (mediumRiskCount > 0 || home.appointments.isNotEmpty) {
    headline = 'Follow-up review recommended';
    color = AppColors.warning;
  } else {
    headline = 'Clinical queue looks stable';
    color = AppColors.success;
  }

  final priorities = <String>[
    if (highRiskCount > 0)
      '$highRiskCount patient report(s) are currently in the highest risk band.',
    if (mediumRiskCount > 0)
      '$mediumRiskCount patient report(s) are in a medium-priority review band.',
    if (nextVisit != null)
      'Next scheduled appointment: ${nextVisit.when} with ${nextVisit.doctorName}.',
    if (!home.onboardingComplete)
      'Complete doctor profile fields to improve patient-facing report context.',
    if (home.reports.isEmpty)
      'No stored reports are available yet; run a new ECG analysis to populate the review center.',
  ];

  return DoctorCopilotBrief(
    headline: headline,
    summary:
        'AI copilot reviewed ${home.patients.length} patient profiles, ${home.reports.length} stored report bundles, and ${home.appointments.length} scheduled follow-up items.',
    color: color,
    priorities: priorities,
  );
}

bool _containsUrgencyKeywords(String text) {
  final lower = text.toLowerCase();
  const keywords = [
    'pain',
    'chest',
    'pressure',
    'faint',
    'dizzy',
    'blackout',
    'emergency',
    'urgent',
    'palpitation',
    'shortness of breath',
    'stroke',
    'weakness',
  ];
  return keywords.any(lower.contains);
}

ChatAiGuide _buildChatAiGuide(
  List<MessageModel> messages, {
  required bool doctorView,
}) {
  if (messages.isEmpty) {
    return ChatAiGuide(
      headline: doctorView ? 'AI conversation starter' : 'AI message starter',
      summary: doctorView
          ? 'No messages are stored yet. Start with a structured clinical check-in.'
          : 'No messages are stored yet. Start with a concise symptom update.',
      statusLabel: 'New thread',
      color: AppColors.primary,
      suggestions: doctorView
          ? const [
              'Please tell me when the symptoms started and whether they are improving or worsening.',
              'Have you uploaded a recent ECG or repeated the measurement today?',
              'If chest pain, fainting, or severe shortness of breath are present, seek urgent care now.',
            ]
          : const [
              'Hello doctor, I want to share my latest ECG and current symptoms.',
              'My symptoms started today and I would like guidance on what to do next.',
              'I repeated the ECG and can upload another file if needed.',
            ],
    );
  }

  final lastMessage = messages.last;
  final urgent = messages.any((m) => _containsUrgencyKeywords(m.text));
  final patientCount = messages.where((m) => m.senderRole == 'patient').length;
  final doctorCount = messages.where((m) => m.senderRole == 'doctor').length;

  if (doctorView) {
    return ChatAiGuide(
      headline: urgent
          ? 'Urgent symptom language detected'
          : 'Doctor AI copilot ready',
      summary: urgent
          ? 'The thread includes urgency-related symptom language. Confirm severity and direct escalation if symptoms are active.'
          : 'The chat looks stable. Use the next message to sharpen timing, symptom burden, and follow-up actions.',
      statusLabel: urgent ? 'Escalation watch' : 'Routine follow-up',
      color: urgent ? AppColors.danger : AppColors.accent,
      suggestions: [
        if (urgent)
          'Your message mentions urgent symptoms. If they are still active, go to emergency care immediately and do not wait for chat review.',
        'Please confirm symptom timing, duration, and whether the ECG was captured during symptoms.',
        'Repeat the ECG upload if the tracing quality was low or if symptoms have changed since the last recording.',
        if (patientCount > doctorCount)
          'I reviewed your updates. I will summarize the next clinical steps after one more ECG comparison.',
      ],
    );
  }

  return ChatAiGuide(
    headline:
        urgent ? 'AI safety reminder active' : 'Patient AI messaging guide',
    summary: urgent
        ? 'Your recent messages include urgent symptom words. Use the chat, but do not rely on messaging alone if symptoms are severe now.'
        : 'Use one clear message that includes symptoms, timing, and whether a new ECG file is available.',
    statusLabel: urgent ? 'Safety warning' : 'Ready to message',
    color: urgent ? AppColors.danger : AppColors.success,
    suggestions: [
      if (urgent)
        'My symptoms are active right now. Please advise whether I should seek emergency care immediately.',
      'I uploaded my latest ECG. My current symptoms started at [time] and feel [better/same/worse].',
      'I do not have severe symptoms right now, but I want to know whether I should repeat the ECG today.',
      if (lastMessage.senderRole == 'doctor')
        'Thank you doctor. I will follow the plan and send another ECG if my symptoms change.',
    ],
  );
}

LiveMonitoringAiBrief _buildLiveMonitoringAiBrief({
  required double riskLevel,
  required String connectionMode,
  required String connectionStatus,
  required String region,
  required List<String> activeCoils,
  required List<double> ecgPoints,
}) {
  final lowerStatus = connectionStatus.toLowerCase();
  final degraded = lowerStatus.contains('error') ||
      lowerStatus.contains('failed') ||
      lowerStatus.contains('not');
  final connected =
      lowerStatus.contains('connected') || lowerStatus.contains('demo');
  final recent = ecgPoints.length > 32
      ? ecgPoints.sublist(ecgPoints.length - 32)
      : ecgPoints;

  double amplitudeRange = 0;
  double meanAbs = 0;
  if (recent.isNotEmpty) {
    var minV = recent.first;
    var maxV = recent.first;
    var totalAbs = 0.0;
    for (final value in recent) {
      if (value < minV) minV = value;
      if (value > maxV) maxV = value;
      totalAbs += value.abs();
    }
    amplitudeRange = maxV - minV;
    meanAbs = totalAbs / recent.length;
  }

  final dynamicSignal = amplitudeRange >= 1.6 || meanAbs >= 0.45;
  final moderateSignal = amplitudeRange >= 0.9 || meanAbs >= 0.25;

  String headline;
  String urgencyLabel;
  String signalLabel;
  String recommendedAction;
  String summary;
  Color color;

  if (degraded) {
    headline = 'Monitoring reliability degraded';
    urgencyLabel = 'Reconnect now';
    signalLabel = 'Acquisition unstable';
    recommendedAction =
        'Reacquire the stream before interpreting risk changes.';
    summary =
        'The live feed is not in a reliable state, so current ECG-driven alerts should be treated cautiously.';
    color = AppColors.danger;
  } else if (riskLevel >= 0.62) {
    headline = 'Elevated live screening pattern';
    urgencyLabel = 'Review immediately';
    signalLabel = dynamicSignal
        ? 'High waveform activity'
        : 'High risk, low-amplitude window';
    recommendedAction =
        'Keep the stream active, compare symptoms, and prepare escalation if the pattern persists.';
    summary =
        'The rolling ECG window is in the highest monitoring band, so the app is maintaining a higher-alert posture.';
    color = AppColors.danger;
  } else if (riskLevel >= 0.35) {
    headline = 'Intermediate monitoring watch';
    urgencyLabel = 'Watch closely';
    signalLabel = moderateSignal
        ? 'Moderate waveform variation'
        : 'Moderate screening shift';
    recommendedAction =
        'Continue live observation and save a physician-ready report if symptoms are present.';
    summary =
        'The live ECG window shows enough change to justify closer observation, but not the highest alert state.';
    color = AppColors.warning;
  } else {
    headline = 'Live session appears stable';
    urgencyLabel = 'Routine monitoring';
    signalLabel = connected ? 'Connected baseline' : 'Baseline pending';
    recommendedAction =
        'Continue monitoring and preserve the session if the patient develops new symptoms.';
    summary =
        'The current ECG window remains in a lower screening band with no dominant live alert trigger.';
    color = AppColors.success;
  }

  return LiveMonitoringAiBrief(
    headline: headline,
    summary: summary,
    urgencyLabel: urgencyLabel,
    signalLabel: signalLabel,
    recommendedAction: recommendedAction,
    color: color,
    bullets: [
      'Stream mode: $connectionMode. Connection state: $connectionStatus.',
      'Recent waveform range: ${amplitudeRange.toStringAsFixed(2)} with mean absolute amplitude ${meanAbs.toStringAsFixed(2)}.',
      'Detected region: ${region == 'Low' ? 'No dominant alert region' : region}.',
      'Active coil targets: ${activeCoils.isEmpty ? 'none' : activeCoils.join(', ')}.',
    ],
  );
}

MessagingOpsBrief _buildMessagingOpsBrief(DoctorHomeSnapshot home) {
  final unread = home.stats.messages;
  final flagged = home.stats.emergencies;
  final highRiskCount =
      home.reports.where((r) => _riskRank(r.latestRisk) >= 2).length;

  String headline;
  String summary;
  String queueLabel;
  String responseLabel;
  Color color;

  if (flagged > 0 || highRiskCount > 0) {
    headline = 'Escalation-sensitive inbox';
    summary =
        'The communication queue should be handled with priority because flagged cases and high-risk reports are present.';
    queueLabel = 'Priority queue active';
    responseLabel = unread > 0 ? 'Respond now' : 'Watch for updates';
    color = AppColors.danger;
  } else if (unread > 0) {
    headline = 'Patient communication pending';
    summary =
        'New or unresolved messaging items are present even though the overall risk queue is not in the highest band.';
    queueLabel = '$unread message item(s)';
    responseLabel = 'Reply soon';
    color = AppColors.warning;
  } else {
    headline = 'Messaging workload stable';
    summary =
        'No urgent communication pressure is visible from the current dashboard snapshot.';
    queueLabel = 'Inbox clear';
    responseLabel = 'Routine follow-up';
    color = AppColors.success;
  }

  return MessagingOpsBrief(
    headline: headline,
    summary: summary,
    queueLabel: queueLabel,
    responseLabel: responseLabel,
    color: color,
    bullets: [
      '${home.patients.length} patient profile(s) are currently visible in the doctor workspace.',
      if (highRiskCount > 0)
        '$highRiskCount recent report(s) are in the highest risk band and may justify proactive outreach.',
      if (flagged > 0)
        '$flagged emergency or flagged workflow item(s) should be reviewed before routine chat follow-up.',
      if (unread == 0)
        'No unread message pressure is currently reflected in the doctor dashboard stats.',
      if (unread > 0)
        'Use the patient chat helper to send structured follow-up requests instead of short unstructured replies.',
    ],
  );
}

PatientAiCompanionBrief _buildPatientAiCompanionBrief({
  required AppDoctor? doctor,
}) {
  if (doctor == null) {
    return const PatientAiCompanionBrief(
      headline: 'Independent monitoring mode',
      summary:
          'The patient profile can analyze ECGs and monitor sessions without linking a doctor first, but clinical follow-up is still easier once a physician is added.',
      readinessLabel: 'Analysis ready',
      doctorStateLabel: 'Doctor optional',
      color: AppColors.warning,
      bullets: [
        'You can open analysis, live monitoring, and report generation without a doctor link.',
        'Add a doctor later when you want direct messaging and follow-up coordination.',
        'Use messaging only after a patient record and communication context are available.',
      ],
    );
  }

  return PatientAiCompanionBrief(
    headline: 'Connected care companion ready',
    summary:
        'The patient profile is linked to ${doctor.name}, so AI analysis, reporting, and doctor messaging can work together in one care flow.',
    readinessLabel: 'Connected workflow',
    doctorStateLabel: doctor.specialty,
    color: AppColors.success,
    bullets: [
      'Use live monitoring for immediate session review, then store a report if symptoms change.',
      'Use messages to send a structured update after uploading a new ECG.',
      'Keep the doctor link updated so reports and follow-up context stay aligned.',
    ],
  );
}

String _timeStampLabel() {
  final now = DateTime.now();
  final h = now.hour.toString().padLeft(2, '0');
  final m = now.minute.toString().padLeft(2, '0');
  final s = now.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

Widget _chatAiGuideCard(
  BuildContext context, {
  required ChatAiGuide guide,
  required ValueChanged<String> onSuggestionTap,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: guide.color.withAlpha(60)),
      boxShadow: AppShadows.soft,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: guide.color.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_awesome, color: guide.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guide.headline,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    guide.statusLabel,
                    style: TextStyle(
                      color: guide.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          guide.summary,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: guide.suggestions
              .map(
                (suggestion) => ActionChip(
                  avatar:
                      Icon(Icons.bolt_rounded, size: 16, color: guide.color),
                  side: BorderSide(color: guide.color.withAlpha(50)),
                  backgroundColor: guide.color.withAlpha(12),
                  label: Text(
                    suggestion,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => onSuggestionTap(suggestion),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

Widget _topActionShell({
  required BuildContext context,
  required IconData icon,
  required VoidCallback onTap,
  required String tooltip,
}) {
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withAlpha(236),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
        ),
      ),
    ),
  );
}

Widget _workspaceAction(BuildContext context) {
  return _topActionShell(
    context: context,
    icon: Icons.grid_view_rounded,
    tooltip: _t('Quick access', 'وصول سريع'),
    onTap: () => _showSplashTools(context, ApiService(baseUrl: _apiBaseUrl())),
  );
}

Widget _settingsAction(BuildContext context) {
  return _topActionShell(
    context: context,
    icon: Icons.settings_outlined,
    tooltip: _t('Settings', 'الإعدادات'),
    onTap: () => Navigator.push(
      context,
      _fadeRoute(const SettingsPage()),
    ),
  );
}

List<Widget> _topBarActions(BuildContext context) {
  return [
    _workspaceAction(context),
    _settingsAction(context),
  ];
}

String _t(String en, String ar) {
  return AppState.isArabic.value ? ar : en;
}

Widget _retryCard({required String message, required VoidCallback onRetry}) {
  return GlassPanel(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.danger),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(_t('Retry', 'Ø¥Ø¹Ø§Ø¯Ø© Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø©')),
        ),
      ],
    ),
  );
}

class CardiacApp extends StatelessWidget {
  const CardiacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState.isArabic,
      builder: (context, isArabic, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: AppState.isDarkMode,
          builder: (context, isDarkMode, __) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(isArabic: isArabic),
              darkTheme: AppTheme.dark(isArabic: isArabic),
              themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
              locale: isArabic ? const Locale('ar') : const Locale('en'),
              supportedLocales: const [
                Locale('en'),
                Locale('ar'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return Directionality(
                  textDirection:
                      isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: const SessionBootstrapPage(),
            );
          },
        );
      },
    );
  }
}

class SessionBootstrapPage extends StatefulWidget {
  const SessionBootstrapPage({super.key});

  @override
  State<SessionBootstrapPage> createState() => _SessionBootstrapPageState();
}

class _SessionBootstrapPageState extends State<SessionBootstrapPage> {
  late final Future<Widget> _futureHome;

  @override
  void initState() {
    super.initState();
    _futureHome = _resolveHome();
  }

  Future<Widget> _resolveHome() async {
    SessionStore.instance.restoreSettings();
    final snapshot = SessionStore.instance.restoreSession();
    if (snapshot == null) {
      return const SplashScreen();
    }

    ApiService.restoreAuth(
      token: snapshot.token,
      role: snapshot.role,
      username: snapshot.username,
    );
    AppState.restoreDoctorContext(
      currentDoctor: snapshot.currentDoctor,
      selectedDoctorValue: snapshot.selectedDoctor,
    );
    AppState.currentWorkspace = snapshot.workspace;

    final api = ApiService(baseUrl: _apiBaseUrl());
    try {
      final me = await api.me();
      final resolvedName = (me.name ?? snapshot.username).trim().isEmpty
          ? snapshot.username
          : (me.name ?? snapshot.username).trim();
      ApiService.restoreAuth(
        token: snapshot.token,
        role: me.role,
        username: resolvedName,
      );
      await AppState.persistSession(
        token: snapshot.token,
        role: me.role,
        username: resolvedName,
        workspace: snapshot.workspace,
      );

      switch (snapshot.workspace) {
        case 'doctor_dashboard':
          final doctorName =
              AppState.currentDoctorProfile?.name ?? resolvedName;
          return DoctorDashboard(username: doctorName);
        case 'patient_home':
          return PatientHome(username: resolvedName);
        case 'role_selection':
          return RoleSelectionPage(username: resolvedName);
        default:
          return me.role == 'patient'
              ? PatientHome(username: resolvedName)
              : RoleSelectionPage(username: resolvedName);
      }
    } catch (_) {
      final fallbackName =
          snapshot.username.trim().isEmpty ? 'User' : snapshot.username.trim();
      ApiService.restoreAuth(
        token: snapshot.token,
        role: snapshot.role,
        username: fallbackName,
      );
      switch (snapshot.workspace) {
        case 'doctor_dashboard':
          final doctorName =
              AppState.currentDoctorProfile?.name ?? fallbackName;
          return DoctorDashboard(username: doctorName);
        case 'patient_home':
          return PatientHome(username: fallbackName);
        case 'role_selection':
          return RoleSelectionPage(username: fallbackName);
        default:
          return snapshot.role == 'patient'
              ? PatientHome(username: fallbackName)
              : RoleSelectionPage(username: fallbackName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _futureHome,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data ?? const SplashScreen();
      },
    );
  }
}

TextStyle _inputTextStyle(BuildContext context) {
  return const TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.w600,
  );
}

String _patientLoadMessage(Object? error) {
  final raw = (error ?? '').toString().toLowerCase();
  if (raw.contains('404') || raw.contains('not found')) {
    return _t(
      "You don't have patients yet. Add your first patient to start the registry.",
      'لا يوجد مرضى لديك بعد. أضف أول مريض لبدء السجل.',
    );
  }
  if (raw.contains('401') || raw.contains('403') || raw.contains('auth')) {
    return _t(
      'Your session expired. Sign in again to load patient records.',
      'انتهت الجلسة. سجّل الدخول مرة أخرى لتحميل سجلات المرضى.',
    );
  }
  if (raw.contains('network') ||
      raw.contains('socket') ||
      raw.contains('timeout')) {
    return _t(
      'Connection problem while loading patients. Check the network or backend and retry.',
      'مشكلة اتصال أثناء تحميل المرضى. تحقّق من الشبكة أو الخادم ثم أعد المحاولة.',
    );
  }
  return _t(
    "We couldn't load the patient list right now. Retry in a moment.",
    'تعذر تحميل قائمة المرضى الآن. أعد المحاولة بعد لحظة.',
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService(baseUrl: _apiBaseUrl());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  _splashCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: Text(
                      AppState.projectName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  _splashCircleButton(
                    icon: Icons.grid_view_rounded,
                    onPressed: () => _showSplashTools(context, api),
                  ),
                  const SizedBox(width: 8),
                  _splashCircleButton(
                    icon: Icons.settings_outlined,
                    onPressed: () => Navigator.push(
                      context,
                      _fadeRoute(const SettingsPage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GlassPanel(
                            padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
                            radius: BorderRadius.circular(34),
                            child: Column(
                              children: [
                                Container(
                                  width: 108,
                                  height: 108,
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.hero,
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: AppShadows.lift,
                                  ),
                                  child: const Icon(
                                    Icons.monitor_heart_outlined,
                                    size: 54,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentSoft,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    _t('AI-Assisted ECG Analysis',
                                        'تحليل ECG بالذكاء الاصطناعي'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.accentDeep,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  AppState.projectName.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        height: 1.0,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 14),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 520),
                                  child: Text(
                                    _t(
                                      'Premium ECG intelligence for screening, monitoring, and physician-ready reporting.',
                                      'منصة طبية متقدمة لفحص ECG والمراقبة اللحظية وإخراج تقارير جاهزة للطبيب.',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 17,
                                      height: 1.55,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _heroMetricChip(
                                      icon: Icons.bolt_rounded,
                                      label: _t('Fast ECG Intake',
                                          'استقبال سريع للإشارات'),
                                    ),
                                    _heroMetricChip(
                                      icon: Icons.analytics_rounded,
                                      label: _t(
                                          'Clinical Metrics', 'مؤشرات سريرية'),
                                    ),
                                    _heroMetricChip(
                                      icon: Icons.picture_as_pdf_rounded,
                                      label: _t('Shareable PDF Reports',
                                          'تقارير PDF قابلة للمشاركة'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final compact = constraints.maxWidth < 520;
                                    final buttons = [
                                      SizedBox(
                                        width: compact ? double.infinity : 220,
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            _fadeRoute(const LoginPage()),
                                          ),
                                          child: Text(_t(
                                              'Enter Platform', 'دخول المنصة')),
                                        ),
                                      ),
                                      SizedBox(
                                        width: compact ? double.infinity : 220,
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            _fadeRoute(const RoleSelectionPage(
                                                username: 'Demo User')),
                                          ),
                                          child: Text(_t(
                                              'Explore Demo', 'استكشاف العرض')),
                                        ),
                                      ),
                                    ];
                                    if (compact) {
                                      return Column(
                                        children: [
                                          buttons[0],
                                          const SizedBox(height: 12),
                                          buttons[1],
                                        ],
                                      );
                                    }
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        buttons[0],
                                        const SizedBox(width: 12),
                                        buttons[1],
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.push(
                                      context,
                                      _fadeRoute(
                                        const PatientLiveScreen(
                                          username: 'Prototype Patient',
                                          prototypeDemo: true,
                                        ),
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    child: Ink(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.accentDeep,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: AppShadows.lift,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withAlpha(24),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color:
                                                    Colors.white.withAlpha(45),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.sensors_rounded,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 7,
                                                      height: 7,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color:
                                                            AppColors.success,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 7),
                                                    Text(
                                                      _t(
                                                        'PROTOTYPE LIVE DEMO',
                                                        'عرض النموذج الحي',
                                                      ),
                                                      style: const TextStyle(
                                                        color: AppColors
                                                            .accentSoft,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: .7,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  _t(
                                                    'Live Patient Monitor',
                                                    'مراقبة المريض لحظيًا',
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  _t(
                                                    'ESP32 + one-lead ECG simulation, BLE/Wi-Fi setup, and live signal status.',
                                                    'محاكاة ESP32 ومستشعر ECG أحادي القناة مع إعداد BLE وWi-Fi وحالة الإشارة الحية.',
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withAlpha(180),
                                                    fontSize: 11,
                                                    height: 1.35,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
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

Widget _splashCircleButton({
  required IconData icon,
  required VoidCallback onPressed,
}) {
  return Material(
    color: Colors.white.withAlpha(235),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    ),
  );
}

Widget _heroMetricChip({
  required IconData icon,
  required String label,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.accentDeep),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ],
    ),
  );
}

Widget _splashShortcutCard({
  required String title,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(22),
    child: Container(
      width: 158,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    ),
  );
}

void _showSplashTools(BuildContext context, ApiService api) {
  final actions = [
    (
      _t('Doctor Reports', 'تقارير الطبيب'),
      Icons.analytics_outlined,
      () => Navigator.push(context, _fadeRoute(const DoctorReportsPage()))
    ),
    (
      _t('Patient History', 'سجل المريض'),
      Icons.history_rounded,
      () => Navigator.push(context, _fadeRoute(const PatientHistoryPage()))
    ),
    (
      _t('Session Logs', 'سجل الجلسات'),
      Icons.timeline_rounded,
      () => Navigator.push(context, _fadeRoute(const SessionLogPage()))
    ),
    (
      _t('Patient Management', 'إدارة المرضى'),
      Icons.people_alt_outlined,
      () => Navigator.push(context, _fadeRoute(DoctorPatientsPage(api: api)))
    ),
    (
      _t('Help Center', 'مركز المساعدة'),
      Icons.help_outline_rounded,
      () => Navigator.push(context, _fadeRoute(const HelpCenterPage()))
    ),
    (
      _t('Settings', 'الإعدادات'),
      Icons.settings_outlined,
      () => Navigator.push(context, _fadeRoute(const SettingsPage()))
    ),
  ];

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _t('Quick Access', 'وصول سريع'),
                style: GoogleFonts.sora(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 14),
              ...actions.map(
                (item) => ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  tileColor: AppColors.surfaceAlt,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Icon(item.$2, color: AppColors.primary),
                  title: Text(
                    item.$1,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    item.$3();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final ApiService _api = ApiService(baseUrl: _apiBaseUrl());
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final mobile = _mobile.text.trim();
    final password = _password.text;
    if (mobile.isEmpty || password.isEmpty) {
      setState(() => _error = _t('Enter mobile number and password.',
          'أدخل رقم الهاتف وكلمة المرور.'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _api.login(
        email: _authIdentityToEmail(mobile),
        mobile: mobile,
        password: password,
      );
      ApiService.restoreAuth(
        token: user.token,
        role: user.role,
        username: (user.name ?? mobile).trim().isEmpty
            ? mobile
            : (user.name ?? mobile).trim(),
      );
      AppState.currentWorkspace = 'role_selection';
      final resolvedName = (user.name ?? mobile).trim().isEmpty
          ? mobile
          : (user.name ?? mobile).trim();
      final isPatient = user.role == 'patient';
      AppState.currentWorkspace = isPatient ? 'patient_home' : 'role_selection';
      await AppState.persistSession(
        token: user.token,
        role: user.role,
        username: resolvedName,
        workspace: isPatient ? 'patient_home' : 'role_selection',
      );
      if (!mounted) return;
      final displayName = resolvedName;
      Navigator.pushReplacement(
        context,
        _fadeRoute(
          isPatient
              ? PatientHome(username: displayName)
              : RoleSelectionPage(username: displayName),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _mobile.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AppBackdrop(
        dark: dark,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1020),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 860;
                    final intro = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassPanel(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          radius: BorderRadius.circular(999),
                          child: Text(
                            _t('SECURE CLINICAL ACCESS', 'دخول سريري آمن'),
                            style: TextStyle(
                              color: dark ? Colors.white : AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          AppState.projectName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: dark ? Colors.white : AppColors.primary,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _t(
                            'Trusted access for patients, physicians, and supervised screening workflows.',
                            'دخول موثوق للمرضى والأطباء ومسارات الفحص الخاضعة للإشراف.',
                          ),
                          style: TextStyle(
                            color:
                                dark ? Colors.white70 : AppColors.textSecondary,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _signalChip(Icons.auto_graph_rounded,
                                _t('Real ECG analysis', 'تحليل ECG حقيقي')),
                            _signalChip(Icons.shield_outlined,
                                _t('Protected access', 'وصول محمي')),
                            _signalChip(Icons.description_outlined,
                                _t('Medical reporting', 'تقارير طبية')),
                          ],
                        ),
                      ],
                    );
                    final form = GlassPanel(
                      padding: const EdgeInsets.all(26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_t('Sign in', 'تسجيل الدخول'),
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                            _t(
                              'Use your account to continue into the correct medical workflow.',
                              'استخدم حسابك للمتابعة داخل المسار الطبي المناسب.',
                            ),
                            style: TextStyle(
                              color: dark
                                  ? Colors.white60
                                  : AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _mobile,
                            keyboardType: TextInputType.phone,
                            style: _inputTextStyle(context),
                            decoration: InputDecoration(
                              labelText: _t('Mobile Number', 'رقم الهاتف'),
                              prefixIcon:
                                  const Icon(Icons.phone_iphone_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _password,
                            obscureText: true,
                            style: _inputTextStyle(context),
                            decoration: InputDecoration(
                              labelText: _t('Password', 'كلمة المرور'),
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_t(
                                      'Password reset is not connected yet.',
                                      'استعادة كلمة المرور غير متصلة بعد.',
                                    )),
                                  ),
                                );
                              },
                              child: Text(
                                  _t('Forgot password', 'نسيت كلمة المرور')),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!,
                                style:
                                    const TextStyle(color: AppColors.danger)),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              child: Text(
                                _loading
                                    ? _t('Signing in...', 'جارٍ الدخول...')
                                    : _t('Continue to platform',
                                        'الدخول إلى المنصة'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.push(
                                  context, _fadeRoute(const RegisterPage())),
                              child: Text(
                                  _t('Create new account', 'إنشاء حساب جديد')),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                _fadeRoute(const GuidedDemoPage()),
                              ),
                              icon:
                                  const Icon(Icons.play_circle_outline_rounded),
                              label: Text(_t(
                                  'Watch full demo', 'مشاهدة الديمو الكامل')),
                            ),
                          ),
                        ],
                      ),
                    );
                    return wide
                        ? Row(
                            children: [
                              Expanded(
                                  child: Padding(
                                      padding: const EdgeInsets.only(right: 24),
                                      child: intro)),
                              Expanded(child: form),
                            ],
                          )
                        : Column(
                            children: [
                              intro,
                              const SizedBox(height: 20),
                              form,
                            ],
                          );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final TextEditingController _specialty = TextEditingController();
  final ApiService _api = ApiService(baseUrl: _apiBaseUrl());
  String _role = 'doctor';
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final name = _name.text.trim();
    final mobile = _mobile.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;
    if (name.isEmpty || mobile.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _error =
          _t('Complete all required fields.', 'أكمل كل الحقول المطلوبة.'));
      return;
    }
    if (!RegExp(r'^[0-9+\-\s]{8,20}$').hasMatch(mobile)) {
      setState(() =>
          _error = _t('Enter a valid mobile number.', 'أدخل رقم هاتف صحيح.'));
      return;
    }
    if (password.length < 6) {
      setState(() => _error = _t('Password must be at least 6 characters.',
          'كلمة المرور يجب أن تكون 6 أحرف على الأقل.'));
      return;
    }
    if (password != confirm) {
      setState(() => _error = _t('Password confirmation does not match.',
          'تأكيد كلمة المرور غير مطابق.'));
      return;
    }
    if (_role == 'doctor' && _specialty.text.trim().isEmpty) {
      setState(
          () => _error = _t('Enter medical specialty.', 'أدخل التخصص الطبي.'));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _api.register(
        email: _authIdentityToEmail(mobile),
        mobile: mobile,
        password: password,
        role: _role,
        name: name,
        specialty: _role == 'doctor' ? _specialty.text.trim() : null,
      );
      final resolvedDisplayName = (user.name ?? name).trim().isEmpty
          ? name
          : (user.name ?? name).trim();
      ApiService.restoreAuth(
        token: user.token,
        role: user.role,
        username: resolvedDisplayName,
      );
      if (!mounted) return;
      final displayName = resolvedDisplayName;
      if (user.role == 'doctor') {
        AppState.currentWorkspace = 'role_selection';
        await AppState.persistSession(
          token: user.token,
          role: user.role,
          username: displayName,
          workspace: 'role_selection',
        );
        Navigator.pushReplacement(
          context,
          _fadeRoute(DoctorProfileSetupPage(initialName: displayName)),
        );
      } else {
        AppState.currentWorkspace = 'patient_home';
        await AppState.persistSession(
          token: user.token,
          role: user.role,
          username: displayName,
          workspace: 'patient_home',
        );
        Navigator.pushReplacement(
          context,
          _fadeRoute(PatientHome(username: displayName)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isDoctor = _role == 'doctor';
    final intro = GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppGradients.hero,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.lift,
            ),
            child: const Icon(Icons.person_add_alt_1_rounded,
                size: 36, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            isDoctor
                ? _t('Create your doctor workspace', 'أنشئ مساحة الطبيب')
                : _t('Create your patient account', 'أنشئ حساب المريض'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: dark ? Colors.white : AppColors.ink,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            isDoctor
                ? _t(
                    'Register once, then open doctor dashboards, patient review tools, ECG analysis, and report workflows.',
                    'سجل مرة واحدة ثم افتح لوحات الطبيب وأدوات مراجعة المرضى وتحليل ECG ومسارات التقارير.',
                  )
                : _t(
                    'Register once, then start personal ECG analysis, report access, and independent health tracking.',
                    'سجل مرة واحدة ثم ابدأ تحليل ECG الشخصي والوصول للتقارير والمتابعة الصحية المستقلة.',
                  ),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: dark ? AppColors.textSecondary : AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _signalChip(Icons.verified_user_outlined,
                  _t('Secure onboarding', 'دخول آمن')),
              _signalChip(
                isDoctor
                    ? Icons.dashboard_customize_outlined
                    : Icons.monitor_heart_outlined,
                isDoctor
                    ? _t('Doctor dashboard', 'لوحة الطبيب')
                    : _t('Personal ECG', 'ECG شخصي'),
              ),
              _signalChip(
                isDoctor
                    ? Icons.assignment_outlined
                    : Icons.insert_chart_outlined_rounded,
                isDoctor
                    ? _t('Clinical reports', 'تقارير سريرية')
                    : _t('Health tracking', 'متابعة صحية'),
              ),
            ],
          ),
        ],
      ),
    );

    final form = GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDoctor
                ? _t('Doctor account setup', 'إعداد حساب الطبيب')
                : _t('Patient account setup', 'إعداد حساب المريض'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isDoctor
                ? _t(
                    'Choose doctor access, complete your identity fields, then continue to the doctor workflow.',
                    'اختر حساب الطبيب، وأكمل بياناتك، ثم تابع إلى مسار الطبيب.',
                  )
                : _t(
                    'Choose patient access, complete your identity fields, then continue directly to the patient workspace.',
                    'اختر حساب المريض، وأكمل بياناتك، ثم تابع مباشرة إلى مساحة المريض.',
                  ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: InputDecoration(
              labelText: _t('Account Type', 'نوع الحساب'),
              prefixIcon: const Icon(Icons.person_outline),
            ),
            items: [
              DropdownMenuItem(
                value: 'doctor',
                child: Text(_t('Doctor', 'طبيب')),
              ),
              DropdownMenuItem(
                value: 'patient',
                child: Text(_t('Patient', 'مريض')),
              ),
            ],
            onChanged: (v) => setState(() => _role = v ?? 'doctor'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            style: _inputTextStyle(context),
            decoration: InputDecoration(
              labelText: _t('Full Name', 'الاسم الكامل'),
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            style: _inputTextStyle(context),
            decoration: InputDecoration(
              labelText: _t('Mobile Number', 'رقم الهاتف'),
              prefixIcon: const Icon(Icons.phone_iphone_outlined),
            ),
          ),
          if (_role == 'doctor') ...[
            const SizedBox(height: 14),
            TextField(
              controller: _specialty,
              style: _inputTextStyle(context),
              decoration: InputDecoration(
                labelText: _t('Medical Specialty', 'التخصص الطبي'),
                prefixIcon: const Icon(Icons.local_hospital_outlined),
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            obscureText: true,
            style: _inputTextStyle(context),
            decoration: InputDecoration(
              labelText: _t('Password', 'كلمة المرور'),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirm,
            obscureText: true,
            style: _inputTextStyle(context),
            decoration: InputDecoration(
              labelText: _t('Confirm Password', 'تأكيد كلمة المرور'),
              prefixIcon: const Icon(Icons.verified_user_outlined),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(dark ? 0.18 : 0.09),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.danger.withOpacity(0.28)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: Icon(_loading ? Icons.sync : Icons.arrow_forward_rounded),
              label: Text(
                _loading
                    ? _t('Creating...', 'جارٍ الإنشاء...')
                    : isDoctor
                        ? _t('Create Doctor Account', 'إنشاء حساب الطبيب')
                        : _t('Create Patient Account', 'إنشاء حساب المريض'),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: AppBackdrop(
        dark: dark,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 920;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: wide
                          ? [
                              Expanded(child: intro),
                              const SizedBox(width: 24),
                              Expanded(child: form),
                            ]
                          : [
                              Expanded(
                                child: ListView(
                                  shrinkWrap: true,
                                  children: [
                                    intro,
                                    const SizedBox(height: 20),
                                    form,
                                  ],
                                ),
                              ),
                            ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GuidedDemoPage extends StatefulWidget {
  const GuidedDemoPage({super.key});

  @override
  State<GuidedDemoPage> createState() => _GuidedDemoPageState();
}

class _GuidedDemoPageState extends State<GuidedDemoPage> {
  static const List<
      ({
        String title,
        String titleAr,
        String description,
        String descriptionAr,
        IconData icon,
        Color color,
        List<String> points,
        List<String> pointsAr,
      })> _scenes = [
    (
      title: 'Secure Clinical Sign-In',
      titleAr: 'تسجيل دخول سريري آمن',
      description:
          'A user enters the platform, authentication completes, and the correct medical workspace opens immediately.',
      descriptionAr:
          'يدخل المستخدم إلى المنصة، ثم تكتمل المصادقة ويفتح النظام مساحة العمل الطبية المناسبة فورًا.',
      icon: Icons.login_rounded,
      color: AppColors.accent,
      points: ['Fast access', 'Protected workflow', 'Role routing'],
      pointsAr: ['دخول سريع', 'مسار محمي', 'توجيه حسب الدور'],
    ),
    (
      title: 'Doctor Dashboard',
      titleAr: 'لوحة الطبيب',
      description:
          'The doctor reviews active patients, pending reports, alerts, and recent ECG sessions from one command center.',
      descriptionAr:
          'يراجع الطبيب المرضى النشطين والتقارير المعلقة والتنبيهات وجلسات ECG الأخيرة من شاشة واحدة.',
      icon: Icons.dashboard_customize_rounded,
      color: AppColors.success,
      points: ['Patient list', 'Alert queue', 'Quick review'],
      pointsAr: ['قائمة المرضى', 'قائمة التنبيهات', 'مراجعة سريعة'],
    ),
    (
      title: 'Live ECG Monitoring',
      titleAr: 'مراقبة ECG لحظية',
      description:
          'The patient view streams the waveform in real time with rhythm status, heart rate, and signal health.',
      descriptionAr:
          'تعرض شاشة المريض الموجة بشكل حي مع حالة الإيقاع ومعدل النبض وجودة الإشارة.',
      icon: Icons.monitor_heart_outlined,
      color: AppColors.warning,
      points: ['Live waveform', 'BPM tracking', 'Signal quality'],
      pointsAr: ['موجة حية', 'متابعة النبض', 'جودة الإشارة'],
    ),
    (
      title: 'AI Clinical Analysis',
      titleAr: 'تحليل سريري بالذكاء الاصطناعي',
      description:
          'The model extracts ECG insights, grades risk, and highlights the main findings for physician review.',
      descriptionAr:
          'يقوم النموذج باستخراج مؤشرات ECG وتقدير الخطورة وإبراز أهم النتائج لمراجعة الطبيب.',
      icon: Icons.auto_graph_rounded,
      color: AppColors.danger,
      points: ['AI confidence', 'Risk score', 'Feature summary'],
      pointsAr: ['ثقة النموذج', 'درجة الخطورة', 'ملخص المؤشرات'],
    ),
    (
      title: 'Report Generation',
      titleAr: 'توليد التقرير',
      description:
          'A polished PDF report is generated with medical layout, visual charts, and doctor-ready case details.',
      descriptionAr:
          'يتم توليد تقرير PDF منظم مع تصميم طبي وجرافات مرئية وتفاصيل جاهزة للطبيب.',
      icon: Icons.picture_as_pdf_rounded,
      color: Color(0xFF7A9BFF),
      points: ['PDF output', 'Share ready', 'Clinical summary'],
      pointsAr: ['إخراج PDF', 'جاهز للمشاركة', 'ملخص سريري'],
    ),
  ];

  late final PageController _controller;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentIndex + 1) % _scenes.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
      );
      setState(() => _currentIndex = next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AppBackdrop(
        dark: dark,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: dark ? Colors.white : AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _t('Watch Demo', 'مشاهدة الديمو'),
                            style: TextStyle(
                              color: dark ? Colors.white : AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _t(
                              'A cinematic walkthrough of the full medical workflow',
                              'استعراض مرئي كامل لمسار الاستخدام الطبي',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: dark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.maybePop(context),
                      child: Text(_t('Close', 'إغلاق')),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GlassPanel(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppGradients.hero,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppState.projectName,
                              style: TextStyle(
                                color: dark ? Colors.white : AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _t(
                                'This demo presents login, doctor review, live ECG, AI analysis, and PDF reporting.',
                                'هذا الديمو يعرض تسجيل الدخول ومراجعة الطبيب وECG الحي والتحليل الذكي والتقرير النهائي.',
                              ),
                              style: TextStyle(
                                color: dark
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _scenes.length,
                    onPageChanged: (value) =>
                        setState(() => _currentIndex = value),
                    itemBuilder: (context, index) {
                      final scene = _scenes[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _DemoSceneCard(
                          title: _t(scene.title, scene.titleAr),
                          description:
                              _t(scene.description, scene.descriptionAr),
                          icon: scene.icon,
                          color: scene.color,
                          points: AppState.isArabic.value
                              ? scene.pointsAr
                              : scene.points,
                          active: index == _currentIndex,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _scenes.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? AppColors.accent
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(_t('Back', 'رجوع')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          _fadeRoute(
                              const RoleSelectionPage(username: 'Demo User')),
                        ),
                        icon: const Icon(Icons.rocket_launch_outlined),
                        label:
                            Text(_t('Open demo flow', 'فتح الديمو التفاعلي')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoSceneCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> points;
  final bool active;

  const _DemoSceneCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.points,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedScale(
      duration: const Duration(milliseconds: 280),
      scale: active ? 1 : 0.975,
      child: GlassPanel(
        padding: const EdgeInsets.all(22),
        radius: BorderRadius.circular(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color, size: 29),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: dark ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _t('Feature highlight', 'عرض مميز'),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withAlpha(22),
                      dark
                          ? AppColors.surfaceDark.withAlpha(180)
                          : Colors.white,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: color.withAlpha(44)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _demoStatusDot(Colors.redAccent),
                        const SizedBox(width: 6),
                        _demoStatusDot(AppColors.warning),
                        const SizedBox(width: 6),
                        _demoStatusDot(AppColors.success),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withAlpha(26),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _t('DEMO', 'ديمو'),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  description,
                                  style: TextStyle(
                                    color: dark
                                        ? Colors.white70
                                        : AppColors.textSecondary,
                                    fontSize: 14.5,
                                    height: 1.55,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                ...points.map(
                                  (point) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded,
                                            color: color, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            point,
                                            style: TextStyle(
                                              color: dark
                                                  ? Colors.white
                                                  : AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                _demoMetricCard(
                                  label: _t('Heartbeat', 'النبض'),
                                  value: active ? '78 BPM' : '74 BPM',
                                  color: color,
                                ),
                                const SizedBox(height: 10),
                                _demoMetricCard(
                                  label: _t('AI Status', 'حالة الذكاء'),
                                  value: active
                                      ? _t('Active', 'نشط')
                                      : _t('Ready', 'جاهز'),
                                  color: AppColors.success,
                                ),
                                const SizedBox(height: 10),
                                _demoMetricCard(
                                  label: _t('Report', 'التقرير'),
                                  value: _t('Prepared', 'جاهز'),
                                  color: AppColors.accentDeep,
                                ),
                                const Spacer(),
                                Container(
                                  height: 88,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: dark
                                        ? AppColors.primaryDark.withAlpha(150)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: AppColors.border.withAlpha(120)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: List.generate(18, (bar) {
                                      const values = [
                                        0.20,
                                        0.34,
                                        0.40,
                                        0.54,
                                        0.48,
                                        0.72,
                                        0.26,
                                        0.18,
                                        0.29,
                                        0.44,
                                        0.60,
                                        0.86,
                                        0.50,
                                        0.33,
                                        0.24,
                                        0.28,
                                        0.46,
                                        0.58,
                                      ];
                                      return Expanded(
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 420),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 2),
                                            height: 56 * values[bar] + 8,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  color,
                                                  color.withAlpha(90)
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
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
            ),
          ],
        ),
      ),
    );
  }
}

Widget _demoMetricCard({
  required String label,
  required String value,
  required Color color,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withAlpha(16),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withAlpha(42)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
          ),
        ),
      ],
    ),
  );
}

Widget _demoStatusDot(Color color) {
  return Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class RoleSelectionPage extends StatelessWidget {
  final String username;
  const RoleSelectionPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AppBackdrop(
        dark: dark,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                _t('Choose your workspace', 'اختر مساحة العمل'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: dark ? Colors.white : AppColors.primary,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                _t(
                  'Select the experience that matches the clinical role you want to enter.',
                  'اختر التجربة المناسبة للدور السريري الذي تريد الدخول به.',
                ),
                style: TextStyle(
                  color: dark ? Colors.white70 : AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 20),
              _roleCard(
                icon: Icons.medical_services_outlined,
                title: _t('Doctor workspace', 'مساحة الطبيب'),
                sub: _t(
                    'Command center for patients, analyses, reports, and clinical review',
                    'مركز قيادة للمرضى والتحليلات والتقارير والمراجعة السريرية'),
                color: AppColors.accent,
                onTap: () {
                  final doctor = AppState.currentDoctorProfile;
                  if (doctor == null) {
                    AppState.currentWorkspace = 'role_selection';
                    unawaited(
                        AppState.persistSession(workspace: 'role_selection'));
                    Navigator.push(
                        context,
                        _fadeRoute(
                            const DoctorProfileSetupPage(initialName: '')));
                  } else {
                    ApiService.currentUsername = doctor.name;
                    AppState.currentWorkspace = 'doctor_dashboard';
                    unawaited(AppState.persistSession(
                      username: doctor.name,
                      workspace: 'doctor_dashboard',
                    ));
                    Navigator.push(context,
                        _fadeRoute(DoctorDashboard(username: doctor.name)));
                  }
                },
              ),
              const SizedBox(height: 14),
              _roleCard(
                icon: Icons.favorite_outline,
                title: _t('Patient workspace', 'مساحة المريض'),
                sub: _t(
                    'Personal monitoring, ECG upload, reports, and independent health tracking',
                    'مراقبة شخصية ورفع ECG والتقارير والمتابعة الصحية المستقلة'),
                color: AppColors.success,
                onTap: () {
                  ApiService.currentUsername = username;
                  AppState.currentWorkspace = 'patient_home';
                  unawaited(AppState.persistSession(
                    username: username,
                    workspace: 'patient_home',
                  ));
                  Navigator.push(
                      context, _fadeRoute(PatientHome(username: username)));
                },
              ),
              const SizedBox(height: 14),
              _roleCard(
                icon: Icons.auto_awesome_outlined,
                title: _t('Guest / demo', 'ضيف / عرض'),
                sub: _t(
                    'Explore the analysis workflow and result experience with real ECG processing',
                    'استكشف مسار التحليل وتجربة النتائج مع معالجة ECG حقيقية'),
                color: AppColors.accentDeep,
                onTap: () {
                  Navigator.push(
                    context,
                    _fadeRoute(
                      AnalysisHubPage(
                        api: ApiService(baseUrl: _apiBaseUrl()),
                        roleTitle: _t('Demo Analysis', 'تحليل تجريبي'),
                        roleSubtitle: _t(
                          'Capture, upload, or stream ECG and generate a physician-friendly result page.',
                          'التقاط أو رفع أو بث ECG مع نتيجة منظمة ملائمة للعرض.',
                        ),
                        accentColor: AppColors.accentDeep,
                        sourceLabel: 'Demo',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnalysisHubPage extends StatefulWidget {
  final ApiService api;
  final String roleTitle;
  final String roleSubtitle;
  final Color accentColor;
  final String sourceLabel;
  final AnalysisSessionDraft? presetDraft;

  const AnalysisHubPage({
    super.key,
    required this.api,
    required this.roleTitle,
    required this.roleSubtitle,
    required this.accentColor,
    required this.sourceLabel,
    this.presetDraft,
  });

  @override
  State<AnalysisHubPage> createState() => _AnalysisHubPageState();
}

class _AnalysisHubPageState extends State<AnalysisHubPage> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _doctor;
  late final TextEditingController _notes;
  String _sex = 'Not specified';

  @override
  void initState() {
    super.initState();
    final preset = widget.presetDraft;
    _name = TextEditingController(text: preset?.patientName ?? '');
    _age = TextEditingController(text: preset?.patientAge ?? '');
    _doctor = TextEditingController(text: preset?.doctorName ?? '');
    _notes = TextEditingController(text: preset?.notes ?? '');
    _sex = preset?.patientSex.isNotEmpty == true
        ? preset!.patientSex
        : 'Not specified';
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _doctor.dispose();
    _notes.dispose();
    super.dispose();
  }

  AnalysisSessionDraft _draft(String source) {
    return AnalysisSessionDraft(
      patientName: _name.text.trim(),
      patientAge: _age.text.trim(),
      patientSex: _sex,
      doctorName: _doctor.text.trim(),
      notes: _notes.text.trim(),
      analysisSource: source,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 920;
    final isDemo = widget.sourceLabel.toLowerCase() == 'demo';
    final accent = isDemo ? AppColors.accentDeep : widget.accentColor;
    final workflow = [
      _workflowStage(
        index: '01',
        title: _t('Select source', 'اختيار المصدر'),
        subtitle: _t('Image, upload, or live wearable session.',
            'صورة أو رفع ملفات أو جلسة مباشرة.'),
      ),
      _workflowStage(
        index: '02',
        title: _t('Attach identity', 'إرفاق الهوية'),
        subtitle: _t('Patient and doctor fields travel with the report.',
            'بيانات المريض والطبيب تنتقل مع التقرير.'),
      ),
      _workflowStage(
        index: '03',
        title: _t('Analyze and report', 'التحليل والتقرير'),
        subtitle: _t('Open the AI result and export the PDF.',
            'افتح النتيجة ثم صدّر التقرير PDF.'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roleTitle),
        actions: _topBarActions(context),
      ),
      body: AppBackdrop(
        dark: Theme.of(context).brightness == Brightness.dark,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            AppHeroBanner(
              title: widget.roleTitle,
              subtitle: widget.roleSubtitle,
              icon:
                  isDemo ? Icons.play_circle_outline_rounded : Icons.auto_graph,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, accent],
              ),
            ),
            const SizedBox(height: 16),
            if (isDemo) ...[
              GlassPanel(
                padding: const EdgeInsets.all(18),
                radius: BorderRadius.circular(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.play_lesson_outlined,
                        color: AppColors.accentDeep,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('Demo workspace', 'مساحة العرض'),
                            style: GoogleFonts.sora(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _t(
                              'This guided screen lets you test the ECG pipeline quickly using image capture, WFDB upload, or live monitoring without the doctor dashboard styling.',
                              'هذه الشاشة مخصصة لتجربة خط تحليل ECG بسرعة باستخدام الصورة أو رفع WFDB أو المراقبة المباشرة بدون طابع لوحة الطبيب.',
                            ),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _analysisCard(
              title: _t('Medical workflow', 'المسار الطبي'),
              subtitle: _t(
                'A structured ECG analysis flow from source selection to report export.',
                'مسار منظم لتحليل ECG من اختيار المصدر حتى تصدير التقرير.',
              ),
              child: wide
                  ? Row(
                      children: [
                        for (int i = 0; i < workflow.length; i++) ...[
                          Expanded(child: workflow[i]),
                          if (i != workflow.length - 1)
                            const SizedBox(width: 12),
                        ],
                      ],
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < workflow.length; i++) ...[
                          workflow[i],
                          if (i != workflow.length - 1)
                            const SizedBox(height: 10),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _analysisCard(
              title: _t('Patient and session context', 'بيانات المريض والجلسة'),
              subtitle: _t(
                'These details appear inside the analysis result and report view.',
                'هذه البيانات تظهر داخل نتيجة التحليل والتقرير.',
              ),
              child: Column(
                children: [
                  _formField(_name, _t('Patient name', 'اسم المريض'),
                      Icons.badge_outlined),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _formField(
                            _age, _t('Age', 'العمر'), Icons.cake_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _sex,
                          decoration: InputDecoration(
                            labelText: _t('Sex', 'النوع'),
                            prefixIcon: const Icon(Icons.wc_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Not specified',
                                child: Text('Not specified')),
                            DropdownMenuItem(
                                value: 'Male', child: Text('Male')),
                            DropdownMenuItem(
                                value: 'Female', child: Text('Female')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _sex = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _formField(_doctor, _t('Doctor name', 'اسم الطبيب'),
                      Icons.local_hospital_outlined),
                  const SizedBox(height: 12),
                  _formField(
                    _notes,
                    _t('Clinical notes', 'ملاحظات سريرية'),
                    Icons.edit_note,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _analysisCard(
              title: _t('Choose ECG source', 'اختر مصدر ECG'),
              subtitle: _t(
                'Use the same backend pipeline with image capture, WFDB files, or live wearable streaming.',
                'استخدم نفس خط التحليل مع الصور أو ملفات WFDB أو جلسة جهاز مباشر.',
              ),
              child: Column(
                children: [
                  _analysisActionTile(
                    title: _t('ECG image', 'صورة ECG'),
                    subtitle: _t(
                      'Use camera or gallery with patient context attached.',
                      'استخدم الكاميرا أو المعرض مع إرفاق بيانات المريض.',
                    ),
                    icon: Icons.photo_camera_back_outlined,
                    color: isDemo ? AppColors.accentDeep : AppColors.accent,
                    onTap: () => Navigator.push(
                      context,
                      _fadeRoute(ECGAnalysisPage(
                          api: widget.api, draft: _draft('ECG image'))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _analysisActionTile(
                    title: _t('WFDB file upload', 'رفع ملفات WFDB'),
                    subtitle: _t(
                      'Upload `.hea`, `.dat`, or the full pair. Automatic sibling matching is attempted when possible.',
                      'ارفع `.hea` أو `.dat` أو الزوج كاملًا، مع محاولة مطابقة الملف الشقيق تلقائيًا.',
                    ),
                    icon: Icons.file_present_outlined,
                    color: isDemo ? AppColors.secondary : AppColors.success,
                    onTap: () => Navigator.push(
                      context,
                      _fadeRoute(FileUploadPage(
                          api: widget.api, draft: _draft('WFDB upload'))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _analysisActionTile(
                    title: _t('Live wearable session', 'جلسة جهاز مباشر'),
                    subtitle: _t(
                      'Open the monitoring workstation for ESP32 one-lead streaming.',
                      'افتح منصة المراقبة لجلسات ESP32 أحادية القناة.',
                    ),
                    icon: Icons.monitor_heart_outlined,
                    color: isDemo ? AppColors.primary : AppColors.warning,
                    onTap: () => Navigator.push(
                      context,
                      _fadeRoute(
                        PatientLiveScreen(
                          username: _name.text.trim().isEmpty
                              ? widget.sourceLabel
                              : _name.text.trim(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _analysisCard(
              title: _t('Expected outputs', 'المخرجات المتوقعة'),
              subtitle: _t(
                'Only outputs supported by the active backend pipeline are displayed later.',
                'يتم عرض المخرجات المدعومة فعليًا فقط من الباك إند الحالي.',
              ),
              child: Column(
                children: const [
                  _BulletLine(text: 'Patient-linked analysis context'),
                  _BulletLine(text: 'Real AI-assisted screening result'),
                  _BulletLine(
                      text: 'Waveform preview and computed measurements'),
                  _BulletLine(text: 'PDF export and shareable report output'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _workflowStage({
    required String index,
    required String title,
    required String subtitle,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      radius: BorderRadius.circular(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              index,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accentDeep,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: dark ? Colors.white60 : AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _analysisCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      radius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  color: dark ? Colors.white60 : AppColors.textSecondary,
                  fontSize: 12)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _analysisActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(0),
      radius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withAlpha(28), color.withAlpha(dark ? 12 : 6)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withAlpha(52)),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withAlpha(24),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: dark ? Colors.white60 : AppColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  _t('Open', 'فتح'),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 18, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _formField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: _inputTextStyle(context),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;
  const _BulletLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle, color: AppColors.success, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class DoctorProfileSetupPage extends StatefulWidget {
  final String initialName;
  const DoctorProfileSetupPage({super.key, required this.initialName});

  @override
  State<DoctorProfileSetupPage> createState() => _DoctorProfileSetupPageState();
}

class _DoctorProfileSetupPageState extends State<DoctorProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _specialty =
      TextEditingController(text: 'Cardiology');
  final TextEditingController _clinic =
      TextEditingController(text: 'Heart Clinic');

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _specialty.dispose();
    _clinic.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final doctor = AppState.createDoctor(
      name: _name.text.trim(),
      specialty: _specialty.text.trim(),
      clinic: _clinic.text.trim(),
      phone: _phone.text.trim(),
      email:
          '${_name.text.trim().replaceAll(' ', '.').toLowerCase()}@clinic.com',
      about: 'Cardiac specialist available for follow-ups.',
    );
    ApiService.currentUsername = doctor.name;
    AppState.currentWorkspace = 'doctor_dashboard';
    unawaited(AppState.persistSession(
      username: doctor.name,
      workspace: 'doctor_dashboard',
    ));
    Navigator.pushReplacement(
      context,
      _fadeRoute(DoctorDashboard(username: doctor.name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AppBackdrop(
        dark: dark,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _t('Doctor Profile Setup', 'إعداد ملف الطبيب'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GlassPanel(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _signalChip(Icons.medical_services_outlined,
                              _t('Doctor identity', 'هوية الطبيب')),
                          _signalChip(Icons.schedule_outlined,
                              _t('Follow-up ready', 'جاهز للمتابعة')),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _t('Finalize your clinician profile',
                            'أكمل ملفك كطبيب'),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _t(
                          'This profile is used across patient lists, report headers, and physician review workflows.',
                          'يُستخدم هذا الملف في قوائم المرضى وعناوين التقارير ومسارات المراجعة الطبية.',
                        ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.55,
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 24),
                      _formField(
                        _name,
                        _t('Full Name', 'الاسم الكامل'),
                        Icons.person_outline_rounded,
                        required: true,
                      ),
                      const SizedBox(height: 14),
                      _formField(
                        _specialty,
                        _t('Specialty', 'التخصص'),
                        Icons.medical_services_outlined,
                        required: true,
                      ),
                      const SizedBox(height: 14),
                      _formField(
                        _clinic,
                        _t('Clinic / Hospital', 'العيادة / المستشفى'),
                        Icons.local_hospital_outlined,
                        required: true,
                      ),
                      const SizedBox(height: 14),
                      _formField(
                        _phone,
                        _t('Phone Number', 'رقم الهاتف'),
                        Icons.phone_outlined,
                        required: true,
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: Text(
                            _t('Save & Continue', 'حفظ والمتابعة'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: _inputTextStyle(context),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class DoctorSelectionPage extends StatefulWidget {
  final String username;
  const DoctorSelectionPage({super.key, required this.username});

  @override
  State<DoctorSelectionPage> createState() => _DoctorSelectionPageState();
}

class _DoctorSelectionPageState extends State<DoctorSelectionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    AppState.selectedDoctor = null;
    ApiService.currentUsername = _name.text.trim();
    AppState.currentWorkspace = 'patient_home';
    unawaited(AppState.persistSession(
      username: _name.text.trim(),
      workspace: 'patient_home',
    ));
    Navigator.pushReplacement(
      context,
      _fadeRoute(PatientHome(username: _name.text.trim())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AppBackdrop(
        dark: dark,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _t('Patient Setup', 'إعداد المريض'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GlassPanel(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Create the patient profile', 'أنشئ ملف المريض'),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _t(
                          'Add patient identity now, then continue directly to the patient workspace.',
                          'أدخل بيانات المريض الآن، ثم تابع مباشرة إلى مساحة المريض.',
                        ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.55,
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _signalChip(Icons.favorite_outline,
                              _t('Patient identity', 'هوية المريض')),
                          _signalChip(Icons.arrow_forward_rounded,
                              _t('Direct access', 'دخول مباشر')),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _formField(
                        _name,
                        _t('Full Name', 'الاسم الكامل'),
                        Icons.person_outline_rounded,
                        required: true,
                      ),
                      const SizedBox(height: 14),
                      _formField(
                        _phone,
                        _t('Phone Number', 'رقم الهاتف'),
                        Icons.phone_outlined,
                        required: true,
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: Text(_t('Continue to Patient Workspace',
                              'المتابعة إلى مساحة المريض')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      style: _inputTextStyle(context),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class DoctorDashboard extends StatefulWidget {
  final String username;
  const DoctorDashboard({super.key, required this.username});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final ApiService api = ApiService(baseUrl: _apiBaseUrl());
  late Future<DoctorHomeSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    ApiService.currentUsername = widget.username;
    AppState.currentWorkspace = 'doctor_dashboard';
    unawaited(AppState.persistSession(
      username: widget.username,
      workspace: 'doctor_dashboard',
    ));
    _snapshotFuture = _loadSnapshot();
  }

  void _refreshStats() {
    setState(() => _snapshotFuture = _loadSnapshot());
  }

  Future<DoctorHomeSnapshot> _loadSnapshot() async {
    final stats = await api.getStats();
    final patients = await api.listPatients();
    final appointments = await api.listAppointments();
    final reports = <ReportLibraryEntry>[];
    for (final patient in patients.take(8)) {
      final patientId = patient.id;
      if (patientId == null) continue;
      try {
        final report = await api.getReport(patientId);
        final latestRisk =
            report.riskLevels.isNotEmpty ? report.riskLevels.last : 'No risk';
        final latestBpm =
            report.bpm.isNotEmpty ? '${report.bpm.last} bpm' : 'Unavailable';
        final latestLabel =
            report.labels.isNotEmpty ? report.labels.last : 'No timeline label';
        reports.add(
          ReportLibraryEntry(
            patient: patient,
            report: report,
            latestRisk: latestRisk,
            latestBpm: latestBpm,
            latestLabel: latestLabel,
            latestDate: _safeDateLabel(report.createdAt ?? patient.createdAt),
          ),
        );
      } catch (_) {}
    }
    final profile = AppState.currentDoctorProfile;
    final onboardingComplete = profile != null &&
        profile.name.trim().isNotEmpty &&
        profile.phone.trim().isNotEmpty &&
        profile.specialty.trim().isNotEmpty &&
        profile.clinic.trim().isNotEmpty;
    return DoctorHomeSnapshot(
      stats: stats,
      patients: patients,
      appointments: appointments,
      reports: reports,
      onboardingComplete: onboardingComplete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 980;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Clinical Command Center', 'مركز المتابعة السريري')),
        actions: _topBarActions(context),
      ),
      body: AppBackdrop(
        dark: Theme.of(context).brightness == Brightness.dark,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _doctorHeader(username: widget.username),
            const SizedBox(height: 16),
            FutureBuilder<DoctorHomeSnapshot>(
              future: _snapshotFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 72,
                    child: Center(child: LinearProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _retryCard(
                    message: _t(
                      'Clinical home could not load. Check backend connectivity and retry.',
                      'تعذر تحميل الصفحة السريرية. تحقّق من اتصال الخادم ثم أعد المحاولة.',
                    ),
                    onRetry: _refreshStats,
                  );
                }
                final home = snapshot.data ??
                    DoctorHomeSnapshot(
                      stats:
                          StatsModel(patients: 0, emergencies: 0, messages: 0),
                      patients: [],
                      appointments: [],
                      reports: [],
                      onboardingComplete: false,
                    );
                final stats = home.stats;
                return Column(
                  children: [
                    AppSectionHeader(
                      title: _t('Operational Overview', 'نظرة تشغيلية عامة'),
                      subtitle: _t(
                        'Real-time status across connected patients and screening workflows',
                        'حالة لحظية للمرضى المتصلين ومسارات الفحص الحالية',
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: wide ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.18,
                      children: [
                        AppMetricTile(
                          label: _t('Patients', 'المرضى'),
                          value: stats.patients.toString(),
                          caption: _t('Tracked patient profiles',
                              'ملفات المرضى المتابعة'),
                          accent: AppColors.accent,
                          icon: Icons.people_rounded,
                        ),
                        AppMetricTile(
                          label: _t('Flagged', 'الحالات الحرجة'),
                          value: stats.emergencies.toString(),
                          caption: _t('Priority review queue',
                              'قائمة المراجعة العاجلة'),
                          accent: AppColors.danger,
                          icon: Icons.priority_high_rounded,
                        ),
                        AppMetricTile(
                          label: _t('Messages', 'الرسائل'),
                          value: stats.messages.toString(),
                          caption: _t('Unread communication items',
                              'عناصر التواصل غير المقروءة'),
                          accent: AppColors.success,
                          icon: Icons.chat_bubble_rounded,
                        ),
                        AppMetricTile(
                          label: _t('Workflow', 'العمل السريري'),
                          value: _t('Active', 'نشط'),
                          caption: _t('Analysis and review services online',
                              'خدمات التحليل والمراجعة متاحة'),
                          accent: AppColors.primary,
                          icon: Icons.monitor_heart_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _doctorOnboardingCard(home),
                    const SizedBox(height: 16),
                    _doctorPulsePanel(stats),
                    const SizedBox(height: 16),
                    _doctorRecentStrip(home),
                    const SizedBox(height: 16),
                    _doctorMessagingAiCard(home),
                    const SizedBox(height: 16),
                    _doctorCopilotCard(home),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            AppSectionHeader(
              title: _t('Clinical Workflows', 'مسارات العمل السريرية'),
              subtitle: _t(
                'Launch analysis, review patients, and move into care actions',
                'ابدأ التحليل وراجع المرضى وانتقل لإجراءات المتابعة',
              ),
            ),
            const SizedBox(height: 10),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: Column(children: [
                    _doctorAnalysisCard(),
                    const SizedBox(height: 14),
                    _doctorUploadCard(),
                    const SizedBox(height: 14),
                    _doctorReportsCard(),
                    const SizedBox(height: 14),
                    _doctorRecentReportsCard()
                  ])),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(children: [
                    _doctorCareCard(),
                    const SizedBox(height: 14),
                    _doctorMessagesCard(context),
                    const SizedBox(height: 14),
                    _doctorPatientsCard(),
                    const SizedBox(height: 14),
                    _doctorPriorityPanel(),
                    const SizedBox(height: 14),
                    _doctorAppointmentsCard()
                  ])),
                ],
              )
            else
              Column(
                children: [
                  _doctorAnalysisCard(),
                  const SizedBox(height: 14),
                  _doctorUploadCard(),
                  const SizedBox(height: 14),
                  _doctorReportsCard(),
                  const SizedBox(height: 14),
                  _doctorRecentReportsCard(),
                  const SizedBox(height: 14),
                  _doctorCareCard(),
                  const SizedBox(height: 14),
                  _doctorMessagesCard(context),
                  const SizedBox(height: 14),
                  _doctorPatientsCard(),
                  const SizedBox(height: 14),
                  _doctorPriorityPanel(),
                  const SizedBox(height: 14),
                  _doctorAppointmentsCard(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _doctorHeader({required String username}) {
    final profile = AppState.currentDoctorProfile;
    final specialty = profile?.specialty ?? 'Cardiac Specialist';
    final clinic = profile?.clinic ?? 'Medical Center';
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: AppGradients.hero,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.medical_services, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  specialty,
                  style: TextStyle(
                      color: dark ? Colors.white70 : AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  clinic,
                  style: TextStyle(
                      color: dark ? Colors.white54 : AppColors.textSecondary,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(38),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _t('Monitoring Active', 'المتابعة نشطة'),
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorAnalysisCard() {
    return _dashboardCard(
      title: _t('Unified Analysis Hub', 'بوابة التحليل الموحدة'),
      subtitle: _t('Patient context + image + files + live routing',
          'بيانات المريض مع الصورة والملفات والبث المباشر'),
      icon: Icons.auto_graph,
      color: AppColors.accent,
      onTap: () => Navigator.push(
        context,
        _scaleRoute(
          AnalysisHubPage(
            api: api,
            roleTitle: _t('Doctor Analysis Hub', 'بوابة تحليل الطبيب'),
            roleSubtitle: _t(
              'Launch physician-grade ECG analysis with patient metadata and a stronger report-style result.',
              'ابدأ تحليل ECG احترافي مع بيانات المريض ونتيجة أقوى على نمط التقرير.',
            ),
            accentColor: AppColors.accent,
            sourceLabel: 'Doctor',
            presetDraft: AnalysisSessionDraft(
              patientName: '',
              patientAge: '',
              patientSex: 'Not specified',
              doctorName: widget.username,
              notes: '',
              analysisSource: 'Doctor hub',
            ),
          ),
        ),
      ),
    );
  }

  Widget _doctorUploadCard() {
    return _dashboardCard(
      title: _t('Signal Upload (.hea/.dat)', 'رفع الإشارة (.hea/.dat)'),
      subtitle:
          _t('Direct WFDB upload shortcut', 'اختصار مباشر لرفع سجلات WFDB'),
      icon: Icons.upload_file,
      color: AppColors.success,
      onTap: () => Navigator.push(
        context,
        _scaleRoute(
          FileUploadPage(
            api: api,
            draft: AnalysisSessionDraft(
              patientName: '',
              patientAge: '',
              patientSex: 'Not specified',
              doctorName: widget.username,
              notes: '',
              analysisSource: 'Doctor WFDB upload',
            ),
          ),
        ),
      ),
    );
  }

  Widget _doctorReportsCard() {
    return _dashboardCard(
      title: _t('Report Center', 'مركز التقارير'),
      subtitle: _t('Clinical summaries, PDF exports, and review packages',
          'ملخصات سريرية وتصدير PDF وحزم مراجعة'),
      icon: Icons.analytics_outlined,
      color: AppColors.warning,
      onTap: () => Navigator.push(
        context,
        _scaleRoute(const DoctorReportsPage()),
      ),
    );
  }

  Widget _doctorRecentReportsCard() {
    return FutureBuilder<DoctorHomeSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        final reports = snapshot.data?.reports ?? const <ReportLibraryEntry>[];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: _t('Recent reports', 'أحدث التقارير'),
                subtitle: _t(
                  'Latest report outputs generated from connected patient files.',
                  'أحدث التقارير الناتجة من ملفات المرضى المتصلة.',
                ),
                action: TextButton(
                  onPressed: () => Navigator.push(
                      context, _scaleRoute(const DoctorReportsPage())),
                  child: Text(_t('Open center', 'فتح المركز')),
                ),
              ),
              const SizedBox(height: 10),
              if (reports.isEmpty)
                _emptyState(_t(
                    'No reports generated yet.', 'لا توجد تقارير مولدة بعد.'))
              else
                ...reports.take(3).map(
                      (entry) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _riskColor(entry.latestRisk).withAlpha(12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color:
                                  _riskColor(entry.latestRisk).withAlpha(38)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  _riskColor(entry.latestRisk).withAlpha(24),
                              child: Icon(Icons.description_outlined,
                                  color: _riskColor(entry.latestRisk)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.patient.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary)),
                                  const SizedBox(height: 3),
                                  Text(
                                      '${entry.latestRisk} • ${entry.latestBpm}',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary)),
                                  const SizedBox(height: 2),
                                  Text(entry.latestDate,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _doctorCopilotCard(DoctorHomeSnapshot home) {
    final brief = _buildDoctorCopilotBrief(home);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: _t('AI Doctor Copilot', 'المساعد الذكي للطبيب'),
            subtitle: _t(
              'A quick AI-generated briefing from the currently loaded reports, patients, and appointments.',
              'ملخص ذكي سريع مبني على التقارير والمرضى والمواعيد المحمّلة حاليًا.',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: brief.color.withAlpha(12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: brief.color.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brief.headline,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: brief.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  brief.summary,
                  style: const TextStyle(
                      color: AppColors.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...brief.priorities.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 10, color: brief.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorMessagingAiCard(DoctorHomeSnapshot home) {
    final brief = _buildMessagingOpsBrief(home);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: _t('AI Messaging Summary', 'ملخص المراسلة الذكي'),
            subtitle: _t(
              'AI reads the current dashboard workload to suggest the right communication pace.',
              'يلخّص الذكاء الاصطناعي ضغط المراسلات الحالي لاقتراح وتيرة المتابعة المناسبة.',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: brief.color.withAlpha(12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: brief.color.withAlpha(35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brief.headline,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: brief.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  brief.summary,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: 'Queue',
                  value: brief.queueLabel,
                  caption: _t('Communication pressure', 'ضغط المراسلات'),
                  accent: brief.color,
                  icon: Icons.mark_unread_chat_alt_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppMetricTile(
                  label: 'Response',
                  value: brief.responseLabel,
                  caption: _t('Suggested pace', 'الوتيرة المقترحة'),
                  accent: AppColors.primary,
                  icon: Icons.reply_all_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...brief.bullets.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 10, color: brief.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorCareCard() {
    return _dashboardCard(
      title: _t('Care Coordination', 'تنسيق المتابعة'),
      subtitle: _t('Visits, follow-up planning, and patient coordination',
          'الزيارات وخطة المتابعة وتنسيق الرعاية'),
      icon: Icons.event_available,
      color: AppColors.accent,
      onTap: () => Navigator.push(
        context,
        _scaleRoute(const DoctorAppointmentsPage()),
      ),
    );
  }

  Widget _doctorMessagesCard(BuildContext context) {
    return _dashboardCard(
      title: _t('Messages', 'الرسائل'),
      subtitle: _t('Doctor-patient chat', 'محادثة الطبيب والمريض'),
      icon: Icons.chat_bubble_outline,
      color: AppColors.success,
      onTap: () async {
        final picked = await Navigator.push<PatientModel>(
          context,
          _fadeRoute<PatientModel>(PatientPickerPage(api: api)),
        );
        if (!context.mounted) return;
        if (picked != null) {
          Navigator.push(
            context,
            _scaleRoute(
              DoctorChatPage(
                patientId: picked.id ?? 0,
                patientName: picked.name,
              ),
            ),
          );
        }
      },
    );
  }

  Widget _doctorPatientsCard() {
    return _dashboardCard(
      title: _t('Patients', 'المرضى'),
      subtitle: _t('Registry, assignment, and review access',
          'السجل والتعيين والوصول للمراجعة'),
      icon: Icons.people_alt_outlined,
      color: AppColors.primary,
      onTap: () => Navigator.push(
        context,
        _scaleRoute(DoctorPatientsPage(api: api)),
      ),
    );
  }

  Widget _doctorAppointmentsCard() {
    return _dashboardCard(
      title: _t('Appointments', 'المواعيد'),
      subtitle: _t('Open the scheduling queue and follow-up calendar',
          'افتح قائمة المواعيد وجدول المتابعة'),
      icon: Icons.event_note_outlined,
      color: AppColors.secondary,
      onTap: () => Navigator.push(
        context,
        _scaleRoute(const DoctorAppointmentsPage()),
      ),
    );
  }

  Widget _doctorOnboardingCard(DoctorHomeSnapshot home) {
    final profile = AppState.currentDoctorProfile;
    final completed = home.onboardingComplete;
    final missing = <String>[
      if ((profile?.phone ?? '').trim().isEmpty) _t('Phone', 'الهاتف'),
      if ((profile?.specialty ?? '').trim().isEmpty) _t('Specialty', 'التخصص'),
      if ((profile?.clinic ?? '').trim().isEmpty) _t('Clinic', 'العيادة'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completed
            ? AppColors.success.withAlpha(10)
            : AppColors.warning.withAlpha(10),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: completed
              ? AppColors.success.withAlpha(40)
              : AppColors.warning.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: completed
                ? AppColors.success.withAlpha(18)
                : AppColors.warning.withAlpha(20),
            child: Icon(
              completed
                  ? Icons.verified_user_outlined
                  : Icons.assignment_ind_outlined,
              color: completed ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completed
                      ? _t(
                          'Doctor onboarding complete', 'تم إكمال إعداد الطبيب')
                      : _t('Finish doctor setup', 'أكمل إعداد الطبيب'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  completed
                      ? _t(
                          'Your workspace is ready for patient assignment, messaging, and reporting.',
                          'مساحة العمل جاهزة لإسناد المرضى والمراسلة والتقارير.')
                      : _t(
                          'Add the missing professional fields so reports and follow-up screens look complete: ${missing.join(", ")}.',
                          'أضف الحقول المهنية الناقصة ليظهر التقرير والمتابعة بشكل مكتمل: ${missing.join("، ")}.'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              _fadeRoute(DoctorProfileSetupPage(
                  initialName: profile?.name ?? widget.username)),
            ),
            child:
                Text(completed ? _t('Edit', 'تعديل') : _t('Complete', 'إكمال')),
          ),
        ],
      ),
    );
  }

  Widget _doctorRecentStrip(DoctorHomeSnapshot home) {
    final nextAppointment =
        home.appointments.isNotEmpty ? home.appointments.first : null;
    final latestReport = home.reports.isNotEmpty ? home.reports.first : null;
    return Row(
      children: [
        Expanded(
          child: AppMetricTile(
            label: _t('Next visit', 'أقرب موعد'),
            value: nextAppointment?.when ?? _t('No schedule', 'لا يوجد'),
            caption: _t('Upcoming follow-up slot', 'موعد المتابعة القادم'),
            accent: AppColors.secondary,
            icon: Icons.event_available_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppMetricTile(
            label: _t('Latest report', 'آخر تقرير'),
            value: latestReport?.patient.name ?? _t('No reports', 'لا يوجد'),
            caption: latestReport?.latestRisk ??
                _t('No generated files yet', 'لا توجد ملفات مولدة بعد'),
            accent: latestReport == null
                ? AppColors.accent
                : _riskColor(latestReport.latestRisk),
            icon: Icons.description_rounded,
          ),
        ),
      ],
    );
  }

  Widget _doctorPulsePanel(StatsModel stats) {
    final trend = <double>[
      stats.patients.toDouble().clamp(0, 100).toDouble(),
      (stats.patients - stats.emergencies).toDouble().clamp(0, 100).toDouble(),
      (stats.messages + 3).toDouble().clamp(0, 100).toDouble(),
      (stats.emergencies * 2 + 4).toDouble().clamp(0, 100).toDouble(),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: _t('Clinical pulse', 'نبض العمل السريري'),
            subtitle: _t(
              'A compact operational trend view for today’s workload.',
              'عرض مختصر لاتجاه ضغط العمل السريري اليوم.',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
              height: 150, child: CustomPaint(painter: TrendPainter(trend))),
        ],
      ),
    );
  }

  Widget _doctorPriorityPanel() {
    final rows = [
      (
        _t('Flagged screenings', 'الفحوصات المعلّمة'),
        _t('Review today', 'راجِع اليوم'),
        AppColors.danger
      ),
      (
        _t('New reports', 'التقارير الجديدة'),
        _t('Export ready', 'جاهزة للتصدير'),
        AppColors.success
      ),
      (
        _t('Patient follow-up', 'متابعة المرضى'),
        _t('Pending scheduling', 'بانتظار الجدولة'),
        AppColors.accent
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: _t('Priority review', 'أولوية المراجعة'),
            subtitle: _t(
              'Current doctor-facing actions that require attention.',
              'الإجراءات الحالية التي تتطلب انتباه الطبيب.',
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: row.$3.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: row.$3.withAlpha(42)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: row.$3, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        row.$1,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      row.$2,
                      style:
                          TextStyle(color: row.$3, fontWeight: FontWeight.w700),
                    ),
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

class AppBackdrop extends StatelessWidget {
  final Widget child;
  final bool dark;

  const AppBackdrop({
    super.key,
    required this.child,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: dark ? AppGradients.darkBackdrop : AppGradients.lightHero,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _orb(
              size: 220,
              color: AppColors.accent.withAlpha(dark ? 60 : 45),
            ),
          ),
          Positioned(
            left: -70,
            bottom: 80,
            child: _orb(
              size: 180,
              color: AppColors.info.withAlpha(dark ? 45 : 28),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                lineColor:
                    (dark ? Colors.white : AppColors.primary).withAlpha(18),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _orb({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withAlpha(0)],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color lineColor;

  _GridPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const gap = 36.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? radius;
  final VoidCallback? onTap;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final panel = ClipRRect(
      borderRadius: radius ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: dark ? AppColors.glassDark : AppColors.glass,
            borderRadius: radius ?? BorderRadius.circular(24),
            border: Border.all(
              color:
                  dark ? AppColors.borderDark : AppColors.border.withAlpha(210),
            ),
            boxShadow: AppShadows.soft,
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return panel;
    return InkWell(
      onTap: onTap,
      borderRadius: radius ?? BorderRadius.circular(24),
      child: panel,
    );
  }
}

class SecondaryPageShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final List<Widget>? actions;

  const SecondaryPageShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AppBackdrop(
      dark: dark,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GlassPanel(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: AppGradients.hero,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppShadows.lift,
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(spacing: 10, runSpacing: 10, children: actions!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

Widget glassListCard({
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  EdgeInsetsGeometry margin = EdgeInsets.zero,
}) {
  return Padding(
    padding: margin,
    child: GlassPanel(
      padding: padding,
      radius: BorderRadius.circular(AppRadii.lg),
      child: child,
    ),
  );
}

class GlassNavBar extends StatelessWidget {
  final int index;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onSelected;

  const GlassNavBar({
    super.key,
    required this.index,
    required this.destinations,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        radius: BorderRadius.circular(28),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: onSelected,
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 70,
          destinations: destinations,
        ),
      ),
    );
  }
}

class DoctorReportsPage extends StatefulWidget {
  const DoctorReportsPage({super.key});

  @override
  State<DoctorReportsPage> createState() => _DoctorReportsPageState();
}

class _DoctorReportsPageState extends State<DoctorReportsPage> {
  final ApiService _api = ApiService(baseUrl: _apiBaseUrl());
  late Future<List<ReportLibraryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ReportLibraryEntry>> _load() async {
    final patients = await _api.listPatients();
    final entries = <ReportLibraryEntry>[];
    for (final patient in patients) {
      if (patient.id == null) continue;
      try {
        final report = await _api.getReport(patient.id!);
        entries.add(
          ReportLibraryEntry(
            patient: patient,
            report: report,
            latestRisk: report.riskLevels.isNotEmpty
                ? report.riskLevels.last
                : 'No risk',
            latestBpm: report.bpm.isNotEmpty
                ? '${report.bpm.last} bpm'
                : 'Unavailable',
            latestLabel:
                report.labels.isNotEmpty ? report.labels.last : 'No label',
            latestDate: _safeDateLabel(report.createdAt ?? patient.createdAt),
          ),
        );
      } catch (_) {}
    }
    entries.sort((a, b) => b.latestDate.compareTo(a.latestDate));
    return entries;
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Doctor Reports', 'تقارير الطبيب')),
        actions: _topBarActions(context),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<ReportLibraryEntry>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _retryCard(
                    message: _t(
                      'Report center could not load. Check patient/report connectivity and retry.',
                      'تعذر تحميل مركز التقارير. تحقّق من اتصال المرضى والتقارير ثم أعد المحاولة.',
                    ),
                    onRetry: _refresh,
                  ),
                ],
              );
            }
            final items = snapshot.data ?? const <ReportLibraryEntry>[];
            final criticalCount = items
                .where((e) => e.latestRisk.toLowerCase().contains('high'))
                .length;
            final mediumCount = items
                .where((e) => e.latestRisk.toLowerCase().contains('medium'))
                .length;
            final avgBpm = items.isEmpty
                ? '--'
                : (items
                            .map((e) =>
                                int.tryParse(e.latestBpm.split(' ').first) ?? 0)
                            .reduce((a, b) => a + b) ~/
                        items.length)
                    .toString();
            return SecondaryPageShell(
              title: _t('Doctor Reports', 'تقارير الطبيب'),
              subtitle: _t(
                  'Clinical summaries, flagged cases, and physician review packages',
                  'ملخصات سريرية وحالات مميزة وحزم مراجعة للطبيب'),
              icon: Icons.analytics_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _metricCard(_t('Reports', 'التقارير'),
                            '${items.length}', Icons.description_outlined)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _metricCard(_t('Critical', 'الحالات الحرجة'),
                            '$criticalCount', Icons.warning_amber)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _metricCard(
                            _t('Avg BPM', 'متوسط النبض'),
                            avgBpm == '--' ? '--' : '$avgBpm bpm',
                            Icons.favorite)),
                  ],
                ),
                const SizedBox(height: 16),
                glassListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title: _t('AI Queue Summary', 'ملخص الطابور الذكي'),
                        subtitle: _t(
                          'Automatic prioritization from the currently stored report library.',
                          'ترتيب أولوية تلقائي من مكتبة التقارير المحفوظة حاليًا.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: criticalCount > 0
                              ? AppColors.danger.withAlpha(12)
                              : mediumCount > 0
                                  ? AppColors.warning.withAlpha(12)
                                  : AppColors.success.withAlpha(12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: criticalCount > 0
                                ? AppColors.danger.withAlpha(38)
                                : mediumCount > 0
                                    ? AppColors.warning.withAlpha(38)
                                    : AppColors.success.withAlpha(38),
                          ),
                        ),
                        child: Text(
                          criticalCount > 0
                              ? 'AI copilot flagged $criticalCount high-risk report(s) for immediate review.'
                              : mediumCount > 0
                                  ? 'AI copilot found $mediumCount medium-priority report(s) that should be compared next.'
                                  : 'AI copilot did not detect a high-priority report queue in the stored summaries.',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...[
                        'Stored reports: ${items.length}',
                        'High-risk queue: $criticalCount',
                        'Medium-risk queue: $mediumCount',
                        if (avgBpm != '--')
                          'Average stored BPM across latest reports: $avgBpm bpm',
                      ].map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(Icons.circle,
                                    size: 10, color: AppColors.accent),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                glassListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title: _t('Report queue', 'قائمة التقارير'),
                        subtitle: _t(
                            'Latest generated report summaries across patient profiles',
                            'أحدث ملخصات التقارير المولدة عبر ملفات المرضى'),
                      ),
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        _emptyState(_t('No reports available yet.',
                            'لا توجد تقارير متاحة بعد.'))
                      else
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.2),
                            1: FlexColumnWidth(1.2),
                            2: FlexColumnWidth(1.0),
                            3: FlexColumnWidth(0.9),
                          },
                          children: [
                            AnalysisResultPage._tableHeader(
                                'Patient', 'Latest finding', 'Risk / Date'),
                            ...List.generate(items.length.clamp(0, 6), (i) {
                              final e = items[i];
                              return AnalysisResultPage._tableRow(
                                e.patient.name,
                                e.latestLabel,
                                '${e.latestRisk} • ${e.latestDate}',
                                i.isEven,
                                _riskColor(e.latestRisk),
                              );
                            }),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...items.map((e) => _reportCard(e)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      radius: BorderRadius.circular(AppRadii.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _reportCard(ReportLibraryEntry entry) {
    final color = _riskColor(entry.latestRisk);
    return glassListCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(38),
            child: Icon(Icons.description_outlined, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.patient.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.latestRisk} • ${entry.latestBpm} • ${entry.latestLabel}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.latestDate,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  _fadeRoute(
                    PatientReportsPage(patient: entry.patient),
                  ),
                ),
                child: Text(_t('Open', 'فتح')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ECGAnalysisPage extends StatefulWidget {
  final ApiService api;
  final AnalysisSessionDraft? draft;
  const ECGAnalysisPage({super.key, required this.api, this.draft});

  @override
  State<ECGAnalysisPage> createState() => _ECGAnalysisPageState();
}

class _ECGAnalysisPageState extends State<ECGAnalysisPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  String? _error;
  int _analysisStage = 0;
  String _analysisLabel = '';

  void _setAnalysisStage(int stage, String label) {
    if (!mounted) return;
    setState(() {
      _analysisStage = stage;
      _analysisLabel = label;
    });
  }

  List<PipelineStage> get _imageStages => [
        PipelineStage(
          title: _t('Image acquired', 'تم التقاط الصورة'),
          subtitle: _t('ECG image is attached to the session.',
              'تم إرفاق صورة ECG بالجلسة.'),
          done: _analysisStage > 0,
          active: _analysisStage == 1,
        ),
        PipelineStage(
          title: _t('Upload package', 'رفع الحزمة'),
          subtitle: _t('Sending image input to the backend.',
              'إرسال الصورة إلى الخادم.'),
          done: _analysisStage > 1,
          active: _analysisStage == 2,
        ),
        PipelineStage(
          title: _t('Signal preparation', 'تجهيز الإشارة'),
          subtitle: _t('Preparing image-derived ECG traces.',
              'تجهيز آثار ECG المشتقة من الصورة.'),
          done: _analysisStage > 2,
          active: _analysisStage == 3,
        ),
        PipelineStage(
          title: _t('AI inference', 'استدلال النموذج'),
          subtitle: _t('Running the ECG decision pipeline.',
              'تشغيل مسار قرار ECG الذكي.'),
          done: _analysisStage > 3,
          active: _analysisStage == 4,
        ),
        PipelineStage(
          title: _t('Result assembly', 'تجهيز النتيجة'),
          subtitle: _t('Building the physician-ready output.',
              'تجهيز النتيجة الجاهزة للمراجعة.'),
          done: _analysisStage > 4,
          active: _analysisStage == 5,
        ),
      ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
          _isAnalyzing = true;
          _error = null;
          _analysisStage = 1;
          _analysisLabel = _t(
              'ECG image captured successfully.', 'تم التقاط صورة ECG بنجاح.');
        });

        await Future<void>.delayed(const Duration(milliseconds: 180));
        _setAnalysisStage(
            2,
            _t('Uploading ECG image to the backend...',
                'جارٍ رفع صورة ECG إلى الخادم...'));
        await Future<void>.delayed(const Duration(milliseconds: 220));
        _setAnalysisStage(
            3,
            _t('Preparing image-based signal traces...',
                'جارٍ تجهيز الإشارات المشتقة من الصورة...'));
        await Future<void>.delayed(const Duration(milliseconds: 220));
        _setAnalysisStage(
            4,
            _t('Running AI inference and clinical scoring...',
                'جارٍ تشغيل النموذج وحساب الدرجة السريرية...'));
        final result = await widget.api.analyzeImage(picked);
        _setAnalysisStage(
            5,
            _t('Assembling the final ECG report view...',
                'جارٍ تجهيز عرض تقرير ECG النهائي...'));
        await Future<void>.delayed(const Duration(milliseconds: 160));

        if (!mounted) return;
        setState(() {
          _isAnalyzing = false;
          _analysisStage = 0;
          _analysisLabel = '';
        });
        Navigator.push(
          context,
          _fadeRoute(AnalysisResultPage(result: result, draft: widget.draft)),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _error = e.toString();
        _analysisStage = 0;
        _analysisLabel = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('ECG Image Analysis', 'تحليل صورة رسم القلب')),
        actions: _topBarActions(context),
      ),
      body: SecondaryPageShell(
        title: _t('ECG Image Workstation', 'منصة صورة ECG'),
        subtitle: _t(
            'Capture or upload a clear ECG image, then send it to the AI analysis pipeline',
            'التقط أو ارفع صورة ECG واضحة ثم أرسلها إلى مسار التحليل الذكي'),
        icon: Icons.photo_camera_back_outlined,
        children: [
          glassListCard(
            child: Column(
              children: [
                Container(
                  height: 320,
                  decoration: BoxDecoration(
                    color: dark
                        ? AppColors.surfaceDark.withAlpha(160)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: kIsWeb
                              ? Image.network(_selectedImage!.path,
                                  fit: BoxFit.cover)
                              : Image.file(File(_selectedImage!.path),
                                  fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 70,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              _t('Upload ECG Image', 'ارفع صورة رسم القلب'),
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppMetricTile(
                        label: _t('Source', 'المصدر'),
                        value: _selectedImage == null
                            ? _t('Pending', 'بانتظار')
                            : _t('Loaded', 'تم التحميل'),
                        caption: _t(
                            'Current image input state', 'حالة الصورة الحالية'),
                        accent: AppColors.accent,
                        icon: Icons.image_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppMetricTile(
                        label: _t('Pipeline', 'المسار'),
                        value: _isAnalyzing
                            ? _t('Processing', 'جاري التحليل')
                            : _t('Ready', 'جاهز'),
                        caption: _t('Image AI analysis readiness',
                            'جاهزية تحليل الصورة'),
                        accent: _isAnalyzing
                            ? AppColors.warning
                            : AppColors.success,
                        icon: Icons.auto_graph_rounded,
                      ),
                    ),
                  ],
                ),
                if (_isAnalyzing) ...[
                  const SizedBox(height: 16),
                  _pipelineProgressCard(
                    context,
                    headline:
                        _t('Live analysis pipeline', 'مسار التحليل اللحظي'),
                    status: _analysisLabel,
                    stages: _imageStages,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text('Error: $_error',
                      style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: Text(_t('Capture from Camera', 'التقاط بالكاميرا')),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.image),
                    label: Text(_t('Select from Gallery', 'اختيار من المعرض')),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pipelineProgressCard(
    BuildContext context, {
    required String headline,
    required String status,
    required List<PipelineStage> stages,
  }) {
    final progress = stages.isEmpty
        ? 0.0
        : (_analysisStage / stages.length).clamp(0, 1).toDouble();
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      radius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.memory_rounded,
                    color: AppColors.accentDeep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 14),
          ...stages.map(
            (stage) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: stage.done
                          ? AppColors.success.withAlpha(30)
                          : stage.active
                              ? AppColors.accentSoft
                              : AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: stage.done
                            ? AppColors.success
                            : stage.active
                                ? AppColors.accent
                                : AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      stage.done
                          ? Icons.check_rounded
                          : stage.active
                              ? Icons.more_horiz_rounded
                              : Icons.circle_outlined,
                      size: 14,
                      color: stage.done
                          ? AppColors.success
                          : stage.active
                              ? AppColors.accentDeep
                              : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.title,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stage.subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  final ApiService _api = ApiService(baseUrl: _apiBaseUrl());
  late Future<List<AppointmentModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.listAppointments();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _api.listAppointments();
    });
  }

  Future<void> _add() async {
    final picked = await Navigator.push<PatientModel>(
      context,
      _fadeRoute<PatientModel>(PatientPickerPage(api: _api)),
    );
    if (!mounted) return;
    if (picked != null) {
      final created = await Navigator.push<bool>(
        context,
        _fadeRoute<bool>(AddAppointmentPage(patient: picked, api: _api)),
      );
      if (created == true) {
        await _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Appointments', 'المواعيد')),
        actions: _topBarActions(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AppointmentModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _retryCard(
                    message:
                        _t('Failed to load appointments', 'فشل تحميل المواعيد'),
                    onRetry: _refresh,
                  ),
                ],
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(18),
                children: const [
                  AppHeroBanner(
                    title: 'Appointments',
                    subtitle:
                        'Doctor scheduling, follow-up visits, and care coordination',
                    icon: Icons.event_available,
                    gradient: AppGradients.hero,
                  ),
                  SizedBox(height: 16),
                  Center(child: Text('No appointments yet.')),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const AppHeroBanner(
                  title: 'Appointments',
                  subtitle:
                      'Doctor scheduling, follow-up visits, and care coordination',
                  icon: Icons.event_available,
                  gradient: AppGradients.hero,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title: _t('Scheduling table', 'جدول المواعيد'),
                        subtitle: _t('Current doctor-side appointment queue',
                            'قائمة المواعيد الحالية للطبيب'),
                      ),
                      const SizedBox(height: 12),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(1.8),
                          2: FlexColumnWidth(1.0),
                        },
                        children: [
                          AnalysisResultPage._tableHeader(
                              'Doctor', 'When', 'Status'),
                          ...List.generate(items.length, (i) {
                            final item = items[i];
                            final color = item.status == 'Confirmed'
                                ? AppColors.success
                                : AppColors.warning;
                            return AnalysisResultPage._tableRow(
                              item.doctorName,
                              item.when,
                              item.status,
                              i.isEven,
                              color,
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...items.map((item) {
                  final status = item.status;
                  final color = status == 'Confirmed'
                      ? AppColors.success
                      : AppColors.warning;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withAlpha(31),
                            child: Icon(Icons.event, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.doctorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(item.when,
                                    style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withAlpha(26),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class DoctorChatPage extends StatefulWidget {
  final int patientId;
  final String patientName;
  const DoctorChatPage(
      {super.key, required this.patientId, required this.patientName});

  @override
  State<DoctorChatPage> createState() => _DoctorChatPageState();
}

class _DoctorChatPageState extends State<DoctorChatPage> {
  final ApiService _api = ApiService(baseUrl: _apiBaseUrl());
  final TextEditingController _input = TextEditingController();
  late Future<List<MessageModel>> _messagesFuture;
  late Future<MessageSummaryModel> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _api.listMessagesForPatient(widget.patientId);
    _summaryFuture = _api.getMessageSummary(widget.patientId);
  }

  Future<void> _refresh() async {
    setState(() {
      _messagesFuture = _api.listMessagesForPatient(widget.patientId);
      _summaryFuture = _api.getMessageSummary(widget.patientId);
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    await _api.sendMessage(
      patientId: widget.patientId,
      text: text,
      senderRole: 'doctor',
      senderName: 'Doctor',
    );
    _input.clear();
    await _refresh();
  }

  void _applySuggestion(String suggestion) {
    setState(() {
      _input.text = suggestion;
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
    });
  }

  Widget _backendSummaryCard() {
    return FutureBuilder<MessageSummaryModel>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft,
            ),
            child: const LinearProgressIndicator(),
          );
        }
        if (!snapshot.hasData) return const SizedBox.shrink();
        final summary = snapshot.data!;
        final color = summary.urgency == 'high'
            ? AppColors.danger
            : summary.urgency == 'medium'
                ? AppColors.warning
                : AppColors.success;
        return Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: color.withAlpha(40)),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology_alt_outlined, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      summary.headline,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary.summary,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_t('Messages', 'الرسائل')} - ${widget.patientName}'),
        actions: _topBarActions(context),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.accent.withAlpha(20),
                  child:
                      const Icon(Icons.person_outline, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _t('Doctor-patient secure channel',
                            'قناة تواصل آمنة بين الطبيب والمريض'),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _backendSummaryCard(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<MessageModel>>(
                future: _messagesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: _retryCard(
                        message: _t('Failed to load messages',
                            'ÙØ´Ù„ ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø±Ø³Ø§Ø¦Ù„'),
                        onRetry: _refresh,
                      ),
                    );
                  }
                  final items = snapshot.data ?? [];
                  final guide = _buildChatAiGuide(items, doctorView: true);
                  if (items.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                      children: [
                        _chatAiGuideCard(
                          context,
                          guide: guide,
                          onSuggestionTap: _applySuggestion,
                        ),
                        const SizedBox(height: 40),
                        Column(
                          children: [
                            const Icon(Icons.chat_bubble_outline,
                                size: 36, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(_t('No messages yet.',
                                'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø±Ø³Ø§Ø¦Ù„ Ø¨Ø¹Ø¯.')),
                          ],
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _chatAiGuideCard(
                          context,
                          guide: guide,
                          onSuggestionTap: _applySuggestion,
                        );
                      }
                      final item = items[i - 1];
                      final fromDoctor = item.senderRole == 'doctor';
                      return Align(
                        alignment: fromDoctor
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 320),
                          decoration: BoxDecoration(
                            color: fromDoctor
                                ? AppColors.accentSoft
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppShadows.soft,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.senderName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(item.text),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  item.createdAt
                                      .split('T')
                                      .last
                                      .substring(0, 5),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.border)),
              boxShadow: AppShadows.soft,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      style: _inputTextStyle(context),
                      decoration: InputDecoration(
                        hintText: _t('Type a message', 'اكتب رسالة'),
                        prefixIcon: const Icon(Icons.chat_bubble_outline),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(54, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PatientChatPage extends StatefulWidget {
  final String username;
  const PatientChatPage({super.key, required this.username});

  @override
  State<PatientChatPage> createState() => _PatientChatPageState();
}

class _PatientChatPageState extends State<PatientChatPage> {
  final ApiService _api = ApiService(baseUrl: _apiBaseUrl());
  final TextEditingController _input = TextEditingController();
  late Future<List<MessageModel>> _messagesFuture;
  Future<MessageSummaryModel>? _summaryFuture;
  late int _patientId;

  @override
  void initState() {
    super.initState();
    _patientId = 0;
    _messagesFuture = Future.value([]);
  }

  Future<void> _refresh() async {
    setState(() {
      _messagesFuture = _api.listMessagesForPatient(_patientId);
      _summaryFuture =
          _patientId == 0 ? null : _api.getMessageSummary(_patientId);
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    if (_patientId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a patient first.')),
      );
      return;
    }
    await _api.sendMessage(
      patientId: _patientId,
      text: text,
      senderRole: 'patient',
      senderName: widget.username,
    );
    _input.clear();
    await _refresh();
  }

  void _applySuggestion(String suggestion) {
    setState(() {
      _input.text = suggestion;
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
    });
  }

  Widget _backendSummaryCard() {
    if (_summaryFuture == null) return const SizedBox.shrink();
    return FutureBuilder<MessageSummaryModel>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft,
            ),
            child: const LinearProgressIndicator(),
          );
        }
        if (!snapshot.hasData) return const SizedBox.shrink();
        final summary = snapshot.data!;
        final color = summary.urgency == 'high'
            ? AppColors.danger
            : summary.urgency == 'medium'
                ? AppColors.warning
                : AppColors.success;
        return Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: color.withAlpha(40)),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      summary.headline,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary.summary,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Messages', 'الرسائل')),
        actions: _topBarActions(context),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.accent.withAlpha(20),
                      child: const Icon(Icons.person_search,
                          color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _patientId == 0
                            ? _t('No linked patient selected yet',
                                'لم يتم اختيار مريض بعد')
                            : _t('Patient linked for messaging',
                                'تم ربط المريض للمحادثة'),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_search),
                    label: Text(_t('Select Patient', 'اختيار المريض')),
                    onPressed: () async {
                      final picked = await Navigator.push<PatientModel>(
                        context,
                        _fadeRoute<PatientModel>(PatientPickerPage(api: _api)),
                      );
                      if (picked != null) {
                        setState(() {
                          _patientId = picked.id ?? 0;
                          _messagesFuture =
                              _api.listMessagesForPatient(_patientId);
                          _summaryFuture = _api.getMessageSummary(_patientId);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          _backendSummaryCard(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<MessageModel>>(
                future: _messagesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: _retryCard(
                        message: _t('Failed to load messages',
                            'ÙØ´Ù„ ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø±Ø³Ø§Ø¦Ù„'),
                        onRetry: _refresh,
                      ),
                    );
                  }
                  final items = snapshot.data ?? [];
                  final guide = _buildChatAiGuide(items, doctorView: false);
                  if (items.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                      children: [
                        _chatAiGuideCard(
                          context,
                          guide: guide,
                          onSuggestionTap: _applySuggestion,
                        ),
                        const SizedBox(height: 40),
                        Column(
                          children: [
                            const Icon(Icons.chat_bubble_outline,
                                size: 36, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(_t('No messages yet.',
                                'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø±Ø³Ø§Ø¦Ù„ Ø¨Ø¹Ø¯.')),
                          ],
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _chatAiGuideCard(
                          context,
                          guide: guide,
                          onSuggestionTap: _applySuggestion,
                        );
                      }
                      final item = items[i - 1];
                      final fromPatient = item.senderRole == 'patient';
                      return Align(
                        alignment: fromPatient
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 320),
                          decoration: BoxDecoration(
                            color: fromPatient
                                ? AppColors.accentSoft
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppShadows.soft,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.senderName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(item.text),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  item.createdAt
                                      .split('T')
                                      .last
                                      .substring(0, 5),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.border)),
              boxShadow: AppShadows.soft,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      style: _inputTextStyle(context),
                      decoration: InputDecoration(
                        hintText: _t('Type a message', 'اكتب رسالة'),
                        prefixIcon: const Icon(Icons.chat_bubble_outline),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(54, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FileUploadPage extends StatefulWidget {
  final ApiService api;
  final AnalysisSessionDraft? draft;
  const FileUploadPage({super.key, required this.api, this.draft});

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  List<PlatformFile> selected = [];
  bool loading = false;
  String? err;
  String? _pairError;
  Map<String, List<PlatformFile>> _groups = {};
  WFDBConversionResult? _conversionResult;
  int _analysisStage = 0;
  String _analysisLabel = '';

  bool _isImageFile(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.webp');
  }

  bool _isSignalFile(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.hea') ||
        lower.endsWith('.dat') ||
        lower.endsWith('.csv') ||
        lower.endsWith('.wav');
  }

  bool _isWfdbFile(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.hea') || lower.endsWith('.dat');
  }

  void _validatePairs() {
    final groups = <String, List<PlatformFile>>{};
    String? validationError;

    for (final f in selected) {
      final name = f.name.toLowerCase();
      if (_isImageFile(name)) {
        continue;
      }
      if (!_isSignalFile(name)) {
        validationError = _t(
            'Supported files: image ECG, .hea, .dat, .csv, .wav',
            'الصيغ المدعومة: صور ECG و .hea و .dat و .csv و .wav');
        continue;
      }
      if (!_isWfdbFile(name)) {
        continue;
      }
      final base =
          f.name.replaceAll(RegExp(r'\.(hea|dat)$', caseSensitive: false), '');
      groups.putIfAbsent(base, () => []).add(f);
    }

    setState(() {
      _groups = groups;
      _pairError = validationError;
    });
  }

  Future<List<PlatformFile>> _expandWithMatchingFiles(
      List<PlatformFile> input) async {
    if (kIsWeb) return input;

    final expanded = <PlatformFile>[...input];
    final existingPaths =
        expanded.map((f) => f.path?.toLowerCase()).whereType<String>().toSet();

    for (final file in input) {
      final path = file.path;
      if (path == null) continue;

      final lowerName = file.name.toLowerCase();
      if (!_isWfdbFile(lowerName)) continue;

      final siblingPath = lowerName.endsWith('.hea')
          ? path.replaceAll(RegExp(r'\.hea$', caseSensitive: false), '.dat')
          : path.replaceAll(RegExp(r'\.dat$', caseSensitive: false), '.hea');

      final siblingKey = siblingPath.toLowerCase();
      if (existingPaths.contains(siblingKey)) continue;

      final siblingFile = File(siblingPath);
      if (!await siblingFile.exists()) continue;

      expanded.add(
        PlatformFile(
          name: siblingFile.uri.pathSegments.isNotEmpty
              ? siblingFile.uri.pathSegments.last
              : siblingPath.split(Platform.pathSeparator).last,
          path: siblingPath,
          size: await siblingFile.length(),
        ),
      );
      existingPaths.add(siblingKey);
    }

    return expanded;
  }

  Future<void> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: kIsWeb ? FileType.custom : FileType.any,
        allowedExtensions: kIsWeb
            ? ['hea', 'dat', 'csv', 'wav', 'png', 'jpg', 'jpeg', 'bmp', 'webp']
            : null,
        withData: true,
      );
      if (result != null) {
        setState(() {
          selected = result.files;
          _conversionResult = null;
        });
        _validatePairs();
      }
    } catch (e) {
      setState(() => err = e.toString());
    }
  }

  Future<void> analyze() async {
    if (selected.isEmpty) return;
    if (_pairError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_pairError!)),
      );
      return;
    }
    setState(() {
      loading = true;
      err = null;
      _conversionResult = null;
      _analysisStage = 1;
      _analysisLabel = _t('Validating the selected ECG package...',
          'جارٍ التحقق من حزمة ECG المحددة...');
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 140));
      _setUploadStage(
          2,
          _t('Matching related WFDB files and metadata...',
              'جارٍ مطابقة ملفات WFDB والبيانات المرتبطة...'));
      final preparedFiles = await _expandWithMatchingFiles(selected);
      final imageFiles =
          preparedFiles.where((f) => _isImageFile(f.name)).toList();
      final signalFiles =
          preparedFiles.where((f) => _isSignalFile(f.name)).toList();
      late final AnalysisResult result;
      if (imageFiles.isNotEmpty &&
          signalFiles.isEmpty &&
          imageFiles.length == 1) {
        _setUploadStage(
            3,
            _t('Uploading ECG image for analysis...',
                'جارٍ رفع صورة ECG للتحليل...'));
        await Future<void>.delayed(const Duration(milliseconds: 180));
        _setUploadStage(
            4,
            _t('Preparing image-derived ECG signal...',
                'جارٍ تجهيز إشارة ECG المشتقة من الصورة...'));
        await Future<void>.delayed(const Duration(milliseconds: 220));
        _setUploadStage(
            5,
            _t('Running AI screening inference...',
                'جارٍ تشغيل استدلال الذكاء الاصطناعي...'));
        result = await widget.api.analyzePlatformFile(imageFiles.first);
      } else if (signalFiles.isNotEmpty) {
        _setUploadStage(
            3,
            _t('Uploading signal package to the ECG backend...',
                'جارٍ رفع حزمة الإشارة إلى الخادم...'));
        await Future<void>.delayed(const Duration(milliseconds: 180));
        _setUploadStage(
            4,
            _t('Extracting waveform features and quality metrics...',
                'جارٍ استخراج خصائص الموجة ومؤشرات الجودة...'));
        await Future<void>.delayed(const Duration(milliseconds: 220));
        _setUploadStage(
            5,
            _t('Running AI screening inference...',
                'جارٍ تشغيل استدلال الذكاء الاصطناعي...'));
        result = await widget.api.analyzeFiles(signalFiles);
      } else if (imageFiles.isNotEmpty) {
        _setUploadStage(3,
            _t('Uploading ECG image package...', 'جارٍ رفع حزمة صورة ECG...'));
        await Future<void>.delayed(const Duration(milliseconds: 180));
        _setUploadStage(
            4,
            _t('Preparing image-derived ECG signal...',
                'جارٍ تجهيز إشارة ECG المشتقة من الصورة...'));
        await Future<void>.delayed(const Duration(milliseconds: 220));
        _setUploadStage(
            5,
            _t('Running AI screening inference...',
                'جارٍ تشغيل استدلال الذكاء الاصطناعي...'));
        result = await widget.api.analyzePlatformFile(imageFiles.first);
      } else {
        throw Exception('No supported ECG file was selected');
      }
      _setUploadStage(
          6,
          _t('Building the final report-ready package...',
              'جارٍ تجهيز الحزمة النهائية الجاهزة للتقرير...'));
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (!mounted) return;
      setState(() {
        loading = false;
        _analysisStage = 0;
        _analysisLabel = '';
      });
      Navigator.push(
        context,
        _fadeRoute(AnalysisResultPage(result: result, draft: widget.draft)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        err = e.toString();
        _analysisStage = 0;
        _analysisLabel = '';
      });
    }
  }

  void _setUploadStage(int stage, String label) {
    if (!mounted) return;
    setState(() {
      _analysisStage = stage;
      _analysisLabel = label;
    });
  }

  List<PipelineStage> get _uploadStages => [
        PipelineStage(
          title: _t('Validation', 'التحقق'),
          subtitle: _t(
              'Checking supported ECG formats.', 'التحقق من صيغ ECG المدعومة.'),
          done: _analysisStage > 1,
          active: _analysisStage == 1,
        ),
        PipelineStage(
          title: _t('Pairing check', 'فحص الاقتران'),
          subtitle: _t('Matching sibling WFDB files when available.',
              'مطابقة ملفات WFDB الشقيقة عند توفرها.'),
          done: _analysisStage > 2,
          active: _analysisStage == 2,
        ),
        PipelineStage(
          title: _t('Upload', 'الرفع'),
          subtitle: _t('Sending the ECG package to the backend.',
              'إرسال الحزمة إلى الخادم.'),
          done: _analysisStage > 3,
          active: _analysisStage == 3,
        ),
        PipelineStage(
          title: _t('Feature prep', 'تجهيز الخصائص'),
          subtitle: _t('Preparing traces, quality, and derived metrics.',
              'تجهيز الإشارات والجودة والقياسات المشتقة.'),
          done: _analysisStage > 4,
          active: _analysisStage == 4,
        ),
        PipelineStage(
          title: _t('AI inference', 'استدلال النموذج'),
          subtitle: _t('Running ECG screening decision logic.',
              'تشغيل منطق القرار الخاص بفحص ECG.'),
          done: _analysisStage > 5,
          active: _analysisStage == 5,
        ),
        PipelineStage(
          title: _t('Result package', 'الحزمة النهائية'),
          subtitle: _t('Preparing the analysis result screen.',
              'تجهيز شاشة نتيجة التحليل.'),
          done: _analysisStage > 6,
          active: _analysisStage == 6,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final imageSelected =
        selected.length == 1 && _isImageFile(selected.first.name);
    final signalItems = selected.where((f) => _isSignalFile(f.name)).toList();
    final wfdbItems = selected.where((f) => _isWfdbFile(f.name)).toList();
    final imageItems = selected.where((f) => _isImageFile(f.name)).toList();
    final supportedCount = signalItems.length + imageItems.length;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Analyze ECG', 'تحليل ECG')),
        actions: _topBarActions(context),
      ),
      body: AppBackdrop(
        dark: dark,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            GlassPanel(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('ECG Upload Workstation', 'منصة رفع ECG'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t(
                      'Choose an ECG image, a single `.hea` or `.dat`, a full WFDB pair, or a direct `.csv` / `.wav` signal file. The app tries to attach the missing WFDB sibling automatically on desktop.',
                      'اختر صورة ECG أو ملف `.hea` أو `.dat` منفردًا أو زوج WFDB كاملًا أو ملف إشارة مباشر `.csv` / `.wav`. يحاول التطبيق إرفاق ملف WFDB الشقيق تلقائيًا على سطح المكتب.',
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.55,
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _signalChip(
                          Icons.image_outlined, _t('Image ECG', 'صورة ECG')),
                      _signalChip(Icons.multiline_chart_rounded,
                          _t('WFDB pair', 'زوج WFDB')),
                      _signalChip(Icons.graphic_eq_rounded,
                          _t('CSV / WAV', 'CSV / WAV')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _uploadSection(
              title: _t('Source selection', 'اختيار المصدر'),
              subtitle: _t(
                'The application accepts any one supported item and attempts automatic WFDB matching when possible.',
                'التطبيق يقبل أي عنصر مدعوم منفردًا ويحاول مطابقة WFDB تلقائيًا عند الإمكان.',
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pickFiles,
                          icon: const Icon(Icons.folder_open,
                              color: Colors.white),
                          label: Text(
                              _t('Choose from device', 'اختيار من الجهاز')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (!kIsWeb) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Cloud picker is available on web')),
                              );
                              return;
                            }
                            pickFiles();
                          },
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: Text(_t('From cloud', 'من السحابة')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppMetricTile(
                          label: _t('Selected', 'المحدد'),
                          value: '$supportedCount',
                          caption:
                              _t('Supported ECG items', 'عدد العناصر المدعومة'),
                          accent: AppColors.accent,
                          icon: Icons.inventory_2_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppMetricTile(
                          label: _t('WFDB files', 'ملفات WFDB'),
                          value: '${wfdbItems.length}',
                          caption: _t('Current paired-record files in queue',
                              'عدد ملفات WFDB الموجودة بالطابور'),
                          accent: AppColors.success,
                          icon: Icons.multiline_chart_rounded,
                        ),
                      ),
                    ],
                  ),
                  if (imageSelected) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: loading
                            ? null
                            : () async {
                                setState(() {
                                  loading = true;
                                  err = null;
                                });
                                try {
                                  final converted = await widget.api
                                      .convertImageToWfdb(selected.first);
                                  if (!mounted) return;
                                  final opened = await launchUrlString(
                                    converted.downloadUrl,
                                    webOnlyWindowName: '_blank',
                                  );
                                  setState(() {
                                    loading = false;
                                    _conversionResult = converted;
                                  });
                                  if (!mounted) return;
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        opened
                                            ? 'WFDB bundle created and download opened.'
                                            : 'WFDB bundle created successfully.',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  setState(() {
                                    loading = false;
                                    err = e.toString();
                                  });
                                }
                              },
                        icon: const Icon(Icons.transform_outlined),
                        label: Text(
                          loading
                              ? _t('Converting...', 'جارٍ التحويل...')
                              : _t('Convert image to HEA/DAT',
                                  'تحويل الصورة إلى HEA/DAT'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _uploadSection(
              title: _t('Validation and readiness', 'التحقق والجاهزية'),
              subtitle: _t(
                'Review the selected package before sending it to the ECG AI pipeline.',
                'راجع الحزمة المحددة قبل إرسالها إلى نموذج ECG.',
              ),
              child: Column(
                children: [
                  _statusLine(
                    _t('Image input', 'مدخل الصورة'),
                    imageItems.isNotEmpty
                        ? _t('Ready', 'جاهز')
                        : _t('Not selected', 'غير محدد'),
                    imageItems.isNotEmpty ? AppColors.success : Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  _statusLine(
                    _t('Signal input', 'مدخل الإشارة'),
                    signalItems.isNotEmpty
                        ? _t('Ready', 'جاهز')
                        : _t('Not selected', 'غير محدد'),
                    signalItems.isNotEmpty ? AppColors.success : Colors.grey,
                  ),
                  if (signalItems.any((f) =>
                      f.name.toLowerCase().endsWith('.csv') ||
                      f.name.toLowerCase().endsWith('.wav'))) ...[
                    const SizedBox(height: 10),
                    _statusLine(
                      _t('Direct signal mode', 'وضع الإشارة المباشر'),
                      _t('CSV/WAV can be analyzed without WFDB pairing',
                          'يمكن تحليل CSV/WAV بدون زوج WFDB'),
                      AppColors.accent,
                    ),
                  ],
                  if (_pairError != null) ...[
                    const SizedBox(height: 10),
                    _statusLine(_t('Validation', 'التحقق'), _pairError!,
                        AppColors.danger),
                  ],
                  if (err != null) ...[
                    const SizedBox(height: 10),
                    _statusLine(_t('Server', 'الخادم'), err!, AppColors.danger),
                  ],
                  if (loading) ...[
                    const SizedBox(height: 14),
                    _pipelineProgressCard(context),
                  ],
                ],
              ),
            ),
            if (_conversionResult != null) ...[
              const SizedBox(height: 16),
              _uploadSection(
                title: _t('WFDB conversion package', 'حزمة تحويل WFDB'),
                subtitle: _t(
                  'The backend generated a downloadable HEA/DAT package from the image input.',
                  'أنشأ الباك إند حزمة HEA/DAT قابلة للتنزيل من الصورة.',
                ),
                child: Column(
                  children: [
                    _dataTableRow('Record ID', _conversionResult!.recordId),
                    _dataTableRow('HEA File', _conversionResult!.heaFileName),
                    _dataTableRow('DAT File', _conversionResult!.datFileName),
                    _dataTableRow('ZIP Bundle', _conversionResult!.zipFileName),
                    _dataTableRow(
                        'Output Folder', _conversionResult!.outputDir),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await launchUrlString(
                            _conversionResult!.downloadUrl,
                            webOnlyWindowName: '_blank',
                          );
                        },
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text('Download HEA/DAT ZIP'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (selected.isNotEmpty)
              _uploadSection(
                title: _t('Selected items', 'العناصر المحددة'),
                subtitle: _t(
                  'Preview the package before running AI analysis.',
                  'راجع الحزمة قبل تشغيل التحليل.',
                ),
                child: Column(
                  children: [
                    if (imageItems.isNotEmpty)
                      ...imageItems.map(
                        (file) => _selectedFileCard(
                          file.name,
                          _t('ECG image source', 'مصدر صورة ECG'),
                          AppColors.accent,
                          Icons.image_outlined,
                        ),
                      ),
                    if (_groups.isNotEmpty)
                      ..._groups.entries.map((entry) {
                        final files = entry.value;
                        final hasHea = files
                            .any((f) => f.name.toLowerCase().endsWith('.hea'));
                        final hasDat = files
                            .any((f) => f.name.toLowerCase().endsWith('.dat'));
                        final color = (hasHea && hasDat)
                            ? AppColors.success
                            : AppColors.warning;
                        final subtitle = hasHea && hasDat
                            ? _t('Complete WFDB pair detected',
                                'تم اكتشاف زوج WFDB كامل')
                            : _t(
                                'Single file selected, auto-match will be attempted',
                                'تم اختيار ملف منفرد وسيتم محاولة المطابقة تلقائيًا');
                        return _selectedFileCard(
                          entry.key,
                          subtitle,
                          color,
                          Icons.multiline_chart_rounded,
                          chips: files.map((f) => f.name).toList(),
                        );
                      }),
                    ...signalItems
                        .where((f) =>
                            f.name.toLowerCase().endsWith('.csv') ||
                            f.name.toLowerCase().endsWith('.wav'))
                        .map(
                          (file) => _selectedFileCard(
                            file.name,
                            _t('Direct signal file ready for analysis',
                                'ملف إشارة مباشر جاهز للتحليل'),
                            AppColors.accent,
                            Icons.graphic_eq_rounded,
                          ),
                        ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : analyze,
                        icon:
                            const Icon(Icons.auto_awesome, color: Colors.white),
                        label: Text(
                          loading
                              ? _t('Analyzing...', 'جارٍ التحليل...')
                              : _t('Run AI analysis', 'تشغيل التحليل'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              _uploadSection(
                title: _t('No ECG selected yet', 'لم يتم اختيار ECG بعد'),
                subtitle: _t(
                  'Choose a file or image to begin the medical analysis flow.',
                  'اختر ملفًا أو صورة لبدء مسار التحليل.',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      _t('No files selected', 'لا توجد ملفات محددة'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _uploadSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      radius: BorderRadius.circular(AppRadii.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _statusLine(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedFileCard(
    String title,
    String subtitle,
    Color color,
    IconData icon, {
    List<String> chips = const [],
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark.withAlpha(170)
            : Colors.white.withAlpha(170),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withAlpha(190)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map((chip) => Chip(label: Text(chip))).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dataTableRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _pipelineProgressCard(BuildContext context) {
    final progress = _uploadStages.isEmpty
        ? 0.0
        : (_analysisStage / _uploadStages.length).clamp(0, 1).toDouble();
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      radius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.alt_route_rounded,
                    color: AppColors.accentDeep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('ECG processing pipeline', 'مسار معالجة ECG'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _analysisLabel,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 14),
          ..._uploadStages.map(
            (stage) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    stage.done
                        ? Icons.check_circle_rounded
                        : stage.active
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: stage.done
                        ? AppColors.success
                        : stage.active
                            ? AppColors.accent
                            : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.title,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stage.subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnalysisResultPage extends StatelessWidget {
  final AnalysisResult result;
  final AnalysisSessionDraft? draft;
  const AnalysisResultPage({super.key, required this.result, this.draft});

  @override
  Widget build(BuildContext context) {
    final api = ApiService(baseUrl: _apiBaseUrl());
    final aiBundle = _buildAiInsightBundle(result);
    final confidencePct = (result.confidence * 100).toStringAsFixed(1);
    final qrs = result.measurements['qrs_duration']?.value;
    final qtc = result.measurements['qtc']?.value;
    final pr = result.measurements['pr_interval']?.value;
    final rr = result.measurements['rr_interval']?.value;
    final st = result.measurements['st_deviation']?.value;
    final sdnn = result.measurements['sdnn']?.value;
    final rmssd = result.measurements['rmssd']?.value;
    final pnn50 = result.measurements['pnn50']?.value;
    final source = draft?.analysisSource ?? 'Direct analysis';
    final patientName = draft?.patientName.trim().isNotEmpty == true
        ? draft!.patientName
        : 'Unspecified patient';
    final doctorName = draft?.doctorName.trim().isNotEmpty == true
        ? draft!.doctorName
        : 'Not assigned';
    final identity = draft?.patientIdentityLabel ?? 'Session only';
    final reviewLabel = result.riskLevel == 'High'
        ? 'Priority review'
        : result.riskLevel == 'Medium'
            ? 'Monitor closely'
            : 'Routine review';
    final measurementRows = result.measurements.values
        .where((m) => m.value != null)
        .map(
          (m) => _ReportRow(
            m.name,
            '${m.value!.toStringAsFixed(1)} ${m.unit ?? ''}'.trim(),
            m.source,
          ),
        )
        .toList();

    final primaryRows = [
      _ReportRow(
          'Analysis ID',
          result.analysisId.isEmpty ? 'Unavailable' : result.analysisId,
          'Stored backend record'),
      _ReportRow(
          'Recording ID',
          result.recordingId.isEmpty ? 'Unavailable' : result.recordingId,
          'Input record identifier'),
      _ReportRow(
          'Classification',
          result.classification.isEmpty
              ? 'Not available'
              : result.classification,
          'AI-assisted output'),
      _ReportRow('AI Risk Level', result.riskLevel, 'Screening priority'),
      _ReportRow('Analysis Confidence', '$confidencePct%',
          'Reliability of this ECG screening session'),
      _ReportRow('Estimated Heart Rate', '${result.bpm} bpm',
          'Derived display metric'),
      _ReportRow('Regional Pattern', result.region, 'Localization output'),
      _ReportRow('Signal Quality', result.signalQualityLabel ?? 'Unavailable',
          'Backend quality estimate'),
      _ReportRow(
          'Model Version',
          result.modelVersion.isEmpty ? 'Unavailable' : result.modelVersion,
          'Loaded bundle'),
      _ReportRow('Threshold', result.threshold.toStringAsFixed(3),
          'Decision threshold'),
    ];

    final operationalRows = [
      _ReportRow('Signal Source', source, 'Image / file / live stream'),
      _ReportRow('Patient Identifier', identity, 'Attached session context'),
      _ReportRow('Assigned Doctor', doctorName, 'Care owner'),
      _ReportRow('Recommendation Count', '${result.recommendations.length}',
          'Generated action prompts'),
      _ReportRow(
          'Active Coil Targets',
          result.activeCoils.isEmpty ? '0' : result.activeCoils.join(', '),
          'Prototype actuation map'),
    ];
    final snapshotRows = [
      _ReportRow(
          'Screening Status',
          result.classification.isEmpty
              ? 'AI-assisted screening complete'
              : result.classification,
          'Primary AI summary'),
      _ReportRow('Review Priority', reviewLabel, 'Presentation posture'),
      _ReportRow(
          'Heart Rhythm Signal',
          result.riskLevel == 'High'
              ? 'Needs urgent physician review'
              : result.riskLevel == 'Medium'
                  ? 'Monitor and compare with context'
                  : 'Lower screening concern',
          'Risk-linked review cue'),
      _ReportRow(
          'Report Readiness',
          result.analysisId.isEmpty
              ? 'Session summary only'
              : 'PDF-ready analysis record',
          'Export capability'),
    ];
    final summaryTiles = <AppMetricTile>[
      AppMetricTile(
        label: 'Risk',
        value: result.riskLevel,
        caption: 'Model-derived screening level',
        accent: result.riskColor,
        icon: Icons.flag_rounded,
      ),
      AppMetricTile(
        label: 'Confidence',
        value: '$confidencePct%',
        caption: 'Analysis reliability from backend support checks',
        accent: AppColors.accent,
        icon: Icons.analytics_rounded,
      ),
      AppMetricTile(
        label: 'Heart Rate',
        value: '${result.bpm} bpm',
        caption: 'Derived session metric',
        accent: AppColors.success,
        icon: Icons.favorite_rounded,
      ),
      AppMetricTile(
        label: 'Signal Quality',
        value: result.signalQualityLabel ?? 'Unavailable',
        caption: 'Current backend quality estimate',
        accent: AppColors.primary,
        icon: Icons.graphic_eq_rounded,
      ),
    ];
    final dynamicTiles = <AppMetricTile>[];
    if (qtc != null) {
      final qtcAccent =
          qtc >= 470 || qtc <= 330 ? AppColors.danger : AppColors.accent;
      dynamicTiles.add(
        AppMetricTile(
          label: 'QTc',
          value: '${qtc.toStringAsFixed(0)} ms',
          caption: qtcAccent == AppColors.danger
              ? 'Outlying repolarization estimate'
              : 'Corrected QT estimate',
          accent: qtcAccent,
          icon: Icons.timelapse_rounded,
        ),
      );
    }
    if (st != null) {
      final stAccent = st.abs() >= 0.2 ? AppColors.danger : AppColors.success;
      dynamicTiles.add(
        AppMetricTile(
          label: 'ST Shift',
          value: st.toStringAsFixed(2),
          caption: stAccent == AppColors.danger
              ? 'Noticeable ST deviation estimate'
              : 'Minimal ST deviation',
          accent: stAccent,
          icon: Icons.show_chart_rounded,
        ),
      );
    }
    if (qrs != null) {
      final qrsAccent = qrs >= 120 ? AppColors.warning : AppColors.primary;
      dynamicTiles.add(
        AppMetricTile(
          label: 'QRS',
          value: '${qrs.toStringAsFixed(0)} ms',
          caption: qrsAccent == AppColors.warning
              ? 'Widened depolarization window'
              : 'Depolarization duration estimate',
          accent: qrsAccent,
          icon: Icons.square_foot_rounded,
        ),
      );
    }
    if (rr != null) {
      dynamicTiles.add(
        AppMetricTile(
          label: 'RR Interval',
          value: '${rr.toStringAsFixed(0)} ms',
          caption: 'Beat-to-beat interval from detected peaks',
          accent: AppColors.accentDeep,
          icon: Icons.swap_horiz_rounded,
        ),
      );
    }
    if (sdnn != null) {
      final accent = sdnn >= 120 ? AppColors.warning : AppColors.success;
      dynamicTiles.add(
        AppMetricTile(
          label: 'SDNN',
          value: '${sdnn.toStringAsFixed(0)} ms',
          caption: accent == AppColors.warning
              ? 'Higher rhythm variability'
              : 'Short-term rhythm variability',
          accent: accent,
          icon: Icons.multiline_chart_rounded,
        ),
      );
    }
    if (rmssd != null) {
      dynamicTiles.add(
        AppMetricTile(
          label: 'RMSSD',
          value: '${rmssd.toStringAsFixed(0)} ms',
          caption: 'Beat-to-beat variability estimate',
          accent: AppColors.success,
          icon: Icons.insights_rounded,
        ),
      );
    }
    if (pnn50 != null) {
      dynamicTiles.add(
        AppMetricTile(
          label: 'pNN50',
          value: '${pnn50.toStringAsFixed(0)}%',
          caption: 'RR interval variability proportion',
          accent: AppColors.primary,
          icon: Icons.percent_rounded,
        ),
      );
    }
    if (pr != null) {
      dynamicTiles.add(
        AppMetricTile(
          label: 'PR',
          value: '${pr.toStringAsFixed(0)} ms',
          caption: 'Atrioventricular conduction estimate',
          accent: AppColors.accent,
          icon: Icons.route_rounded,
        ),
      );
    }
    final visibleTiles = [
      ...summaryTiles,
      ...dynamicTiles.take(4),
    ];
    final headlineMetrics = [
      _headlineMetric('Risk Level', result.riskLevel, result.riskColor),
      _headlineMetric('Confidence', '$confidencePct%', Colors.white),
      _headlineMetric('Estimated BPM', '${result.bpm}', Colors.white),
      _headlineMetric('Review', reviewLabel, Colors.white),
      if (qtc != null)
        _headlineMetric('QTc', '${qtc.toStringAsFixed(0)} ms', Colors.white),
      if (st != null)
        _headlineMetric('ST Shift', st.toStringAsFixed(2), Colors.white),
      if (qrs != null)
        _headlineMetric('QRS', '${qrs.toStringAsFixed(0)} ms', Colors.white),
      if (sdnn != null)
        _headlineMetric('SDNN', '${sdnn.toStringAsFixed(0)} ms', Colors.white),
    ];
    final caseFingerprint = [
      if (qtc != null) 'QTc ${qtc.toStringAsFixed(0)}',
      if (st != null) 'ST ${st.toStringAsFixed(2)}',
      if (qrs != null) 'QRS ${qrs.toStringAsFixed(0)}',
      if (rr != null) 'RR ${rr.toStringAsFixed(0)}',
      if (sdnn != null) 'SDNN ${sdnn.toStringAsFixed(0)}',
    ].join(' • ');

    final englishCaseSummary = _buildEnglishCaseSummary(
      result: result,
      bpm: result.bpm.toDouble(),
      qtc: qtc,
      qrs: qrs,
      st: st,
      source: source,
    );
    final arabicCaseSummary = _buildArabicCaseSummaryClean(
      result: result,
      bpm: result.bpm.toDouble(),
      qtc: qtc,
      qrs: qrs,
      st: st,
      source: source,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('ECG Screening Report'),
        actions: _topBarActions(context),
      ),
      body: AppBackdrop(
        dark: Theme.of(context).brightness == Brightness.dark,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.accentDeep],
                ),
                borderRadius: BorderRadius.circular(AppRadii.lg),
                boxShadow: AppShadows.lift,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppState.projectName.toUpperCase(),
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    patientName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Source: $source',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (caseFingerprint.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      caseFingerprint,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: headlineMetrics,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width >= 760 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.18,
              children: visibleTiles,
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'Clinical Command Board',
              subtitle:
                  'Report-style triage overview aligned with the physician-ready PDF layout',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statusStrip(
                      'Triage Status', aiBundle.triage, aiBundle.triageColor),
                  const SizedBox(height: 10),
                  _statusStrip('Source & Session', '$source • $reviewLabel',
                      AppColors.primary),
                  const SizedBox(height: 10),
                  _statusStrip(
                      'Signal & Rhythm',
                      '${result.signalQualityLabel ?? 'Unavailable'} • ${result.rhythmLabel}',
                      AppColors.accent),
                  const SizedBox(height: 12),
                  _infoBlock('Clinical summary', englishCaseSummary),
                  const SizedBox(height: 10),
                  _infoBlock('Arabic summary', arabicCaseSummary),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'AI Copilot Summary',
              subtitle:
                  'Clinician-facing interpretation generated from model outputs and computed ECG measurements',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statusStrip('Triage', aiBundle.triage, aiBundle.triageColor),
                  const SizedBox(height: 10),
                  _statusStrip('Confidence Context', aiBundle.confidenceSummary,
                      AppColors.accent),
                  const SizedBox(height: 12),
                  _infoBlock('Clinician Summary', aiBundle.clinicianSummary),
                  const SizedBox(height: 10),
                  _infoBlock('Signal Quality Context', aiBundle.qualitySummary),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'Patient-Friendly Explanation',
              subtitle:
                  'Plain-language explanation that stays aligned with the currently available ECG pipeline outputs',
              child: _infoBlock('What this means', aiBundle.patientSummary),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'AI Watchlist',
              subtitle:
                  'Model-derived review points highlighted from the current result',
              child: Column(
                children: [
                  ...aiBundle.watchItems.map(
                      (item) => _bulletInfoRow(item, aiBundle.triageColor)),
                  const SizedBox(height: 8),
                  ...aiBundle.nextSteps
                      .map((item) => _bulletInfoRow(item, AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'Case Summary / Bilingual',
              subtitle:
                  'Short bilingual summary generated from the current ECG screening result',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoBlock('English summary', englishCaseSummary),
                  const SizedBox(height: 10),
                  _infoBlock('Arabic summary', arabicCaseSummary),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ReportActionPanel(
              api: api,
              analysisId: result.analysisId,
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'Clinical Snapshot',
              subtitle:
                  'Fast summary table for the current ECG screening session',
              child: _reportTable(snapshotRows, highlight: result.riskColor),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'Analysis summary',
              subtitle:
                  'Primary result status and data provenance for this ECG session',
              child: Column(
                children: [
                  _statusStrip(
                    'Screening status',
                    result.classification.isEmpty
                        ? 'AI-assisted screening complete'
                        : result.classification,
                    result.riskColor,
                  ),
                  const SizedBox(height: 10),
                  _statusStrip(
                    'Signal readiness',
                    result.signalQualityLabel ?? 'Unavailable',
                    AppColors.accent,
                  ),
                  const SizedBox(height: 10),
                  _statusStrip('Processing source', source, AppColors.success),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'Patient & Session Context',
              subtitle: 'Identity fields attached to the generated result',
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.15),
                  1: FlexColumnWidth(1.85),
                },
                children: [
                  _contextRow('Patient', patientName),
                  _contextRow('Identity', identity),
                  _contextRow('Doctor', doctorName),
                  _contextRow(
                      'Notes',
                      draft?.notes.trim().isNotEmpty == true
                          ? draft!.notes
                          : 'No session notes'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'Primary Analysis Table',
              subtitle:
                  'Core screening outputs available from the current pipeline',
              child: _reportTable(primaryRows, highlight: result.riskColor),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'Operational Mapping',
              subtitle: 'Session routing and device logic linked to the result',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reportTable(operationalRows, highlight: AppColors.accent),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Localized Coil Map',
                          style: GoogleFonts.sora(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CoilArrayWidget(active: result.activeCoils),
                        const SizedBox(height: 10),
                        Text(
                          result.activeCoils.isEmpty
                              ? 'No activation suggested for the current screening output.'
                              : 'Active targets: ${result.activeCoils.join(', ')}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (result.waveform.isNotEmpty)
              _sectionCard(
                title: 'ECG visualization',
                subtitle:
                    'Rendered from the backend graph payload of the analyzed ECG segment',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: AppMetricTile._miniStat('Duration view',
                                '${result.waveform.length} pts')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: AppMetricTile._miniStat(
                                'Scale', 'Medical grid')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: AppMetricTile._miniStat(
                                'Region', result.region)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 220,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                              child: CustomPaint(painter: GridPainter())),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: ECGPainter(
                                  result.waveform.take(900).toList()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (result.waveform.isNotEmpty) const SizedBox(height: 14),
            if (result.waveform.length > 2)
              _sectionCard(
                title: 'Clinical visualizations',
                subtitle:
                    'Compact trend inspection derived from the analyzed waveform payload',
                child: Column(
                  children: [
                    SizedBox(
                      height: 170,
                      child: CustomPaint(
                        painter: TrendPainter(
                          result.waveform
                              .take(120)
                              .map((e) => e.abs())
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Trend preview uses analyzed waveform magnitudes for visual inspection only.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            if (result.waveform.length > 2) const SizedBox(height: 14),
            if (measurementRows.isNotEmpty)
              _sectionCard(
                title: 'Key measurements',
                subtitle:
                    'Only values currently computed by the backend are shown',
                child: _reportTable(
                  measurementRows,
                  highlight: AppColors.success,
                ),
              ),
            if (measurementRows.isNotEmpty) const SizedBox(height: 14),
            if (result.findings.isNotEmpty)
              _sectionCard(
                title: 'AI analysis',
                subtitle:
                    'Backend-generated findings from this specific analysis',
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(0.35),
                    1: FlexColumnWidth(2.65),
                    2: FlexColumnWidth(0.9),
                  },
                  children: [
                    _tableHeader('No.', 'Finding', 'Type'),
                    ...List.generate(result.findings.length, (index) {
                      return _tableRow(
                        '${index + 1}',
                        result.findings[index],
                        index == 0 ? 'AI' : 'ECG',
                        index.isEven,
                        AppColors.accent,
                      );
                    }),
                  ],
                ),
              ),
            if (result.findings.isNotEmpty) const SizedBox(height: 14),
            _sectionCard(
              title: 'Recommended Next Steps',
              subtitle:
                  'Generated action list for the current screening output',
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(0.45),
                  1: FlexColumnWidth(2.1),
                  2: FlexColumnWidth(1.0),
                },
                children: [
                  _tableHeader('No.', 'Action', 'Priority'),
                  ...List.generate(result.recommendations.length, (index) {
                    return _tableRow(
                      '${index + 1}',
                      result.recommendations[index],
                      result.riskLevel,
                      index.isEven,
                      result.riskColor,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: 'Review Status',
              subtitle: 'Presentation and escalation posture for this report',
              child: Column(
                children: [
                  _statusStrip(
                      'Review Priority', reviewLabel, result.riskColor),
                  const SizedBox(height: 10),
                  _statusStrip('Report Format', 'Shareable PDF-ready summary',
                      AppColors.accent),
                  const SizedBox(height: 10),
                  _statusStrip('Safety Layer', 'Prototype safeguards available',
                      AppColors.success),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassPanel(
              padding: const EdgeInsets.all(14),
              child: const Text(
                'This page is an AI-assisted ECG screening summary and should be reviewed clinically before treatment decisions.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _buildEnglishCaseSummary({
    required AnalysisResult result,
    required double bpm,
    required double? qtc,
    required double? qrs,
    required double? st,
    required String source,
  }) {
    final parts = <String>[
      'This case was analyzed from $source and is currently categorized as ${result.riskLevel.toLowerCase()} risk with ${(result.confidence * 100).toStringAsFixed(1)}% analysis confidence.',
      'Estimated heart rate is ${bpm.toStringAsFixed(0)} bpm.',
      if (qrs != null || qtc != null || st != null)
        'Key ECG markers: ${[
          if (qrs != null) 'QRS ${qrs.toStringAsFixed(0)} ms',
          if (qtc != null) 'QTc ${qtc.toStringAsFixed(0)} ms',
          if (st != null) 'ST shift ${st.toStringAsFixed(2)}',
        ].join(', ')}.',
      if (result.findings.isNotEmpty)
        'Primary interpretation point: ${result.findings.first}.',
      if (result.recommendations.isNotEmpty)
        'Suggested next step: ${result.recommendations.first}.',
    ];
    return parts.join(' ');
  }

  static String _buildArabicCaseSummary({
    required AnalysisResult result,
    required double bpm,
    required double? qtc,
    required double? qrs,
    required double? st,
    required String source,
  }) {
    final parts = <String>[
      'تم تحليل هذه الحالة من مصدر $source، ويصنف الفحص الحالي كمستوى خطورة ${_riskArabicLabel(result.riskLevel)} بنسبة ثقة ${result.confidence.toStringAsFixed(1)}٪.',
      'معدل القلب التقديري الحالي هو ${bpm.toStringAsFixed(0)} نبضة في الدقيقة.',
      if (qrs != null || qtc != null || st != null)
        'أهم المؤشرات الكهربائية الحالية: ${[
          if (qrs != null) 'QRS ${qrs.toStringAsFixed(0)} مللي ثانية',
          if (qtc != null) 'QTc ${qtc.toStringAsFixed(0)} مللي ثانية',
          if (st != null) 'انزياح ST بمقدار ${st.toStringAsFixed(2)}',
        ].join('، ')}.',
      if (result.findings.isNotEmpty)
        'أهم ملاحظة في التحليل: ${result.findings.first}.',
      if (result.recommendations.isNotEmpty)
        'الخطوة التالية المقترحة: ${result.recommendations.first}.',
    ];
    return parts.join(' ');
  }

  static String _riskArabicLabel(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return 'مرتفع';
      case 'medium':
        return 'متوسط';
      case 'low':
        return 'منخفض';
      default:
        return risk;
    }
  }

  static String _buildArabicCaseSummaryClean({
    required AnalysisResult result,
    required double bpm,
    required double? qtc,
    required double? qrs,
    required double? st,
    required String source,
  }) {
    final parts = <String>[
      'تم تحليل هذه الحالة من مصدر $source، ويُصنَّف الفحص الحالي كمستوى خطورة ${_riskArabicLabelClean(result.riskLevel)} بنسبة ثقة ${result.confidence.toStringAsFixed(1)}٪.',
      'معدل القلب التقديري الحالي هو ${bpm.toStringAsFixed(0)} نبضة في الدقيقة.',
      if (qrs != null || qtc != null || st != null)
        'أهم المؤشرات الكهربائية الحالية: ${[
          if (qrs != null) 'QRS ${qrs.toStringAsFixed(0)} مللي ثانية',
          if (qtc != null) 'QTc ${qtc.toStringAsFixed(0)} مللي ثانية',
          if (st != null) 'انزياح ST بمقدار ${st.toStringAsFixed(2)}',
        ].join('، ')}.',
      if (result.findings.isNotEmpty)
        'أهم ملاحظة في التحليل: ${result.findings.first}.',
      if (result.recommendations.isNotEmpty)
        'الخطوة التالية المقترحة: ${result.recommendations.first}.',
    ];
    return parts.join(' ');
  }

  static String _riskArabicLabelClean(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return 'مرتفع';
      case 'medium':
        return 'متوسط';
      case 'low':
        return 'منخفض';
      default:
        return risk;
    }
  }

  static Widget _headlineMetric(String label, String value, Color valueColor) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final dark = AppState.isDarkMode.value;
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  color: dark ? Colors.white60 : AppColors.textSecondary,
                  fontSize: 12)),
          const Divider(height: 22),
          child,
        ],
      ),
    );
  }

  static Widget _reportTable(List<_ReportRow> rows,
      {required Color highlight}) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.3),
        1: FlexColumnWidth(1.15),
        2: FlexColumnWidth(1.55),
      },
      children: [
        _tableHeader('Parameter', 'Result', 'Comment'),
        ...List.generate(rows.length, (index) {
          final row = rows[index];
          return _tableRow(
              row.label, row.value, row.note, index.isEven, highlight);
        }),
      ],
    );
  }

  static TableRow _tableHeader(String c1, String c2, String c3) {
    final dark = AppState.isDarkMode.value;
    return TableRow(
      decoration: BoxDecoration(
        color: dark
            ? AppColors.primary.withAlpha(48)
            : AppColors.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
      ),
      children: [
        _tableCell(c1, isHeader: true),
        _tableCell(c2, isHeader: true),
        _tableCell(c3, isHeader: true),
      ],
    );
  }

  static TableRow _tableRow(
    String c1,
    String c2,
    String c3,
    bool even,
    Color accent,
  ) {
    final dark = AppState.isDarkMode.value;
    return TableRow(
      decoration: BoxDecoration(
        color: even
            ? (dark ? AppColors.surfaceDark.withAlpha(160) : Colors.white)
            : (dark
                ? AppColors.backgroundDark.withAlpha(120)
                : AppColors.background),
      ),
      children: [
        _tableCell(c1),
        _tableCell(c2, color: accent, weight: FontWeight.w700),
        _tableCell(c3),
      ],
    );
  }

  static TableRow _contextRow(String label, String value) {
    return TableRow(
      children: [
        _tableCell(label, color: AppColors.primary, weight: FontWeight.w700),
        _tableCell(value),
      ],
    );
  }

  static Widget _tableCell(
    String text, {
    bool isHeader = false,
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) {
    final dark = AppState.isDarkMode.value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          color: color ??
              (isHeader
                  ? (dark ? Colors.white : AppColors.primary)
                  : (dark ? Colors.white.withAlpha(235) : Colors.black87)),
          fontWeight: isHeader ? FontWeight.w700 : weight,
          fontSize: isHeader ? 12 : 12.5,
        ),
      ),
    );
  }

  static Widget _statusStrip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(48)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _infoBlock(String title, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bulletInfoRow(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 10, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportActionPanel extends StatefulWidget {
  final ApiService api;
  final String analysisId;

  const _ReportActionPanel({
    required this.api,
    required this.analysisId,
  });

  @override
  State<_ReportActionPanel> createState() => _ReportActionPanelState();
}

class _ReportActionPanelState extends State<_ReportActionPanel> {
  bool _loading = false;
  String? _lastReportUrl;
  String? _status;

  Future<void> _generateAndOpen() async {
    if (widget.analysisId.isEmpty) return;
    setState(() {
      _loading = true;
      _status = null;
    });
    try {
      final report = await widget.api.generateReport(
        analysisId: widget.analysisId,
      );
      final url = widget.api.reportDownloadUrl(report.reportId);
      final opened = await launchUrlString(url, webOnlyWindowName: '_blank');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _lastReportUrl = url;
        _status = opened
            ? 'PDF report generated and opened successfully.'
            : 'PDF report generated successfully.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = 'Report generation failed: $e';
      });
    }
  }

  Future<void> _openLastReport() async {
    final url = _lastReportUrl;
    if (url == null) return;
    final opened = await launchUrlString(url, webOnlyWindowName: '_blank');
    if (!mounted) return;
    setState(() {
      _status = opened
          ? 'Latest report opened.'
          : 'Unable to open the latest report.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final canGenerate = widget.analysisId.isNotEmpty;
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      radius: BorderRadius.circular(AppRadii.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Generate the physician-ready PDF package, then reopen the latest exported report when needed.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _loading ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
              ),
              ElevatedButton.icon(
                onPressed: _loading || !canGenerate ? null : _generateAndOpen,
                icon:
                    Icon(_loading ? Icons.sync : Icons.picture_as_pdf_outlined),
                label: Text(
                    _loading ? 'Generating report...' : 'Generate PDF Report'),
              ),
              OutlinedButton.icon(
                onPressed:
                    _loading || _lastReportUrl == null ? null : _openLastReport,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open latest report'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _miniStatusRow('Analysis ID',
              widget.analysisId.isEmpty ? 'Unavailable' : widget.analysisId),
          _miniStatusRow('Session Mode',
              canGenerate ? 'Analysis-linked report' : 'Unavailable'),
          _miniStatusRow(
              'Latest Report URL', _lastReportUrl ?? 'Not generated yet'),
          if (_status != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _status!.toLowerCase().contains('failed')
                    ? AppColors.danger.withAlpha(18)
                    : AppColors.success.withAlpha(18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _status!.toLowerCase().contains('failed')
                      ? AppColors.danger.withAlpha(70)
                      : AppColors.success.withAlpha(70),
                ),
              ),
              child: Text(
                _status!,
                style: TextStyle(
                  color: _status!.toLowerCase().contains('failed')
                      ? AppColors.danger
                      : AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRow {
  final String label;
  final String value;
  final String note;
  const _ReportRow(this.label, this.value, this.note);
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _api;

  @override
  void initState() {
    super.initState();
    _api = TextEditingController(text: AppState.apiBaseUrl.value);
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  void _save() {
    AppState.apiBaseUrl.value = _api.text.trim();
    unawaited(AppState.persistSettings());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_t('Saved', 'تم الحفظ'))),
    );
  }

  Future<void> _signOut() async {
    ApiService.clearAuth();
    await AppState.clearSessionState();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      _fadeRoute(const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AppBackdrop(
        dark: dark,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              GlassPanel(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Settings', 'الإعدادات'),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _t(
                        'Configure the language, appearance, and backend connection for the Cardiac Pre-Ischemia workspace.',
                        'اضبط اللغة والمظهر واتصال الخادم داخل مساحة عمل Cardiac Pre-Ischemia.',
                      ),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.55,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _signalChip(
                            Icons.language_rounded, _t('Language', 'اللغة')),
                        _signalChip(
                            Icons.palette_outlined, _t('Theme', 'المظهر')),
                        _signalChip(
                            Icons.link_rounded, _t('Backend', 'الخادم')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassPanel(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppState.projectName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: dark ? Colors.white : AppColors.ink,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppState.projectTagline,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassPanel(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Localization & Appearance', 'اللغة والمظهر'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<bool>(
                      valueListenable: AppState.isArabic,
                      builder: (context, isArabic, _) {
                        return SwitchListTile(
                          value: isArabic,
                          onChanged: (v) {
                            AppState.isArabic.value = v;
                            unawaited(AppState.persistSettings());
                          },
                          title: Text(_t('Arabic Language', 'اللغة العربية')),
                          subtitle: Text(
                            _t('Switch interface copy between English and Arabic.',
                                'التبديل بين اللغة الإنجليزية والعربية.'),
                          ),
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: AppState.isDarkMode,
                      builder: (context, enabled, _) {
                        return SwitchListTile(
                          value: enabled,
                          onChanged: (v) {
                            AppState.isDarkMode.value = v;
                            unawaited(AppState.persistSettings());
                          },
                          title: Text(_t('Dark Theme', 'الثيم الداكن')),
                          subtitle: Text(
                            _t('Use the darker visual mode for demos and low-light review.',
                                'استخدم النمط الداكن للعروض والمراجعة في الإضاءة المنخفضة.'),
                          ),
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassPanel(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Developer / Advanced Mode',
                          'وضع المطور / الوضع المتقدم'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<bool>(
                      valueListenable: AppState.developerMode,
                      builder: (context, enabled, _) {
                        return Column(
                          children: [
                            SwitchListTile(
                              value: enabled,
                              onChanged: (v) {
                                AppState.developerMode.value = v;
                                unawaited(AppState.persistSettings());
                              },
                              title: Text(_t(
                                  'Enable advanced connectivity controls',
                                  'تفعيل إعدادات الاتصال المتقدمة')),
                              subtitle: Text(_t(
                                  'Use this only for demo setup, local server changes, and debugging.',
                                  'استخدم هذا فقط لإعداد العرض أو تغيير الخادم المحلي أو التصحيح.')),
                              contentPadding: EdgeInsets.zero,
                            ),
                            if (enabled) ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: _api,
                                style: _inputTextStyle(context),
                                decoration: InputDecoration(
                                  labelText: _t('Server URL', 'رابط الخادم'),
                                  helperText: _t(
                                      'Example: http://192.168.1.10:8001',
                                      'مثال: http://192.168.1.10:8001'),
                                  prefixIcon: const Icon(Icons.link),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _save,
                                  icon: const Icon(Icons.save_outlined),
                                  label: Text(_t('Save Connection Settings',
                                      'حفظ إعدادات الاتصال')),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassPanel(
                padding: const EdgeInsets.all(16),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.auto_awesome, color: AppColors.accent),
                  title: Text(
                    _t('System Enhancements', 'تطويرات النظام'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  subtitle: Text(
                    _t('Explainable AI, safety, and compliance',
                        'تفسير الذكاء، الأمان، والامتثال'),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    _fadeRoute(const SystemEnhancementsPage()),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GlassPanel(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.danger),
                    label: Text(
                      _t('Sign out', 'تسجيل الخروج'),
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w800,
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
}

class SystemEnhancementsPage extends StatelessWidget {
  const SystemEnhancementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        _t('Explainable AI Module',
            'ÙˆØ­Ø¯Ø© ØªÙØ³ÙŠØ± Ø§Ù„Ø°ÙƒØ§Ø¡ Ø§Ù„Ø§ØµØ·Ù†Ø§Ø¹ÙŠ'),
        _t('Visual explanations highlight ECG patterns behind alerts.',
            'ØªÙˆØ¶ÙŠØ­Ø§Øª Ù…Ø±Ø¦ÙŠØ© ØªÙØ¸Ù‡Ø± Ø£Ù†Ù…Ø§Ø· Ø±Ø³Ù… Ø§Ù„Ù‚Ù„Ø¨ ÙˆØ±Ø§Ø¡ Ø§Ù„ØªÙ†Ø¨ÙŠÙ‡Ø§Øª.')
      ),
      (
        _t('Clinical Override & Human-in-the-Loop',
            'Ù…Ø±Ø§Ø¬Ø¹Ø© Ø§Ù„Ø·Ø¨ÙŠØ¨ ÙˆØ§Ù„ØªØ­ÙƒÙ… Ø§Ù„Ø¨Ø´Ø±ÙŠ'),
        _t('Physicians can confirm or override AI alerts.',
            'ÙŠÙ…ÙƒÙ† Ù„Ù„Ø·Ø¨ÙŠØ¨ ØªØ£ÙƒÙŠØ¯ Ø£Ùˆ ØªØ¬Ø§ÙˆØ² ØªÙ†Ø¨ÙŠÙ‡Ø§Øª Ø§Ù„Ø°ÙƒØ§Ø¡.')
      ),
      (
        _t('Personalized Baseline Calibration',
            'Ù…Ø¹Ø§ÙŠØ±Ø© Ø®Ø· Ø£Ø³Ø§Ø³ Ù…Ø®ØµØµØ©'),
        _t('Risk detection based on each patient baseline.',
            'Ø§Ù„ÙƒØ´Ù ÙŠØ¹ØªÙ…Ø¯ Ø¹Ù„Ù‰ Ø®Ø· Ø§Ù„Ø£Ø³Ø§Ø³ Ù„ÙƒÙ„ Ù…Ø±ÙŠØ¶.')
      ),
      (
        _t('Data Security & Medical Compliance',
            'Ø£Ù…Ø§Ù† Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª ÙˆØ§Ù„Ø§Ù…ØªØ«Ø§Ù„ Ø§Ù„Ø·Ø¨ÙŠ'),
        _t('End-to-end encryption with role-based access.',
            'ØªØ´ÙÙŠØ± Ø´Ø§Ù…Ù„ Ù…Ø¹ ØµÙ„Ø§Ø­ÙŠØ§Øª ÙˆØµÙˆÙ„ Ø­Ø³Ø¨ Ø§Ù„Ø¯ÙˆØ±.')
      ),
      (
        _t('Offline Safety Mode', 'ÙˆØ¶Ø¹ Ø£Ù…Ø§Ù† Ø¯ÙˆÙ† Ø§ØªØµØ§Ù„'),
        _t('Local monitoring continues during outages.',
            'Ø§Ù„Ù…Ø±Ø§Ù‚Ø¨Ø© ØªØ³ØªÙ…Ø± Ù…Ø­Ù„ÙŠÙ‹Ø§ Ø¹Ù†Ø¯ Ø§Ù†Ù‚Ø·Ø§Ø¹ Ø§Ù„Ø´Ø¨ÙƒØ©.')
      ),
      (
        _t('Research & Clinical Logging Mode',
            'ÙˆØ¶Ø¹ Ø§Ù„Ø³Ø¬Ù„ Ø§Ù„Ø¨Ø­Ø«ÙŠ'),
        _t('Anonymized logs for research with consent.',
            'ØªØ³Ø¬ÙŠÙ„Ø§Øª Ù…Ø¬Ù‡ÙˆÙ„Ø© Ù„Ù„Ø¨Ø­Ø« Ø¨Ù…ÙˆØ§ÙÙ‚Ø© Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù….')
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('System Enhancements', 'ØªØ·ÙˆÙŠØ±Ø§Øª Ø§Ù„Ù†Ø¸Ø§Ù…')),
        actions: _topBarActions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          AppHeroBanner(
            title: _t('Clinical-grade improvements',
                'ØªØ­Ø³ÙŠÙ†Ø§Øª Ø¨Ù…Ø³ØªÙˆÙ‰ Ø·Ø¨ÙŠ'),
            subtitle: _t('Transparency, safety, and research readiness.',
                'Ø´ÙØ§ÙÙŠØ©ØŒ Ø£Ù…Ø§Ù†ØŒ ÙˆØ¬Ø§Ù‡Ø²ÙŠØ© Ø¨Ø­Ø«ÙŠØ©.'),
            icon: Icons.shield_outlined,
            gradient: AppGradients.hero,
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.$2,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PatientHome extends StatefulWidget {
  final String username;
  const PatientHome({super.key, required this.username});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    ApiService.currentUsername = widget.username;
    AppState.currentWorkspace = 'patient_home';
    unawaited(AppState.persistSession(
      username: widget.username,
      workspace: 'patient_home',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      PatientDashboardPage(
        username: widget.username,
        onNavigate: (index) => setState(() => _index = index),
      ),
      AnalysisHubPage(
        api: ApiService(baseUrl: _apiBaseUrl()),
        roleTitle: _t('Analyze ECG', 'تحليل ECG'),
        roleSubtitle: _t(
          'Choose a real ECG source and move through a clearer medical analysis workflow.',
          'اختر مصدر ECG حقيقي وتحرك عبر مسار تحليل طبي أوضح.',
        ),
        accentColor: AppColors.accent,
        sourceLabel: 'Patient',
        presetDraft: AnalysisSessionDraft(
          patientName: widget.username,
          patientAge: '',
          patientSex: 'Not specified',
          doctorName: AppState.selectedDoctor?.name ?? '',
          notes: '',
          analysisSource: 'Patient analyze tab',
        ),
      ),
      const PatientHistoryPage(),
      PatientLiveScreen(username: widget.username),
      PatientProfilePage(username: widget.username),
    ];

    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.home_rounded),
        label: _t('Home', 'الرئيسية'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.auto_graph_rounded),
        label: _t('Analyze', 'التحليل'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.timeline_rounded),
        label: _t('History', 'السجل'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.monitor_heart_rounded),
        label: _t('Monitor', 'المراقبة'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_rounded),
        label: _t('Profile', 'الملف'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final dark = Theme.of(context).brightness == Brightness.dark;
        if (wide) {
          return Scaffold(
            body: AppBackdrop(
              dark: dark,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: GlassPanel(
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 10),
                      child: NavigationRail(
                        selectedIndex: _index,
                        onDestinationSelected: (value) =>
                            setState(() => _index = value),
                        backgroundColor: Colors.transparent,
                        indicatorColor:
                            AppColors.accentSoft.withAlpha(dark ? 24 : 255),
                        labelType: NavigationRailLabelType.all,
                        leading: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppGradients.hero,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.monitor_heart_outlined,
                              color: Colors.white),
                        ),
                        destinations: destinations
                            .map(
                              (d) => NavigationRailDestination(
                                icon: d.icon,
                                selectedIcon: d.selectedIcon ?? d.icon,
                                label: Text(d.label),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  Expanded(child: pages[_index]),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          extendBody: true,
          body: AppBackdrop(
            dark: dark,
            child: pages[_index],
          ),
          bottomNavigationBar: GlassNavBar(
            index: _index,
            onSelected: (value) => setState(() => _index = value),
            destinations: destinations,
          ),
        );
      },
    );
  }
}

class PatientDashboardSnapshot {
  final PatientModel? patient;
  final ReportModel? report;
  final List<AppointmentModel> appointments;

  const PatientDashboardSnapshot({
    required this.patient,
    required this.report,
    required this.appointments,
  });
}

class PatientDashboardPage extends StatefulWidget {
  final String username;
  final ValueChanged<int> onNavigate;

  const PatientDashboardPage({
    super.key,
    required this.username,
    required this.onNavigate,
  });

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  late Future<PatientDashboardSnapshot> _future;
  final ApiService _api = ApiService(baseUrl: _apiBaseUrl());

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PatientDashboardSnapshot> _load() async {
    final patients = await _api.listPatients();
    PatientModel? patient;
    for (final item in patients) {
      if (item.name.trim().toLowerCase() ==
          widget.username.trim().toLowerCase()) {
        patient = item;
        break;
      }
    }
    ReportModel? report;
    List<AppointmentModel> appointments = const [];
    if (patient?.id != null) {
      try {
        report = await _api.getReport(patient!.id!);
      } catch (_) {}
      try {
        appointments = await _api.listAppointments(patientId: patient!.id!);
      } catch (_) {}
    }
    return PatientDashboardSnapshot(
      patient: patient,
      report: report,
      appointments: appointments,
    );
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Your Heart Health', 'صحة قلبك')),
        actions: _topBarActions(context),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<PatientDashboardSnapshot>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                padding: const EdgeInsets.all(18),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _dashboardHero('Unable to load dashboard',
                      'Pull to refresh and verify server connectivity.'),
                ],
              );
            }
            final data = snapshot.data ??
                const PatientDashboardSnapshot(
                    patient: null, report: null, appointments: []);
            final report = data.report;
            final patient = data.patient;
            final appointments = data.appointments;
            final latestRisk = report?.riskLevels.isNotEmpty == true
                ? report!.riskLevels.last
                : 'No analysis';
            final latestBpm = report?.bpm.isNotEmpty == true
                ? '${report!.bpm.last} bpm'
                : 'Unavailable';
            final trendValues = (report?.bpm ?? const <int>[])
                .map((e) => e.toDouble())
                .toList();
            final latestDate = report?.createdAt?.split('T').first ?? 'No date';
            final nextAppointment = appointments.isNotEmpty
                ? appointments.first.when
                : _t('No visit scheduled', 'لا توجد زيارة مجدولة');
            final trendInsight = _buildTrendComparison(report);

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _dashboardHero(
                  '${_t('Hello', 'مرحبًا')} ${widget.username}',
                  _t(
                    'Track your latest AI-assisted ECG screening, wearable monitoring, and care pathway in one place.',
                    'تابع آخر فحص ECG مدعوم بالذكاء الاصطناعي والمراقبة القابلة للارتداء وخطة الرعاية في مكان واحد.',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppGradients.hero,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    boxShadow: AppShadows.lift,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Latest Screening', 'آخر فحص'),
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        latestRisk,
                        style: GoogleFonts.sora(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_t('Updated', 'تم التحديث')} $latestDate',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _heroMetric(
                                _t('Heart Rate', 'معدل النبض'), latestBpm),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _heroMetric(
                                _t('Signal Flow', 'حالة التحليل'),
                                patient?.id != null
                                    ? 'Linked'
                                    : 'Profile only'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${_t('Next follow-up', 'المتابعة القادمة')}: $nextAppointment',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => widget.onNavigate(1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                          ),
                          child: Text(_t('Analyze ECG', 'تحليل ECG')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title: _t('AI Patient Copilot', 'المساعد الذكي للمريض'),
                        subtitle: _t(
                          'Simple explanation and change detection based on your stored ECG results.',
                          'شرح مبسط واكتشاف للتغيرات بناءً على نتائج ECG المحفوظة لديك.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: trendInsight.color.withAlpha(12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: trendInsight.color.withAlpha(38)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trendInsight.headline,
                              style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: trendInsight.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              trendInsight.summary,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, height: 1.45),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppMetricTile._miniStat(
                                _t('BPM Change', 'تغير النبض'),
                                trendInsight.bpmDeltaLabel),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppMetricTile._miniStat(
                                _t('Risk Shift', 'تغير الخطر'),
                                trendInsight.riskShiftLabel),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...trendInsight.bullets.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Icon(Icons.circle,
                                    size: 10, color: trendInsight.color),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      height: 1.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount:
                      MediaQuery.of(context).size.width >= 700 ? 4 : 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.25,
                  children: [
                    AppMetricTile(
                      label: _t('Latest Risk', 'آخر خطر'),
                      value: latestRisk,
                      caption:
                          _t('Most recent screening state', 'آخر حالة فحص'),
                      accent: AppColors.danger,
                      icon: Icons.priority_high_rounded,
                    ),
                    AppMetricTile(
                      label: _t('Heart Rate', 'النبض'),
                      value: latestBpm,
                      caption: _t(
                          'Last available ECG session', 'آخر جلسة ECG متاحة'),
                      accent: AppColors.accent,
                      icon: Icons.favorite_rounded,
                    ),
                    AppMetricTile(
                      label: _t('Trend Points', 'نقاط الاتجاه'),
                      value: '${report?.labels.length ?? 0}',
                      caption: _t('Recent stored report samples',
                          'عينات التقارير الأخيرة'),
                      accent: AppColors.success,
                      icon: Icons.insights_rounded,
                    ),
                    AppMetricTile(
                      label: _t('Appointments', 'المواعيد'),
                      value: '${appointments.length}',
                      caption: _t('Linked follow-up visits',
                          'زيارات المتابعة المرتبطة'),
                      accent: AppColors.secondary,
                      icon: Icons.event_available_rounded,
                    ),
                    AppMetricTile(
                      label: _t('Assigned Doctor', 'الطبيب'),
                      value: AppState.selectedDoctor?.name ??
                          _t('Not linked', 'غير مرتبط'),
                      caption: _t('Current care owner', 'المتابع الحالي'),
                      accent: AppColors.primary,
                      icon: Icons.medical_services_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title: _t('Trend Visualization', 'عرض الاتجاه'),
                        subtitle: _t(
                            'Recent heart-rate points from saved analyses',
                            'آخر نقاط معدل النبض من التحليلات المحفوظة'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: trendValues.isEmpty
                            ? _emptyState(_t('No saved trend yet.',
                                'لا يوجد اتجاه محفوظ بعد.'))
                            : CustomPaint(painter: TrendPainter(trendValues)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title: _t('Recent Analyses', 'التحاليل الأخيرة'),
                        subtitle: _t(
                            'Saved report timeline for this patient profile',
                            'الخط الزمني للتقارير المحفوظة لهذا الملف'),
                        action: TextButton(
                          onPressed: () => widget.onNavigate(2),
                          child: Text(_t('Open History', 'فتح السجل')),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (report == null || report.labels.isEmpty)
                        _emptyState(_t('No analysis history yet.',
                            'لا يوجد سجل تحاليل بعد.'))
                      else
                        ...List.generate(report.labels.length, (index) {
                          final label = report.labels[index];
                          final bpm =
                              index < report.bpm.length ? report.bpm[index] : 0;
                          final risk = index < report.riskLevels.length
                              ? report.riskLevels[index]
                              : '-';
                          return _timelineRow(label, bpm, risk);
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _quickActionCard(
                            _t('Monitor', 'المراقبة'),
                            Icons.monitor_heart_rounded,
                            AppColors.accent,
                            () => widget.onNavigate(3))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _quickActionCard(
                            _t('Reports', 'التقارير'),
                            Icons.description_rounded,
                            AppColors.success,
                            () => Navigator.push(
                                context,
                                _fadeRoute(PatientReportsPage(
                                    patient: patient ??
                                        PatientModel(
                                            name: widget.username)))))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _quickActionCard(
                            _t('Appointments', 'المواعيد'),
                            Icons.event_note_rounded,
                            AppColors.secondary,
                            () => Navigator.push(
                                context,
                                _fadeRoute(PatientAppointmentsPage(
                                    patient: patient ??
                                        PatientModel(
                                            name: widget.username)))))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _quickActionCard(
                            _t('Profile & Doctor', 'الملف والطبيب'),
                            Icons.person_pin_circle_outlined,
                            AppColors.primary,
                            () => widget.onNavigate(4))),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dashboardHero(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: AppGradients.accentGlow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.favorite_rounded,
                color: AppColors.accentDeep, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _timelineRow(String label, int bpm, String risk) {
    final color = risk == 'High'
        ? AppColors.danger
        : risk == 'Medium'
            ? AppColors.warning
            : AppColors.success;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label  •  $bpm bpm',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              risk,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class PatientLiveScreen extends StatefulWidget {
  final String username;
  final bool prototypeDemo;
  const PatientLiveScreen({
    super.key,
    required this.username,
    this.prototypeDemo = false,
  });

  @override
  State<PatientLiveScreen> createState() => _PatientLiveScreenState();
}

class _PatientLiveScreenState extends State<PatientLiveScreen> {
  static const String _bleServiceUuid = '0000FFE0-0000-1000-8000-00805F9B34FB';
  static const String _bleCharUuid = '0000FFE1-0000-1000-8000-00805F9B34FB';

  List<double> ecgPoints = [];
  Timer? _demoTimer;
  Timer? _wifiTimer;
  StreamSubscription<List<int>>? _bleSub;
  BluetoothDevice? _bleDevice;
  final TextEditingController _wifiHost =
      TextEditingController(text: 'http://192.168.4.1');
  bool _connecting = false;
  String _connectionStatus = 'Not connected';
  String _connectionMode = 'Demo';
  double riskLevel = 0.2;
  String region = 'Anterior';
  List<String> activeCoils = CoilLogic.coilsForRegion('Anterior');
  double _demoBeatPhase = 0;
  int _demoTick = 0;
  int _demoStage = -1;
  double _demoHeartRate = 76;
  double _demoSignalQuality = 96;
  String _demoRhythm = 'Normal sinus rhythm';
  String _demoScreeningState = 'Stable screening pattern';
  List<LiveAlertEvent> _liveEvents = const [];
  String _lastRiskBand = 'low';
  String _lastRegionLabel = 'Anterior';
  int? _resolvedPatientId;
  bool _loadingStoredEvents = false;

  final ApiService api = ApiService(baseUrl: _apiBaseUrl());

  @override
  void initState() {
    super.initState();
    ecgPoints = List.generate(120, (index) => 0.0);
    _startDemoStream();
    unawaited(_bootstrapMonitoringContext());
  }

  @override
  void dispose() {
    _stopDemoStream();
    _wifiTimer?.cancel();
    _bleSub?.cancel();
    _bleDevice?.disconnect();
    _wifiHost.dispose();
    super.dispose();
  }

  void _startDemoStream() {
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) return;
      _updateDemoScenario();
      final phaseStep = (_demoHeartRate / 60) * 0.04;
      _demoBeatPhase = (_demoBeatPhase + phaseStep) % 1;
      final phase = _demoBeatPhase;
      final baseline = 0.025 * math.sin(_demoTick * 0.025);
      final noise = (math.Random().nextDouble() - 0.5) *
          (1 - (_demoSignalQuality / 100)) *
          0.8;
      var value = baseline +
          _demoWave(phase, 0.18, 0.035, 0.13) +
          _demoWave(phase, 0.37, 0.012, -0.18) +
          _demoWave(phase, 0.40, 0.010, 1.55) +
          _demoWave(phase, 0.43, 0.014, -0.42) +
          _demoWave(phase, 0.68, 0.055, 0.36) +
          noise;
      if (_demoStage == 2 && phase > 0.76 && phase < 0.82) {
        value += _demoWave(phase, 0.79, 0.012, 0.45);
      }
      _applyEcgSample(value);
      _demoTick += 1;
    });
    _setStatus(
      widget.prototypeDemo ? 'ESP32 Demo' : 'Demo',
      widget.prototypeDemo ? 'Streaming simulated patient' : 'Simulated stream',
    );
    _recordLiveEvent(
      title: 'Demo monitoring started',
      detail:
          'The live screen is using the internal ECG simulator until a wearable device connects.',
      color: AppColors.primary,
    );
  }

  double _demoWave(
    double phase,
    double center,
    double width,
    double amplitude,
  ) {
    final distance = (phase - center) / width;
    return amplitude * math.exp(-0.5 * distance * distance);
  }

  void _updateDemoScenario() {
    if (!widget.prototypeDemo) return;
    final seconds = (_demoTick * 0.04) % 60;
    late final int nextStage;
    late final double targetHeartRate;
    late final double targetRisk;
    late final double targetQuality;
    late final String rhythm;
    late final String screeningState;

    if (seconds < 18) {
      nextStage = 0;
      targetHeartRate = 76;
      targetRisk = 0.18;
      targetQuality = 96;
      rhythm = 'Normal sinus rhythm';
      screeningState = 'Stable screening pattern';
    } else if (seconds < 34) {
      nextStage = 1;
      targetHeartRate = 101;
      targetRisk = 0.48;
      targetQuality = 92;
      rhythm = 'Sinus tachycardia pattern';
      screeningState = 'Monitor closely';
    } else if (seconds < 47) {
      nextStage = 2;
      targetHeartRate = 124;
      targetRisk = 0.73;
      targetQuality = 88;
      rhythm = 'Irregular rapid rhythm pattern';
      screeningState = 'Priority review simulated alert';
    } else {
      nextStage = 3;
      targetHeartRate = 84;
      targetRisk = 0.29;
      targetQuality = 94;
      rhythm = 'Recovering sinus rhythm';
      screeningState = 'Returning toward baseline';
    }

    _demoHeartRate += (targetHeartRate - _demoHeartRate) * 0.035;
    _demoHeartRate += math.sin(_demoTick * 0.037) * 0.035;
    riskLevel += (targetRisk - riskLevel) * 0.035;
    _demoSignalQuality += (targetQuality - _demoSignalQuality) * 0.045;
    _demoRhythm = rhythm;
    _demoScreeningState = screeningState;
    region = 'Low';
    activeCoils = const [];

    if (nextStage == _demoStage) return;
    _demoStage = nextStage;
    final color = nextStage == 2
        ? AppColors.danger
        : nextStage == 1
            ? AppColors.warning
            : AppColors.success;
    _recordLiveEvent(
      title: nextStage == 0
          ? 'Demo patient baseline established'
          : nextStage == 1
              ? 'Heart rate trend increased'
              : nextStage == 2
                  ? 'Simulated priority review alert'
                  : 'Demo patient entered recovery phase',
      detail:
          '${_demoHeartRate.round()} BPM • $_demoRhythm • ${(riskLevel * 100).round()}% simulated risk.',
      color: color,
    );
  }

  // ignore: unused_element
  Widget _doctorMessagingAiCardLegacy(DoctorHomeSnapshot home) {
    final brief = _buildMessagingOpsBrief(home);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: _t('AI Messaging Summary', 'ملخص المراسلة الذكي'),
            subtitle: _t(
              'AI reads the current dashboard workload to suggest the right communication pace.',
              'يلخّص الذكاء الاصطناعي ضغط المراسلات الحالي لاقتراح وتيرة المتابعة المناسبة.',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: brief.color.withAlpha(12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: brief.color.withAlpha(35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brief.headline,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: brief.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  brief.summary,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _snapshotMetric('Queue', brief.queueLabel, brief.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _snapshotMetric(
                    'Response', brief.responseLabel, AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...brief.bullets.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 10, color: brief.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _stopDemoStream() {
    _demoTimer?.cancel();
    _demoTimer = null;
  }

  void _applyEcgSample(double value) {
    setState(() {
      ecgPoints.removeAt(0);
      ecgPoints.add(value);
      if (widget.prototypeDemo) {
        region = 'Low';
        activeCoils = const [];
      } else {
        riskLevel = (0.15 + (value.abs() * 0.12)).clamp(0.0, 1.0);
        if (riskLevel > 0.62) {
          region = 'Anterior';
        } else if (riskLevel > 0.45) {
          region = 'Lateral';
        } else {
          region = 'Low';
        }
        activeCoils = region == 'Low' ? [] : CoilLogic.coilsForRegion(region);
      }
    });
    final newRiskBand =
        riskLevel > 0.62 ? 'high' : (riskLevel > 0.35 ? 'medium' : 'low');
    if (newRiskBand != _lastRiskBand) {
      _lastRiskBand = newRiskBand;
      _recordLiveEvent(
        title: newRiskBand == 'high'
            ? 'High live risk window detected'
            : newRiskBand == 'medium'
                ? 'Moderate live risk window detected'
                : 'Live risk returned to baseline',
        detail: widget.prototypeDemo
            ? 'The simulated patient risk band changed to ${newRiskBand.toUpperCase()} at ${_demoHeartRate.round()} BPM.'
            : 'Risk band changed to ${newRiskBand.toUpperCase()} with current region ${region == 'Low' ? 'no dominant alert region' : region}.',
        color: newRiskBand == 'high'
            ? AppColors.danger
            : newRiskBand == 'medium'
                ? AppColors.warning
                : AppColors.success,
      );
    }
    if (widget.prototypeDemo) return;
    final regionLabel = region == 'Low' ? 'Low' : region;
    if (regionLabel != _lastRegionLabel) {
      _lastRegionLabel = regionLabel;
      _recordLiveEvent(
        title: regionLabel == 'Low'
            ? 'Dominant alert region cleared'
            : 'Dominant alert region updated',
        detail: regionLabel == 'Low'
            ? 'No dominant stimulation region is currently active.'
            : 'The live assistant shifted the dominant region to $regionLabel.',
        color: regionLabel == 'Low' ? AppColors.success : AppColors.accent,
      );
    }
  }

  void _applyEcgSamples(List<double> values) {
    for (final v in values) {
      _applyEcgSample(v);
    }
  }

  void _setStatus(String mode, String status) {
    if (!mounted) return;
    setState(() {
      _connectionMode = mode;
      _connectionStatus = status;
    });
    _recordLiveEvent(
      title: '$mode connection update',
      detail: status,
      color: status.toLowerCase().contains('error') ||
              status.toLowerCase().contains('failed') ||
              status.toLowerCase().contains('not')
          ? AppColors.danger
          : status.toLowerCase().contains('connected')
              ? AppColors.success
              : AppColors.warning,
    );
  }

  void _recordLiveEvent({
    required String title,
    required String detail,
    required Color color,
  }) {
    if (!mounted) return;
    final next = LiveAlertEvent(
      timeLabel: _timeStampLabel(),
      title: title,
      detail: detail,
      color: color,
    );
    setState(() {
      _liveEvents = [next, ..._liveEvents].take(6).toList();
    });
    final patientId = _resolvedPatientId;
    if (patientId != null) {
      final severity = color == AppColors.danger
          ? 'high'
          : color == AppColors.warning
              ? 'medium'
              : 'info';
      unawaited(
        api.createMonitoringEvent(
          patientId: patientId,
          title: title,
          detail: detail,
          severity: severity,
        ),
      );
    }
  }

  Future<void> _bootstrapMonitoringContext() async {
    try {
      final patients = await api.listPatients();
      PatientModel? matched;
      for (final patient in patients) {
        if (patient.name.trim().toLowerCase() ==
            widget.username.trim().toLowerCase()) {
          matched = patient;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _resolvedPatientId = matched?.id;
      });
      if (_resolvedPatientId != null) {
        await _loadStoredEvents();
      }
    } catch (_) {}
  }

  Future<void> _loadStoredEvents() async {
    final patientId = _resolvedPatientId;
    if (patientId == null || _loadingStoredEvents) return;
    _loadingStoredEvents = true;
    try {
      final items = await api.listMonitoringEvents(patientId, limit: 6);
      if (!mounted || items.isEmpty) return;
      final mapped = items
          .map(
            (item) => LiveAlertEvent(
              timeLabel: _safeTimeLabel(item.createdAt),
              title: item.title,
              detail: item.detail,
              color: item.severity == 'high'
                  ? AppColors.danger
                  : item.severity == 'medium'
                      ? AppColors.warning
                      : AppColors.success,
            ),
          )
          .toList();
      setState(() {
        _liveEvents = mapped;
      });
    } catch (_) {
    } finally {
      _loadingStoredEvents = false;
    }
  }

  Future<void> _disconnectAll() async {
    _wifiTimer?.cancel();
    _wifiTimer = null;
    await _bleSub?.cancel();
    _bleSub = null;
    await _bleDevice?.disconnect();
    _bleDevice = null;
    if (!mounted) return;
    _startDemoStream();
  }

  Future<void> _connectWifi() async {
    if (_connecting) return;
    setState(() => _connecting = true);
    await _disconnectAll();
    _stopDemoStream();
    _setStatus('Wi-Fi', 'Connecting...');
    try {
      final uri = Uri.parse('${_wifiHost.text}/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) {
        _setStatus('Wi-Fi', 'Health check failed');
        return;
      }
      _setStatus('Wi-Fi', 'Connected');
      _wifiTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
        await _fetchWifiEcg();
      });
    } catch (_) {
      _setStatus('Wi-Fi', 'Connection error');
      _startDemoStream();
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _fetchWifiEcg() async {
    try {
      final uri = Uri.parse('${_wifiHost.text}/ecg');
      final res = await http.get(uri).timeout(const Duration(seconds: 2));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (data['ecg'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList();
      if (!mounted) return;
      _applyEcgSamples(list);
    } catch (_) {
      _setStatus('Wi-Fi', 'Stream error');
    }
  }

  Future<void> _connectBle() async {
    if (_connecting) return;
    if (kIsWeb) {
      _setStatus('BLE', 'Not supported on web');
      return;
    }
    setState(() => _connecting = true);
    await _disconnectAll();
    _stopDemoStream();
    _setStatus('BLE', 'Scanning...');
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      final results = await FlutterBluePlus.scanResults.first;
      BluetoothDevice? device;
      for (final r in results) {
        if (r.device.platformName.toLowerCase().contains('esp32')) {
          device = r.device;
          break;
        }
      }
      await FlutterBluePlus.stopScan();
      if (device == null) {
        _setStatus('BLE', 'Device not found');
        _startDemoStream();
        return;
      }
      _setStatus('BLE', 'Connecting...');
      await device.connect(timeout: const Duration(seconds: 10));
      final services = await device.discoverServices();
      BluetoothCharacteristic? target;
      for (final s in services) {
        if (s.uuid.toString().toLowerCase() == _bleServiceUuid.toLowerCase()) {
          for (final c in s.characteristics) {
            if (c.uuid.toString().toLowerCase() == _bleCharUuid.toLowerCase()) {
              target = c;
              break;
            }
          }
        }
      }
      if (target == null) {
        _setStatus('BLE', 'Characteristic not found');
        await device.disconnect();
        _startDemoStream();
        return;
      }
      await target.setNotifyValue(true);
      _bleSub = target.onValueReceived.listen((value) {
        final text = utf8.decode(value, allowMalformed: true).trim();
        if (text.isEmpty) return;
        final parts = text.split(',');
        final samples = <double>[];
        for (final p in parts) {
          final v = double.tryParse(p);
          if (v != null) samples.add(v);
        }
        if (samples.isNotEmpty) _applyEcgSamples(samples);
      });
      _bleDevice = device;
      _setStatus('BLE', 'Connected');
    } catch (_) {
      _setStatus('BLE', 'Connection error');
      _startDemoStream();
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<Position?> _getLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendSOS() async {
    final pos = await _getLocation();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pos == null
              ? 'Emergency Alert Sent (demo) - Location unavailable'
              : 'Emergency Alert Sent (demo) - ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
        ),
        backgroundColor: Colors.black,
      ),
    );

    if (pos != null) {
      await api.sendEmergencyAlert(patientName: widget.username, pos: pos);
    }
  }

  Widget _prototypeSystemCard({
    required bool hardwareConnected,
    required Color statusColor,
  }) {
    final source = hardwareConnected
        ? '$_connectionMode hardware stream'
        : 'Internal synthetic ECG generator';
    return _card(
      title: 'Prototype Session',
      icon: Icons.developer_board_rounded,
      iconColor: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withAlpha(45)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hardwareConnected
                            ? 'Wearable hardware connected'
                            : 'Prototype simulation active',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hardwareConnected
                            ? 'Samples are arriving from the selected connection.'
                            : 'A synthetic waveform is used until ESP32 connects over BLE or Wi-Fi.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _snapshotRow('Target controller', 'ESP32', AppColors.primary),
          const SizedBox(height: 9),
          _snapshotRow(
            'ECG acquisition',
            'One-lead analog ECG sensor',
            AppColors.accentDeep,
          ),
          const SizedBox(height: 9),
          _snapshotRow('Current source', source, statusColor),
          const SizedBox(height: 9),
          _snapshotRow(
            'Signal buffer',
            '${ecgPoints.length} display samples',
            AppColors.primary,
          ),
          const SizedBox(height: 9),
          _snapshotRow(
            'Clinical inference',
            'Disabled for prototype demo',
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _prototypeBoundariesCard() {
    return _card(
      title: 'Prototype Boundaries',
      icon: Icons.verified_user_outlined,
      iconColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SafetyRow(label: 'Demo waveform', value: 'Synthetic'),
          SafetyRow(label: 'Risk prediction', value: 'Not calculated'),
          SafetyRow(label: 'Medical diagnosis', value: 'Not provided'),
          SafetyRow(label: 'Hardware route', value: 'BLE or Wi-Fi'),
          SizedBox(height: 10),
          Text(
            'Connect the ESP32 to replace the simulator with device samples. '
            'Clinical analysis requires a saved ECG segment and the validated inference pipeline.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required String detail,
    required Color color,
  }) {
    return Container(
      width: MediaQuery.sizeOf(context).width < 700 ? double.infinity : 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(45)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 13),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrototypePatientDemo({
    required bool hardwareConnected,
    required Color statusColor,
    required String riskText,
    required Color riskColor,
  }) {
    final simulationActive = _demoTimer?.isActive ?? false;
    final streamColor = hardwareConnected || simulationActive
        ? AppColors.success
        : AppColors.warning;
    final recommendation = riskLevel > 0.62
        ? _t(
            'Priority review is demonstrated. Pause activity and request clinician assessment.',
            'تظهر المحاكاة أولوية للمراجعة. أوقف النشاط واطلب تقييم الطبيب.',
          )
        : riskLevel > 0.35
            ? _t(
                'Continue monitoring and review the trend if the pattern persists.',
                'استمر في المراقبة وراجع الاتجاه إذا استمر النمط.',
              )
            : _t(
                'The simulated patient is currently near the baseline monitoring range.',
                'المريض التجريبي قريب حاليًا من نطاق المراقبة الأساسي.',
              );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_t('Live Patient Session', 'جلسة المريض الحية')),
        actions: [
          _workspaceAction(context),
          _settingsAction(context),
          Container(
            margin: const EdgeInsetsDirectional.only(end: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: streamColor.withAlpha(24),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: streamColor.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, color: streamColor, size: 10),
                const SizedBox(width: 6),
                Text(
                  hardwareConnected ? 'LIVE' : 'DEMO LIVE',
                  style: TextStyle(
                    color: streamColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppGradients.hero,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppShadows.lift,
              ),
              child: Wrap(
                spacing: 18,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(24),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.monitor_heart_rounded,
                      color: Colors.white,
                      size: 31,
                    ),
                  ),
                  SizedBox(
                    width: math.min(
                      520,
                      MediaQuery.sizeOf(context).width - 72,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _t(
                            'Virtual wearable connected • ESP32-ECG-DEMO • One-lead stream',
                            'جهاز تجريبي متصل • ESP32-ECG-DEMO • بث أحادي القناة',
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: streamColor.withAlpha(35),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: streamColor.withAlpha(110)),
                    ),
                    child: Text(
                      hardwareConnected
                          ? _t('HARDWARE STREAMING', 'بث الجهاز يعمل')
                          : _t('SIMULATION STREAMING', 'المحاكاة تعمل'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _demoMetricTile(
                  icon: Icons.favorite_rounded,
                  label: _t('Heart Rate', 'معدل ضربات القلب'),
                  value: '${_demoHeartRate.round()} BPM',
                  detail: _t('Live simulated measurement', 'قياس تجريبي لحظي'),
                  color: AppColors.danger,
                ),
                _demoMetricTile(
                  icon: Icons.graphic_eq_rounded,
                  label: _t('Heart Rhythm', 'نظم القلب'),
                  value: _demoRhythm,
                  detail: _t('Current waveform pattern', 'نمط الموجة الحالي'),
                  color: AppColors.accentDeep,
                ),
                _demoMetricTile(
                  icon: Icons.signal_cellular_alt_rounded,
                  label: _t('Signal Quality', 'جودة الإشارة'),
                  value: '${_demoSignalQuality.round()}%',
                  detail: _t('Synthetic stream quality', 'جودة البث التجريبي'),
                  color: AppColors.success,
                ),
                _demoMetricTile(
                  icon: Icons.health_and_safety_rounded,
                  label: _t('Live Risk', 'الخطورة الحالية'),
                  value: '${(riskLevel * 100).round()}% • $riskText',
                  detail: _t(
                      'Simulation-derived screening', 'فحص مشتق من المحاكاة'),
                  color: riskColor,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _card(
              title: _t('Live One-Lead ECG', 'رسم القلب الحي أحادي القناة'),
              icon: Icons.monitor_heart_outlined,
              iconColor: riskColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 285,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                            child: CustomPaint(painter: GridPainter())),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: ECGPainter(ecgPoints),
                          ),
                        ),
                        PositionedDirectional(
                          top: 14,
                          start: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: riskColor.withAlpha(45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_demoHeartRate.round()} BPM  •  $riskText',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (_demoTimer?.isActive ?? false) {
                              _stopDemoStream();
                              _setStatus('ESP32 Demo', 'Paused');
                            } else {
                              _startDemoStream();
                            }
                            setState(() {});
                          },
                          icon: Icon(
                            simulationActive
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            simulationActive
                                ? _t('Pause stream', 'إيقاف مؤقت')
                                : _t('Resume stream', 'استكمال البث'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _demoTick = 0;
                              _demoStage = -1;
                              _demoBeatPhase = 0;
                              riskLevel = 0.18;
                              _demoHeartRate = 76;
                              _demoSignalQuality = 96;
                            });
                            _startDemoStream();
                          },
                          icon: const Icon(Icons.replay_rounded),
                          label:
                              Text(_t('Restart scenario', 'إعادة السيناريو')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _card(
              title:
                  _t('Live AI Screening • Demo', 'الفحص الذكي الحي • تجريبي'),
              icon: Icons.auto_awesome_rounded,
              iconColor: riskColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _demoScreeningState,
                              style: TextStyle(
                                color: riskColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              recommendation,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(riskLevel * 100).round()}%',
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: riskLevel,
                      minHeight: 14,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _snapshotRow(
                    _t('Rhythm interpretation', 'تفسير النظم'),
                    _demoRhythm,
                    AppColors.accentDeep,
                  ),
                  const SizedBox(height: 9),
                  _snapshotRow(
                    _t('Review priority', 'أولوية المراجعة'),
                    riskLevel > 0.62
                        ? _t('Priority review', 'مراجعة ذات أولوية')
                        : riskLevel > 0.35
                            ? _t('Monitor closely', 'مراقبة دقيقة')
                            : _t('Routine monitoring', 'مراقبة روتينية'),
                    riskColor,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(16),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.warning.withAlpha(50)),
                    ),
                    child: Text(
                      _t(
                        'Demonstration mode: ECG, BPM, rhythm, and risk are generated by a controlled patient scenario. They are not a real diagnosis.',
                        'وضع تجريبي: رسم القلب والنبض والنظم والخطورة ناتجة عن سيناريو مريض مُحاكى وليست تشخيصًا حقيقيًا.',
                      ),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _card(
              title: _t('Patient Event Timeline', 'الخط الزمني لحالة المريض'),
              icon: Icons.timeline_rounded,
              iconColor: AppColors.accentDeep,
              child: Column(
                children: _liveEvents.isEmpty
                    ? [_emptyState(_t('No events yet.', 'لا توجد أحداث بعد.'))]
                    : _liveEvents
                        .map(
                          (event) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: event.color.withAlpha(10),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: event.color.withAlpha(35)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 11,
                                  height: 11,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: event.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${event.timeLabel} • ${event.detail}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 18),
            _card(
              title:
                  _t('Connect the Real Prototype', 'توصيل البروتوتايب الحقيقي'),
              icon: Icons.developer_board_rounded,
              iconColor: AppColors.accent,
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  _t(
                    'ESP32 connection controls',
                    'إعدادات اتصال ESP32',
                  ),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '$_connectionMode • $_connectionStatus',
                  style: TextStyle(color: statusColor),
                ),
                children: [
                  TextField(
                    controller: _wifiHost,
                    style: _inputTextStyle(context),
                    decoration: const InputDecoration(
                      labelText: 'ESP32 Wi-Fi URL',
                      prefixIcon: Icon(Icons.router_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _connecting ? null : _connectBle,
                          child: const Text('Connect BLE'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _connecting ? null : _connectWifi,
                          child: const Text('Connect Wi-Fi'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final riskText = riskLevel > 0.6
        ? 'High Risk'
        : (riskLevel > 0.35 ? 'Medium Risk' : 'Low Risk');
    final riskColor = riskLevel > 0.6
        ? AppColors.danger
        : (riskLevel > 0.35 ? AppColors.warning : AppColors.success);
    final statusLower = _connectionStatus.toLowerCase();
    final hasConnectionError = statusLower.contains('error') ||
        statusLower.contains('failed') ||
        statusLower.contains('not');
    final hardwareConnected = !hasConnectionError &&
        statusLower == 'connected' &&
        (_connectionMode == 'BLE' || _connectionMode == 'Wi-Fi');
    final statusColor = hasConnectionError
        ? AppColors.danger
        : hardwareConnected
            ? AppColors.success
            : AppColors.warning;
    final liveAi = _buildLiveMonitoringAiBrief(
      riskLevel: riskLevel,
      connectionMode: _connectionMode,
      connectionStatus: _connectionStatus,
      region: region,
      activeCoils: activeCoils,
      ecgPoints: ecgPoints,
    );

    if (widget.prototypeDemo) {
      return _buildPrototypePatientDemo(
        hardwareConnected: hardwareConnected,
        statusColor: statusColor,
        riskText: riskText,
        riskColor: riskColor,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.prototypeDemo
              ? _t('Prototype Live Monitor', 'مراقبة النموذج الحية')
              : _t('Live Cardiac Monitoring', 'المراقبة القلبية الحية'),
        ),
        actions: [
          _workspaceAction(context),
          _settingsAction(context),
          Container(
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color:
                      hardwareConnected ? AppColors.success : AppColors.warning,
                  size: 12,
                ),
                const SizedBox(width: 5),
                Text(
                  hardwareConnected ? 'LIVE' : 'DEMO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (widget.prototypeDemo) ...[
                _prototypeSystemCard(
                  hardwareConnected: hardwareConnected,
                  statusColor: statusColor,
                ),
                const SizedBox(height: 18),
              ],
              _card(
                title: 'Wearable Connectivity',
                icon: Icons.wifi,
                iconColor: AppColors.accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Mode: $_connectionMode',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _connectionStatus,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _wifiHost,
                      style: _inputTextStyle(context),
                      decoration: const InputDecoration(
                        labelText: 'Wi-Fi base URL (e.g. http://192.168.4.1)',
                        prefixIcon: Icon(Icons.router),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _connecting ? null : _connectBle,
                            child: const Text('Connect BLE'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _connecting ? null : _connectWifi,
                            child: const Text('Connect Wi-Fi'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _connecting ? null : _disconnectAll,
                        child: const Text('Disconnect'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _card(
                title: 'Live Session Snapshot',
                icon: Icons.fact_check_outlined,
                iconColor: AppColors.success,
                child: Column(
                  children: [
                    _snapshotRow(
                        'Stream Mode', _connectionMode, AppColors.primary),
                    const SizedBox(height: 10),
                    _snapshotRow(
                        'Connection Status', _connectionStatus, statusColor),
                    const SizedBox(height: 10),
                    if (widget.prototypeDemo) ...[
                      _snapshotRow(
                        'Session Type',
                        hardwareConnected
                            ? 'Prototype hardware stream'
                            : 'Synthetic prototype demo',
                        hardwareConnected
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(height: 10),
                      _snapshotRow(
                        'Clinical AI',
                        'Not running in demo mode',
                        AppColors.warning,
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      _snapshotRow('Estimated Risk', riskText, riskColor),
                      const SizedBox(height: 10),
                      _snapshotRow(
                        'Detected Region',
                        region == 'Low' ? 'No dominant alert region' : region,
                        AppColors.accent,
                      ),
                      const SizedBox(height: 10),
                    ],
                    _snapshotRow('Window Samples', ecgPoints.length.toString(),
                        AppColors.primary),
                    if (!widget.prototypeDemo) ...[
                      const SizedBox(height: 10),
                      _snapshotRow(
                          'Active Coil Targets',
                          activeCoils.isEmpty ? 'None' : activeCoils.join(', '),
                          AppColors.warning),
                    ],
                  ],
                ),
              ),
              if (!widget.prototypeDemo) ...[
                const SizedBox(height: 18),
                _card(
                  title: 'AI Live Copilot',
                  icon: Icons.auto_awesome,
                  iconColor: liveAi.color,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  liveAi.headline,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  liveAi.summary,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: liveAi.color.withAlpha(18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              liveAi.urgencyLabel,
                              style: TextStyle(
                                color: liveAi.color,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _snapshotRow(
                              'Signal State',
                              liveAi.signalLabel,
                              liveAi.color,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _snapshotRow(
                              'Recommended Action',
                              liveAi.recommendedAction,
                              AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...liveAi.bullets.map(
                        (bullet) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  color: liveAi.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  bullet,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _card(
                title: 'Live Anomaly Timeline',
                icon: Icons.timeline_rounded,
                iconColor: AppColors.primary,
                child: Column(
                  children: _liveEvents.isEmpty
                      ? [
                          _emptyState(
                            'No live monitoring events have been logged yet in this session.',
                          ),
                        ]
                      : _liveEvents
                          .map(
                            (event) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: event.color.withAlpha(10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: event.color.withAlpha(35),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: event.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                event.title,
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              event.timeLabel,
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          event.detail,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            height: 1.4,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(77),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: GridPainter())),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: ECGPainter(ecgPoints),
                      ),
                    ),
                    Positioned(
                      top: 15,
                      left: 15,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'One-Lead Wearable ECG',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          Text(
                            widget.prototypeDemo
                                ? (hardwareConnected
                                    ? 'HARDWARE STREAM'
                                    : 'SIMULATED SIGNAL')
                                : (riskLevel > 0.6 ? 'ALERT' : 'STABLE'),
                            style: TextStyle(
                              color: widget.prototypeDemo
                                  ? AppColors.accentSoft
                                  : riskColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.prototypeDemo) ...[
                const SizedBox(height: 18),
                _prototypeBoundariesCard(),
              ] else ...[
                const SizedBox(height: 18),
                _card(
                  title: 'Vest Coil Array (Concept)',
                  icon: Icons.blur_circular,
                  iconColor: AppColors.accent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detected Region: ${region == 'Low' ? 'None' : region}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CoilArrayWidget(active: activeCoils),
                      const SizedBox(height: 10),
                      Text(
                        activeCoils.isEmpty
                            ? 'No activation'
                            : 'Active coils: ${activeCoils.join(', ')}',
                        style: TextStyle(
                          color: activeCoils.isEmpty
                              ? Colors.grey
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Localized protective stimulation (conceptual)',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _card(
                  title: 'Real-time Risk Level',
                  icon: Icons.analytics_outlined,
                  iconColor: AppColors.accent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: riskLevel,
                          minHeight: 14,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          riskText,
                          style: TextStyle(
                            color: riskColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _card(
                  title: 'Safety Layer',
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.success,
                  child: Column(
                    children: const [
                      SafetyRow(label: 'Current limit', value: 'Enabled'),
                      SafetyRow(label: 'Temperature', value: 'Normal'),
                      SafetyRow(label: 'Max on-time', value: '2s'),
                      SafetyRow(label: 'Kill switch', value: 'Ready'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 55,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _sendSOS,
                    icon: const Icon(Icons.warning_amber_rounded,
                        color: Colors.white),
                    label: const Text(
                      'SOS - EMERGENCY ALERT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _snapshotRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(42)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _card({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _snapshotMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class PatientInsightsPage extends StatelessWidget {
  const PatientInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final weekly = _mockWeeklyBpm();
    final average = weekly.reduce((a, b) => a + b) / weekly.length;
    final peak = weekly.reduce(math.max);
    final low = weekly.reduce(math.min);
    final spread = peak - low;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Insights', 'التحليلات')),
        actions: _topBarActions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _insightHeader(),
          const SizedBox(height: 16),
          _card(
            title: 'Weekly BPM Trend',
            child: SizedBox(
              height: 180,
              child: CustomPaint(painter: TrendPainter(weekly)),
            ),
          ),
          const SizedBox(height: 14),
          _card(
            title: 'Trend Summary Table',
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.35),
                1: FlexColumnWidth(1.0),
                2: FlexColumnWidth(1.45),
              },
              children: [
                _summaryHeader('Metric', 'Value', 'Interpretation'),
                _summaryRow('Average BPM', average.toStringAsFixed(1),
                    'Recent session mean', true),
                _summaryRow(
                    'Peak BPM', '$peak', 'Highest recorded point', false),
                _summaryRow(
                    'Lowest BPM', '$low', 'Lowest recorded point', true),
                _summaryRow(
                    'Range', '$spread bpm', 'Overall variability span', false),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            title: 'Monitoring Notes',
            child: Column(
              children: [
                _noteStrip(
                    'Trend profile',
                    spread > 18
                        ? 'Wider fluctuation across recent sessions'
                        : 'Stable fluctuation across recent sessions'),
                const SizedBox(height: 10),
                _noteStrip('Use case',
                    'Designed for longitudinal review, not standalone diagnosis'),
                const SizedBox(height: 10),
                _noteStrip('Recommended action',
                    'Correlate this trend with uploaded ECG reports and wearable sessions'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightHeader() {
    return const AppHeroBanner(
      title: 'Insights',
      subtitle: 'Trend-focused review of recent monitoring sessions',
      icon: Icons.insights,
      gradient: AppGradients.hero,
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  static TableRow _summaryHeader(String a, String b, String c) {
    return TableRow(
      decoration: BoxDecoration(color: AppColors.primary.withAlpha(18)),
      children: [
        _summaryCell(a, header: true),
        _summaryCell(b, header: true),
        _summaryCell(c, header: true),
      ],
    );
  }

  static TableRow _summaryRow(String a, String b, String c, bool even) {
    return TableRow(
      decoration:
          BoxDecoration(color: even ? Colors.white : AppColors.background),
      children: [
        _summaryCell(a),
        _summaryCell(b, color: AppColors.primary, weight: FontWeight.w700),
        _summaryCell(c),
      ],
    );
  }

  static Widget _summaryCell(
    String text, {
    bool header = false,
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? (header ? AppColors.primary : Colors.black87),
          fontWeight: header ? FontWeight.w700 : weight,
          fontSize: 12,
        ),
      ),
    );
  }

  static Widget _noteStrip(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PatientHistoryPage extends StatefulWidget {
  const PatientHistoryPage({super.key});

  @override
  State<PatientHistoryPage> createState() => _PatientHistoryPageState();
}

class _PatientHistoryPageState extends State<PatientHistoryPage> {
  final ApiService _api = ApiService(baseUrl: _apiBaseUrl());
  late Future<PatientHistorySnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PatientHistorySnapshot> _load() async {
    final username = ApiService.currentUsername ?? '';
    final patients = await _api.listPatients();
    PatientModel? patient;
    for (final item in patients) {
      if (item.name.trim().toLowerCase() == username.trim().toLowerCase()) {
        patient = item;
        break;
      }
    }
    ReportModel? report;
    List<AppointmentModel> appointments = const [];
    if (patient?.id != null) {
      try {
        report = await _api.getReport(patient!.id!);
      } catch (_) {}
      try {
        appointments = await _api.listAppointments(patientId: patient!.id!);
      } catch (_) {}
    }
    return PatientHistorySnapshot(
        patient: patient, report: report, appointments: appointments);
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('History', 'السجل')),
        actions: _topBarActions(context),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<PatientHistorySnapshot>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _retryCard(
                    message: _t(
                      'History is unavailable right now. Retry after checking backend connectivity.',
                      'السجل غير متاح الآن. أعد المحاولة بعد التحقق من اتصال الخادم.',
                    ),
                    onRetry: _refresh,
                  ),
                ],
              );
            }
            final data = snapshot.data ??
                const PatientHistorySnapshot(
                    patient: null, report: null, appointments: []);
            final report = data.report;
            final appointments = data.appointments;
            final trendInsight = _buildTrendComparison(report);
            final rows = <(String, String, String, Color)>[];
            if (report != null) {
              for (var i = 0; i < report.labels.length; i++) {
                rows.add((
                  _safeDateLabel(report.createdAt),
                  i < report.bpm.length ? '${report.bpm[i]} bpm' : '--',
                  i < report.riskLevels.length
                      ? report.riskLevels[i]
                      : report.labels[i],
                  _riskColor(i < report.riskLevels.length
                      ? report.riskLevels[i]
                      : 'Low'),
                ));
              }
            }
            for (final appointment in appointments) {
              rows.add((
                _safeDateLabel(appointment.when),
                _safeTimeLabel(appointment.when),
                '${_t("Visit", "زيارة")} • ${appointment.status}',
                appointment.status == 'Confirmed'
                    ? AppColors.success
                    : AppColors.warning,
              ));
            }
            return SecondaryPageShell(
              title: _t('Analysis History', 'سجل التحليل'),
              subtitle: _t(
                  'Timeline of prior screenings, uploads, reports, and follow-up sessions',
                  'الخط الزمني للفحوصات والرفع والتقارير وجلسات المتابعة'),
              icon: Icons.timeline_rounded,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: AppMetricTile(
                            label: _t('Entries', 'العناصر'),
                            value: '${rows.length}',
                            caption: _t(
                                'Stored history records', 'السجلات المحفوظة'),
                            accent: AppColors.accent,
                            icon: Icons.history_rounded)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: AppMetricTile(
                            label: _t('Reports', 'التقارير'),
                            value: '${report?.labels.length ?? 0}',
                            caption: _t('Saved report points',
                                'نقاط التقارير المحفوظة'),
                            accent: AppColors.success,
                            icon: Icons.description_outlined)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: AppMetricTile(
                            label: _t('Visits', 'الزيارات'),
                            value: '${appointments.length}',
                            caption:
                                _t('Follow-up appointments', 'مواعيد المتابعة'),
                            accent: AppColors.secondary,
                            icon: Icons.event_note_rounded)),
                  ],
                ),
                const SizedBox(height: 16),
                glassListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title:
                            _t('AI History Comparison', 'مقارنة السجل الذكية'),
                        subtitle: _t(
                          'Automatic comparison of the latest stored ECG history points.',
                          'مقارنة تلقائية بين أحدث نقاط ECG المحفوظة في السجل.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: trendInsight.color.withAlpha(12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: trendInsight.color.withAlpha(38)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trendInsight.headline,
                              style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: trendInsight.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              trendInsight.summary,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, height: 1.45),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: AppMetricTile._miniStat(
                                  _t('BPM Change', 'تغير النبض'),
                                  trendInsight.bpmDeltaLabel)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: AppMetricTile._miniStat(
                                  _t('Risk Shift', 'تغير الخطر'),
                                  trendInsight.riskShiftLabel)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                glassListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title: _t('Medical timeline', 'الخط الزمني الطبي'),
                        subtitle: _t(
                          'A structured view of previous ECG analysis sessions and care follow-up.',
                          'عرض منظم لجلسات تحليل ECG السابقة ومتابعات الرعاية.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (rows.isEmpty)
                        _emptyState(_t('No history has been stored yet.',
                            'لا يوجد سجل محفوظ حتى الآن.'))
                      else
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.15),
                            1: FlexColumnWidth(1.0),
                            2: FlexColumnWidth(1.8),
                          },
                          children: [
                            AnalysisResultPage._tableHeader(
                                'Date', 'Metric', 'Session'),
                            ...List.generate(rows.length, (i) {
                              final row = rows[i];
                              return AnalysisResultPage._tableRow(
                                row.$1,
                                row.$2,
                                row.$3,
                                i.isEven,
                                row.$4,
                              );
                            }),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (rows.isEmpty)
                  _emptyState(_t(
                      'No patient reports or appointments are available yet.',
                      'لا توجد تقارير أو مواعيد متاحة للمريض حتى الآن.'))
                else
                  ...rows.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _historyCard(
                          HistoryItem(
                            title: item.$3,
                            subtitle: item.$1,
                            time: item.$2,
                            color: item.$4,
                          ),
                        ),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _historyCard(HistoryItem item) {
    return glassListCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: item.color.withAlpha(38),
            child: Icon(Icons.monitor_heart, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(item.subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Text(
            item.time,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class PatientAlertsPage extends StatelessWidget {
  const PatientAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = _mockPatientAlerts();
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Alerts', 'Ø§Ù„ØªÙ†Ø¨ÙŠÙ‡Ø§Øª')),
        actions: _topBarActions(context),
      ),
      body: SecondaryPageShell(
        title: _t('Alerts', 'التنبيهات'),
        subtitle: _t(
            'Review patient-facing safety notifications and follow-up prompts',
            'راجع تنبيهات السلامة والتنبيهات الموجهة للمريض'),
        icon: Icons.notifications_active_outlined,
        children: List.generate(items.length, (i) {
          final item = items[i];
          return glassListCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: item.color.withAlpha(26),
                  child: Icon(Icons.warning_amber, color: item.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text(item.detail,
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Text(item.time,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class CarePlanPage extends StatelessWidget {
  const CarePlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = _mockCarePlan();
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Care Plan', 'Ø®Ø·Ø© Ø§Ù„Ù…ØªØ§Ø¨Ø¹Ø©')),
        actions: _topBarActions(context),
      ),
      body: SecondaryPageShell(
        title: _t('Care Plan', 'خطة المتابعة'),
        subtitle: _t(
            'Daily care tasks, reminders, and monitoring follow-up items',
            'مهام المتابعة اليومية والتذكيرات وعناصر الرعاية'),
        icon: Icons.assignment_turned_in_outlined,
        children: List.generate(items.length, (i) {
          final item = items[i];
          return glassListCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  item.done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: item.done ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text(item.detail,
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Text(item.time,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      _t('How do I upload ECG files?',
          'ÙƒÙŠÙ Ø£Ø±ÙØ¹ Ù…Ù„ÙØ§Øª Ø±Ø³Ù… Ø§Ù„Ù‚Ù„Ø¨ØŸ'),
      _t('What does High Risk mean?', 'Ù…Ø§Ø°Ø§ ÙŠØ¹Ù†ÙŠ Ø®Ø·Ø± Ù…Ø±ØªÙØ¹ØŸ'),
      _t('How to contact my doctor?',
          'ÙƒÙŠÙ Ø£ØªÙˆØ§ØµÙ„ Ù…Ø¹ Ø§Ù„Ø·Ø¨ÙŠØ¨ØŸ'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Help Center', 'Ù…Ø±ÙƒØ² Ø§Ù„Ù…Ø³Ø§Ø¹Ø¯Ø©')),
        actions: _topBarActions(context),
      ),
      body: SecondaryPageShell(
        title: _t('Help Center', 'مركز المساعدة'),
        subtitle: _t(
            'Frequently asked questions and guided help for ECG workflows',
            'أسئلة شائعة ومساعدة موجهة لمسارات ECG'),
        icon: Icons.help_outline,
        children: [
          ...faqs.map(
            (q) => glassListCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.help, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SessionLogPage extends StatelessWidget {
  const SessionLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = _mockSessionLogs();
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Session Logs', 'Ø³Ø¬Ù„ Ø§Ù„Ø¬Ù„Ø³Ø§Øª')),
        actions: _topBarActions(context),
      ),
      body: SecondaryPageShell(
        title: _t('Session Logs', 'سجل الجلسات'),
        subtitle: _t(
            'Timeline of wearable monitoring sessions and screening outcomes',
            'الخط الزمني لجلسات المراقبة ونتائج الفحص'),
        icon: Icons.monitor_heart_outlined,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final color = item.risk == 'High'
              ? AppColors.danger
              : item.risk == 'Medium'
                  ? AppColors.warning
                  : AppColors.success;
          return glassListCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withAlpha(26),
                  child: Icon(Icons.monitor_heart, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text(item.detail,
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(item.time,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.risk,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        }),
      ),
    );
  }
}

class PatientProfilePage extends StatefulWidget {
  final String username;
  const PatientProfilePage({super.key, required this.username});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  Future<void> _pickDoctor() async {
    final doctors = AppState.doctors;
    if (doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('No doctor accounts are available yet.',
                'لا توجد حسابات أطباء متاحة الآن.'),
          ),
        ),
      );
      return;
    }

    final query = ValueNotifier<String>('');
    final picked = await showModalBottomSheet<AppDoctor>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: GlassPanel(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            radius: BorderRadius.circular(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.accentSoft,
                      child:
                          Icon(Icons.add_rounded, color: AppColors.accentDeep),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('Choose Doctor', 'اختر الطبيب'),
                            style: Theme.of(sheetContext)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            _t(
                              'Tap any doctor to link this patient profile.',
                              'اضغط على أي طبيب لربطه بملف المريض.',
                            ),
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  style: _inputTextStyle(sheetContext),
                  decoration: InputDecoration(
                    hintText: _t('Search by doctor name or specialty',
                        'ابحث باسم الطبيب أو التخصص'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: ValueListenableBuilder<String>(
                      valueListenable: query,
                      builder: (_, value, __) {
                        if (value.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          onPressed: () => query.value = '',
                          icon: const Icon(Icons.close_rounded),
                        );
                      },
                    ),
                  ),
                  onChanged: (value) =>
                      query.value = value.trim().toLowerCase(),
                ),
                const SizedBox(height: 14),
                if (AppState.selectedDoctor != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.link_off_rounded),
                      label: Text(_t('Keep current doctor link',
                          'الاحتفاظ بالطبيب الحالي')),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: query,
                    builder: (_, search, __) {
                      final filtered = doctors.where((doctor) {
                        if (search.isEmpty) return true;
                        final haystack =
                            '${doctor.name} ${doctor.specialty} ${doctor.clinic} ${doctor.phone}'
                                .toLowerCase();
                        return haystack.contains(search);
                      }).toList();
                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            _t('No doctors matched this search.',
                                'لا يوجد أطباء مطابقون لهذا البحث.'),
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doctor = filtered[index];
                          final active =
                              AppState.selectedDoctor?.email == doctor.email;
                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.pop(sheetContext, doctor),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.accentSoft
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: active
                                      ? AppColors.accent
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        AppColors.accent.withAlpha(24),
                                    child: const Icon(
                                        Icons.local_hospital_outlined,
                                        color: AppColors.accentDeep),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doctor.name,
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${doctor.specialty} • ${doctor.clinic}',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          doctor.phone,
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (active)
                                    const Icon(Icons.check_circle_rounded,
                                        color: AppColors.success),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) return;
    setState(() {
      AppState.upsertDoctor(picked);
      AppState.selectedDoctor = picked;
    });
    await AppState.persistSession(
      username: widget.username,
      workspace: 'patient_home',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(_t('Doctor linked successfully.', 'تم ربط الطبيب بنجاح.'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quickActions = [
      (
        _t('Analyze ECG', 'تحليل ECG'),
        Icons.auto_graph,
        AppColors.accent,
        () => Navigator.push(
              context,
              _fadeRoute(
                AnalysisHubPage(
                  api: ApiService(baseUrl: _apiBaseUrl()),
                  roleTitle: _t('Patient Analysis Hub', 'بوابة تحليل المريض'),
                  roleSubtitle: _t(
                    'Move from wearable monitoring or uploaded records into a richer AI result flow.',
                    'انتقل من المراقبة أو الملفات المرفوعة إلى مسار نتيجة أقوى وأكثر وضوحًا.',
                  ),
                  accentColor: AppColors.accent,
                  sourceLabel: 'Patient',
                  presetDraft: AnalysisSessionDraft(
                    patientName: widget.username,
                    patientAge: '',
                    patientSex: 'Not specified',
                    doctorName: AppState.selectedDoctor?.name ?? '',
                    notes: '',
                    analysisSource: 'Patient hub',
                  ),
                ),
              ),
            )
      ),
      (
        _t('Care Visits', 'زيارات المتابعة'),
        Icons.event_available,
        AppColors.accent,
        () => _openPatientAppointments(context)
      ),
      (
        _t('Report Library', 'مكتبة التقارير'),
        Icons.description_outlined,
        AppColors.success,
        () => _openPatientReports(context)
      ),
      (
        _t('Messages', 'الرسائل'),
        Icons.chat_bubble_outline,
        AppColors.accent,
        () => Navigator.push(
            context, _fadeRoute(PatientChatPage(username: widget.username)))
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Profile', 'الملف')),
        actions: [
          _workspaceAction(context),
          IconButton(
            onPressed: _pickDoctor,
            icon: const Icon(Icons.add_rounded),
            tooltip: _t('Add doctor optionally', 'إضافة طبيب بشكل اختياري'),
          ),
          _settingsAction(context),
        ],
      ),
      body: SecondaryPageShell(
        title: widget.username,
        subtitle: _t(
            'Patient access profile, quick actions, and connected care context',
            'ملف دخول المريض والإجراءات السريعة وسياق الرعاية المتصل'),
        icon: Icons.person_outline_rounded,
        children: [
          _profileHeader(),
          const SizedBox(height: 14),
          _patientSnapshot(),
          const SizedBox(height: 16),
          _patientAiCompanionCard(),
          const SizedBox(height: 16),
          _sectionTitle(_t('Quick Actions', 'إجراءات سريعة')),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width >= 760 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.18,
            children: quickActions
                .map(
                  (item) => InkWell(
                    onTap: item.$4,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    child: AppMetricTile(
                      label: item.$1,
                      value: _t('Open', 'فتح'),
                      caption:
                          _t('Primary patient workflow', 'مسار مريض أساسي'),
                      accent: item.$3,
                      icon: item.$2,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          _actionTile(
            context,
            title: _t('Settings', 'الإعدادات'),
            icon: Icons.settings,
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              _fadeRoute(const SettingsPage()),
            ),
          ),
          _actionTile(
            context,
            title: _t('Alerts', 'التنبيهات'),
            icon: Icons.notifications_active_outlined,
            color: AppColors.warning,
            onTap: () => Navigator.push(
              context,
              _fadeRoute(const PatientAlertsPage()),
            ),
          ),
          _actionTile(
            context,
            title: _t('Care Plan', 'خطة المتابعة'),
            icon: Icons.assignment_turned_in_outlined,
            color: AppColors.success,
            onTap: () => Navigator.push(
              context,
              _fadeRoute(const CarePlanPage()),
            ),
          ),
          _actionTile(
            context,
            title: _t('Monitoring Sessions', 'جلسات المراقبة'),
            icon: Icons.timeline,
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              _fadeRoute(const SessionLogPage()),
            ),
          ),
          _actionTile(
            context,
            title: _t('Help & Support', 'المساعدة والدعم'),
            icon: Icons.help_outline,
            color: AppColors.accent,
            onTap: () => Navigator.push(
              context,
              _fadeRoute(const HelpCenterPage()),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(_t('Doctor Connection', 'ربط طبيب')),
          const SizedBox(height: 10),
          _doctorCard(context),
          const SizedBox(height: 16),
          _sectionTitle(_t('Emergency Contacts', 'جهات الطوارئ')),
          const SizedBox(height: 10),
          _contactTile(
            _t('Selected doctor', 'الطبيب المختار'),
            AppState.selectedDoctor?.name ?? _t('Not linked', 'غير مرتبط'),
            AppState.selectedDoctor?.phone ?? _t('Not available', 'غير متاح'),
          ),
          _contactTile(
            _t('Emergency contact', 'جهة اتصال للطوارئ'),
            _t('Not set', 'غير محددة'),
            _t('Add manually later', 'أضفها يدويًا لاحقًا'),
          ),
          const SizedBox(height: 16),
          _sectionTitle(_t('Preferences', 'التفضيلات')),
          const SizedBox(height: 10),
          _settingTile(
              _t('Notifications', 'الإشعارات'), _t('Enabled', 'مفعلة')),
          _settingTile(_t('Data Sync', 'مزامنة البيانات'),
              _t('Every 15 minutes', 'كل 15 دقيقة')),
          _settingTile(_t('Connected Device', 'الجهاز المتصل'),
              _t('Wearable ECG vest', 'سترة ECG القابلة للارتداء')),
        ],
      ),
    );
  }

  Future<PatientModel?> _resolveCurrentPatient() async {
    final api = ApiService(baseUrl: _apiBaseUrl());
    final patients = await api.listPatients();
    for (final patient in patients) {
      if (patient.name.trim().toLowerCase() ==
          widget.username.trim().toLowerCase()) {
        return patient;
      }
    }
    return null;
  }

  Future<void> _openPatientAppointments(BuildContext context) async {
    try {
      final patient = await _resolveCurrentPatient();
      if (!context.mounted) return;
      if (patient == null || patient.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(
                'No saved patient record was found for this profile yet.',
                'لم يتم العثور على سجل مريض محفوظ لهذا الحساب بعد.')),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        _fadeRoute(PatientAppointmentsPage(patient: patient)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Unable to open care visits right now.',
              'تعذر فتح زيارات المتابعة الآن.')),
        ),
      );
    }
  }

  Future<void> _openPatientReports(BuildContext context) async {
    try {
      final patient = await _resolveCurrentPatient();
      if (!context.mounted) return;
      if (patient == null || patient.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(
                'No saved patient record was found for this profile yet.',
                'لم يتم العثور على سجل مريض محفوظ لهذا الحساب بعد.')),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        _fadeRoute(PatientReportsPage(patient: patient)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Unable to open the report library right now.',
              'تعذر فتح مكتبة التقارير الآن.')),
        ),
      );
    }
  }

  Widget _profileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.accentGlow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.surface,
            child: Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _t('Patient access profile', 'ملف دخول المريض'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(31),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _t('Monitoring Active', 'المراقبة نشطة'),
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientSnapshot() {
    final doctorName = AppState.selectedDoctor?.name ?? 'Not assigned';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient Status Snapshot',
            style: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Current monitoring and care context',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _snapshotMetric(
                      'Device', 'Wearable ECG vest', AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(
                  child: _snapshotMetric(
                      'Care Owner', doctorName, AppColors.accent)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _snapshotMetric(
                      'Sync', 'Every 15 min', AppColors.success)),
              const SizedBox(width: 10),
              Expanded(
                  child: _snapshotMetric(
                      'Status', 'Monitoring active', AppColors.warning)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _patientAiCompanionCard() {
    final brief = _buildPatientAiCompanionBrief(
      doctor: AppState.selectedDoctor,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: _t('AI Care Companion', 'المرافق الذكي للرعاية'),
            subtitle: _t(
              'A patient-focused AI layer that recommends the next useful action in your care flow.',
              'طبقة ذكية موجهة للمريض تقترح الخطوة الأكثر فائدة داخل مسار المتابعة.',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: brief.color.withAlpha(12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: brief.color.withAlpha(35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brief.headline,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: brief.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  brief.summary,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _snapshotMetric(
                  'Readiness',
                  brief.readinessLabel,
                  brief.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _snapshotMetric(
                  'Doctor State',
                  brief.doctorStateLabel,
                  AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...brief.bullets.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 10, color: brief.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _snapshotMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return AppSectionHeader(title: text);
  }

  Widget _doctorCard(BuildContext context) {
    final doctor = AppState.selectedDoctor;
    if (doctor == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.background,
              child: Icon(Icons.medical_services, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No clinician has been linked to this profile yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: _pickDoctor,
              child: Text(_t('Assign', 'ربط')),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accent.withAlpha(31),
            child: const Icon(Icons.medical_services, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${doctor.specialty} - ${doctor.clinic}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _pickDoctor,
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _contactTile(String tag, String name, String phone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accent.withAlpha(31),
            child: const Icon(Icons.call, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$tag: $name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(phone, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          const Icon(Icons.settings, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(31),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class CoilArrayWidget extends StatelessWidget {
  final List<String> active;
  const CoilArrayWidget({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final coils = List.generate(8, (i) => 'C${i + 1}');

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: coils.map((c) {
        final isOn = active.contains(c);
        final col = isOn ? AppColors.warning : Colors.grey.shade300;
        final border = isOn ? AppColors.danger : Colors.grey.shade400;
        return Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: col.withAlpha(isOn ? 64 : 255),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: isOn ? 2 : 1),
            boxShadow: [
              if (isOn)
                BoxShadow(
                  color: AppColors.warning.withAlpha(89),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Center(
            child: Text(
              c,
              style: TextStyle(
                color: isOn ? AppColors.danger : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PatientAppointmentsPage extends StatefulWidget {
  final PatientModel patient;
  const PatientAppointmentsPage({super.key, required this.patient});

  @override
  State<PatientAppointmentsPage> createState() =>
      _PatientAppointmentsPageState();
}

class _PatientAppointmentsPageState extends State<PatientAppointmentsPage> {
  final ApiService _api = ApiService(baseUrl: _apiBaseUrl());
  late Future<List<AppointmentModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.listAppointments(patientId: widget.patient.id);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _api.listAppointments(patientId: widget.patient.id);
    });
  }

  Future<void> _add() async {
    final created = await Navigator.push<bool>(
      context,
      _fadeRoute<bool>(AddAppointmentPage(patient: widget.patient, api: _api)),
    );
    if (created == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('${_t('Appointments', 'المواعيد')} - ${widget.patient.name}'),
        actions: _topBarActions(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AppointmentModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _retryCard(
                    message:
                        _t('Failed to load appointments', 'فشل تحميل المواعيد'),
                    onRetry: _refresh,
                  ),
                ],
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  AppHeroBanner(
                    title: widget.patient.name,
                    subtitle:
                        'Upcoming visits, follow-up scheduling, and coordination history',
                    icon: Icons.event_note_outlined,
                    gradient: AppGradients.hero,
                  ),
                  const SizedBox(height: 16),
                  const Center(child: Text('No appointments yet.')),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                AppHeroBanner(
                  title: widget.patient.name,
                  subtitle:
                      'Upcoming visits, follow-up scheduling, and coordination history',
                  icon: Icons.event_note_outlined,
                  gradient: AppGradients.hero,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title: _t('Appointment table', 'جدول المواعيد'),
                        subtitle: _t('Patient-side follow-up queue',
                            'قائمة المتابعة الخاصة بالمريض'),
                      ),
                      const SizedBox(height: 12),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(1.8),
                          2: FlexColumnWidth(0.9),
                        },
                        children: [
                          AnalysisResultPage._tableHeader(
                              'Doctor', 'When', 'Status'),
                          ...List.generate(items.length, (i) {
                            final item = items[i];
                            final color = item.status == 'Confirmed'
                                ? AppColors.success
                                : AppColors.warning;
                            return AnalysisResultPage._tableRow(
                              item.doctorName,
                              item.when,
                              item.status,
                              i.isEven,
                              color,
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...items.map((item) {
                  final status = item.status;
                  final color = status == 'Confirmed'
                      ? AppColors.success
                      : AppColors.warning;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withAlpha(31),
                            child: Icon(Icons.event, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.doctorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(item.when,
                                    style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withAlpha(26),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PatientReportsPage extends StatefulWidget {
  final PatientModel patient;
  const PatientReportsPage({super.key, required this.patient});

  @override
  State<PatientReportsPage> createState() => _PatientReportsPageState();
}

class _PatientReportsPageState extends State<PatientReportsPage> {
  final ApiService _api = ApiService(baseUrl: _apiBaseUrl());
  bool _exporting = false;
  late Future<ReportModel> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _api.getReport(widget.patient.id ?? 0);
  }

  void _reload() {
    setState(() => _reportFuture = _api.getReport(widget.patient.id ?? 0));
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final path = await _api.exportReport();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report saved to: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_t('Reports', 'التقارير')} - ${widget.patient.name}'),
        actions: _topBarActions(context),
      ),
      body: SecondaryPageShell(
        title: widget.patient.name,
        subtitle:
            'Export and review your latest AI-assisted ECG report summaries',
        icon: Icons.description_outlined,
        children: [
          FutureBuilder<ReportModel>(
            future: _reportFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _retryCard(
                  message: _t('Failed to load report',
                      'ÙØ´Ù„ ØªØ­Ù…ÙŠÙ„ Ø§Ù„ØªÙ‚Ø±ÙŠØ±'),
                  onRetry: _reload,
                );
              }
              final report = snapshot.data;
              if (report == null) return const SizedBox.shrink();
              final trendInsight = _buildTrendComparison(report);
              final latestBpm = report.bpm.isNotEmpty ? report.bpm.last : 0;
              final latestRisk =
                  report.riskLevels.isNotEmpty ? report.riskLevels.last : 'Low';
              final riskColor = latestRisk == 'High'
                  ? AppColors.danger
                  : latestRisk == 'Medium'
                      ? AppColors.warning
                      : AppColors.success;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppMetricTile(
                          label: _t('Latest Risk', 'آخر خطر'),
                          value: latestRisk,
                          caption: _t(
                              'Most recent report risk label', 'آخر تصنيف خطر'),
                          accent: riskColor,
                          icon: Icons.flag_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppMetricTile(
                          label: _t('Latest BPM', 'آخر نبض'),
                          value: '$latestBpm',
                          caption: _t('Latest stored heart rate point',
                              'آخر نقطة نبض محفوظة'),
                          accent: AppColors.accent,
                          icon: Icons.favorite_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  glassListCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSectionHeader(
                          title:
                              _t('AI Report Reading', 'قراءة التقرير الذكية'),
                          subtitle: _t(
                            'A quick summary of the latest report trajectory for this patient.',
                            'ملخص سريع لمسار أحدث تقرير لهذا المريض.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: trendInsight.color.withAlpha(12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: trendInsight.color.withAlpha(38)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trendInsight.headline,
                                style: GoogleFonts.sora(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: trendInsight.color,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                trendInsight.summary,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.45),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppMetricTile._miniStat(
                                _t('BPM Change', 'تغير النبض'),
                                trendInsight.bpmDeltaLabel,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppMetricTile._miniStat(
                                _t('Risk Shift', 'تغير الخطر'),
                                trendInsight.riskShiftLabel,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...trendInsight.bullets.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Icon(Icons.circle,
                                      size: 10, color: trendInsight.color),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  glassListCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weekly BPM Trend',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 160,
                          child: CustomPaint(
                            painter: TrendPainter(
                                report.bpm.map((e) => e.toDouble()).toList()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  glassListCard(
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined,
                            color: AppColors.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _t('Download detailed PDF report',
                                'تنزيل تقرير PDF التفصيلي'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _exporting ? null : _export,
                          child: Text(_exporting ? 'Exporting...' : 'Export'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class DoctorPatientsPage extends StatefulWidget {
  final ApiService api;
  const DoctorPatientsPage({super.key, required this.api});

  @override
  State<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends State<DoctorPatientsPage> {
  late Future<List<PatientModel>> _patientsFuture;

  @override
  void initState() {
    super.initState();
    _patientsFuture = widget.api.listPatients();
  }

  Future<void> _refresh() async {
    setState(() {
      _patientsFuture = widget.api.listPatients();
    });
  }

  Future<void> _openAddPatient() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => AddPatientPage(api: widget.api),
      ),
    );
    if (created == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Management'),
        actions: _topBarActions(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPatient,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Patient', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<PatientModel>>(
          future: _patientsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _retryCard(
                    message: _patientLoadMessage(snapshot.error),
                    onRetry: _refresh,
                  ),
                ],
              );
            }
            final patients = snapshot.data ?? [];
            if (patients.isEmpty) {
              return SecondaryPageShell(
                title: 'Patient Management',
                subtitle:
                    'Registry, search, and follow-up access for doctor workflows',
                icon: Icons.people_alt_outlined,
                children: const [
                  Center(
                      child: Text(
                          'No patients yet. Tap "Add Patient" to create one.')),
                ],
              );
            }
            return SecondaryPageShell(
              title: 'Patient Management',
              subtitle:
                  'Registry, search, and follow-up access for doctor workflows',
              icon: Icons.people_alt_outlined,
              children: [
                glassListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title: _t('Patient table', 'جدول المرضى'),
                        subtitle: _t(
                            'Quick registry view for the current clinic',
                            'عرض سريع لسجل المرضى في العيادة الحالية'),
                      ),
                      const SizedBox(height: 12),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.3),
                          1: FlexColumnWidth(1.0),
                          2: FlexColumnWidth(1.5),
                        },
                        children: [
                          AnalysisResultPage._tableHeader(
                              'Patient', 'Age', 'Profile'),
                          ...List.generate(patients.length, (i) {
                            final p = patients[i];
                            return AnalysisResultPage._tableRow(
                              p.name,
                              '${p.age ?? '-'}',
                              p.gender ?? 'Unknown',
                              i.isEven,
                              AppColors.accent,
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...patients.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassPanel(
                        padding: const EdgeInsets.all(16),
                        radius: BorderRadius.circular(AppRadii.md),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.accent.withAlpha(31),
                              child: const Icon(Icons.person,
                                  color: AppColors.accent),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Age: ${p.age ?? '-'} - ${p.gender ?? 'Unknown'}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  if ((p.phone ?? '').isNotEmpty)
                                    Text(
                                      p.phone!,
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AddPatientPage extends StatefulWidget {
  final ApiService api;
  const AddPatientPage({super.key, required this.api});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  String _gender = 'Male';
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ageValue =
        _age.text.trim().isEmpty ? null : int.tryParse(_age.text.trim());
    try {
      await widget.api.createPatient(
        PatientModel(
          name: _name.text.trim(),
          age: ageValue,
          gender: _gender,
          phone: _phone.text.trim(),
          notes: _notes.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Add Patient', 'إضافة مريض')),
        actions: _topBarActions(context),
      ),
      body: Form(
        key: _formKey,
        child: SecondaryPageShell(
          title: _t('New Patient Profile', 'ملف مريض جديد'),
          subtitle: _t(
              'Create a structured patient record for analysis, visits, and report linkage',
              'أنشئ ملف مريض منظم للتحليل والزيارات وربط التقارير'),
          icon: Icons.person_add_alt_1_outlined,
          children: [
            glassListCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _formField(
                      _name, _t('Full Name', 'الاسم الكامل'), Icons.person,
                      required: true),
                  const SizedBox(height: 12),
                  _formField(_age, _t('Age', 'العمر'), Icons.cake,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: InputDecoration(
                      labelText: _t('Gender', 'النوع'),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                  ),
                  const SizedBox(height: 12),
                  _formField(_phone, _t('Phone', 'الهاتف'), Icons.phone),
                  const SizedBox(height: 12),
                  _formField(_notes, _t('Notes', 'ملاحظات'), Icons.notes,
                      maxLines: 3),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving
                          ? _t('Saving...', 'جارٍ الحفظ...')
                          : _t('Save Patient', 'حفظ المريض')),
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

  Widget _formField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: _inputTextStyle(context),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class PatientPickerPage extends StatefulWidget {
  final ApiService api;
  const PatientPickerPage({super.key, required this.api});

  @override
  State<PatientPickerPage> createState() => _PatientPickerPageState();
}

class _PatientPickerPageState extends State<PatientPickerPage> {
  late Future<List<PatientModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.listPatients();
  }

  void _reload() {
    setState(() => _future = widget.api.listPatients());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Select Patient', 'اختر المريض')),
        actions: _topBarActions(context),
      ),
      body: FutureBuilder<List<PatientModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _retryCard(
                  message: _patientLoadMessage(snapshot.error),
                  onRetry: _reload,
                ),
              ],
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return SecondaryPageShell(
              title: 'Select Patient',
              subtitle:
                  'Choose a saved patient profile to continue with messaging, appointments, or analysis',
              icon: Icons.person_search_outlined,
              children: const [
                Center(child: Text('No patients yet.')),
              ],
            );
          }
          return SecondaryPageShell(
            title: 'Select Patient',
            subtitle:
                'Choose a saved patient profile to continue with messaging, appointments, or analysis',
            icon: Icons.person_search_outlined,
            children: [
              ...items.map((p) => glassListCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.accent.withAlpha(20),
                        child:
                            const Icon(Icons.person, color: AppColors.accent),
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      subtitle: Text(
                          'Age: ${p.age ?? '-'} - ${p.gender ?? 'Unknown'}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pop(context, p),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class AddAppointmentPage extends StatefulWidget {
  final PatientModel patient;
  final ApiService api;
  const AddAppointmentPage(
      {super.key, required this.patient, required this.api});

  @override
  State<AddAppointmentPage> createState() => _AddAppointmentPageState();
}

class _AddAppointmentPageState extends State<AddAppointmentPage> {
  final _doctor = TextEditingController();
  final _when = TextEditingController();
  final _notes = TextEditingController();
  String _status = 'Pending';
  bool _saving = false;

  Future<void> _save() async {
    if (_doctor.text.trim().isEmpty || _when.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.api.createAppointment(
        AppointmentModel(
          id: 0,
          patientId: widget.patient.id ?? 0,
          doctorName: _doctor.text.trim(),
          when: _when.text.trim(),
          status: _status,
          notes: _notes.text.trim(),
          createdAt: '',
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Appointment'),
        actions: _topBarActions(context),
      ),
      body: SecondaryPageShell(
        title: widget.patient.name,
        subtitle:
            'Create a new follow-up visit or review appointment for this patient',
        icon: Icons.event_available,
        children: [
          glassListCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _formField(_doctor, _t('Doctor Name', 'اسم الطبيب'),
                    Icons.medical_services),
                const SizedBox(height: 12),
                _formField(
                  _when,
                  _t('When (e.g. 2026-08-10 14:00)',
                      'الموعد (مثال 2026-08-10 14:00)'),
                  Icons.event,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: InputDecoration(
                    labelText: _t('Status', 'الحالة'),
                    prefixIcon: const Icon(Icons.flag_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(
                        value: 'Confirmed', child: Text('Confirmed')),
                    DropdownMenuItem(
                        value: 'Cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'Pending'),
                ),
                const SizedBox(height: 12),
                _formField(_notes, _t('Notes', 'ملاحظات'), Icons.notes,
                    maxLines: 3),
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving
                        ? _t('Saving...', 'جارٍ الحفظ...')
                        : _t('Save Appointment', 'حفظ الموعد')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: _inputTextStyle(context),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(26)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ECGPainter extends CustomPainter {
  final List<double> points;
  ECGPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.danger
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (points.isNotEmpty) {
      final xStep = size.width / points.length;
      final centerY = size.height / 2;
      path.moveTo(0, centerY - (points[0] * 30));
      for (int i = 1; i < points.length; i++) {
        path.lineTo(i * xStep, centerY - (points[i] * 30));
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TrendPainter extends CustomPainter {
  final List<double> values;
  TrendPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (values.isNotEmpty) {
      final step = size.width / (values.length - 1);
      final minV = values.reduce(math.min);
      final maxV = values.reduce(math.max);
      final range = (maxV - minV).abs() < 0.1 ? 1.0 : (maxV - minV);

      double mapY(double v) {
        final norm = (v - minV) / range;
        return size.height - (norm * size.height);
      }

      path.moveTo(0, mapY(values.first));
      for (int i = 1; i < values.length; i++) {
        path.lineTo(i * step, mapY(values[i]));
      }
    }

    final shadow = Paint()
      ..color = AppColors.accent.withAlpha(38)
      ..style = PaintingStyle.fill;

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fill, shadow);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SafetyRow extends StatelessWidget {
  final String label;
  final String value;
  const SafetyRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InsightRow extends StatelessWidget {
  final String label;
  final String value;
  const InsightRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class TipRow extends StatelessWidget {
  final String text;
  const TipRow({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class ApiService {
  final String baseUrl;
  ApiService({required this.baseUrl});

  static String? _token;
  static String? currentRole;
  static String? currentUsername;
  static const Duration _timeout = Duration(seconds: 15);

  static String? get currentToken => _token;

  static void restoreAuth({
    required String token,
    required String role,
    required String username,
  }) {
    _token = token;
    currentRole = role;
    currentUsername = username;
  }

  static void clearAuth() {
    _token = null;
    currentRole = null;
    currentUsername = null;
  }

  Map<String, String> _authHeaders() {
    if (_token == null) return {};
    return {'Authorization': 'Bearer $_token'};
  }

  void _applyAuthToMultipart(http.MultipartRequest req) {
    req.headers.addAll(_authHeaders());
  }

  String get _base {
    final override = AppState.apiBaseUrl.value.trim();
    final raw = override.isNotEmpty ? override : baseUrl;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  Uri _u(String path) => Uri.parse('$_base$path');

  Future<http.Response> _get(Uri uri) async {
    try {
      return await http.get(uri, headers: _authHeaders()).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Request timed out');
    } on SocketException {
      throw Exception('Network error');
    }
  }

  Future<http.Response> _postJson(Uri uri, Map<String, dynamic> body) async {
    try {
      return await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json', ..._authHeaders()},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Request timed out');
    } on SocketException {
      throw Exception('Network error');
    }
  }

  Future<AuthUser> register({
    required String email,
    String? mobile,
    required String password,
    required String role,
    String? name,
    String? specialty,
  }) async {
    final uri = _u('/auth/register');
    final res = await _postJson(uri, {
      'email': email,
      'mobile': mobile,
      'password': password,
      'role': role,
      'name': name,
      'specialty': specialty,
    });
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    final user = AuthUser.fromJson(jsonDecode(res.body));
    restoreAuth(
      token: user.token,
      role: user.role,
      username: user.name ?? email,
    );
    return user;
  }

  Future<AuthUser> login({
    required String email,
    String? mobile,
    required String password,
  }) async {
    final uri = _u('/auth/login');
    final res = await _postJson(uri, {
      'email': email,
      'mobile': mobile,
      'password': password,
    });
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    final user = AuthUser.fromJson(jsonDecode(res.body));
    restoreAuth(
      token: user.token,
      role: user.role,
      username: user.name ?? email,
    );
    return user;
  }

  Future<AuthUser> me() async {
    final uri = _u('/auth/me');
    final res = await _get(uri);
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    final user = AuthUser.fromJson(jsonDecode(res.body));
    restoreAuth(
      token: _token ?? '',
      role: user.role,
      username: user.name ?? currentUsername ?? 'User',
    );
    return user;
  }

  Future<AnalysisResult> analyzeImage(XFile image) async {
    final uri = _u('/analyze_image');
    final req = http.MultipartRequest('POST', uri);
    _applyAuthToMultipart(req);

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      req.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: image.name),
      );
    } else {
      req.files.add(await http.MultipartFile.fromPath('file', image.path));
    }

    final res = await req.send().timeout(_timeout);
    final body = await res.stream.bytesToString();
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} $body');
    }
    return AnalysisResult.fromJson(jsonDecode(body));
  }

  Future<AnalysisResult> analyzeFiles(List<PlatformFile> files) async {
    final uri = _u('/analyze_files');
    final req = http.MultipartRequest('POST', uri);
    _applyAuthToMultipart(req);

    for (final f in files) {
      if (f.bytes != null) {
        req.files.add(
          http.MultipartFile.fromBytes('files', f.bytes!, filename: f.name),
        );
      } else if (f.path != null) {
        req.files.add(
          await http.MultipartFile.fromPath('files', f.path!, filename: f.name),
        );
      }
    }

    final res = await req.send().timeout(_timeout);
    final body = await res.stream.bytesToString();
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} $body');
    }
    return AnalysisResult.fromJson(jsonDecode(body));
  }

  Future<AnalysisResult> analyzePlatformFile(PlatformFile file) async {
    final lower = file.name.toLowerCase();
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.webp')) {
      final uri = _u('/analyze_image');
      final req = http.MultipartRequest('POST', uri);
      _applyAuthToMultipart(req);
      if (file.bytes != null) {
        req.files.add(
          http.MultipartFile.fromBytes('file', file.bytes!,
              filename: file.name),
        );
      } else if (file.path != null) {
        req.files.add(
          await http.MultipartFile.fromPath('file', file.path!,
              filename: file.name),
        );
      } else {
        throw Exception('Selected file could not be read');
      }
      final res = await req.send().timeout(_timeout);
      final body = await res.stream.bytesToString();
      if (res.statusCode != 200) {
        throw Exception('API error: ${res.statusCode} $body');
      }
      return AnalysisResult.fromJson(jsonDecode(body));
    }
    return analyzeFiles([file]);
  }

  Future<WFDBConversionResult> convertImageToWfdb(PlatformFile file) async {
    final uri = _u('/ecg/convert-image-to-wfdb');
    final req = http.MultipartRequest('POST', uri);
    _applyAuthToMultipart(req);
    if (file.bytes != null) {
      req.files.add(
        http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
      );
    } else if (file.path != null) {
      req.files.add(
        await http.MultipartFile.fromPath('file', file.path!,
            filename: file.name),
      );
    } else {
      throw Exception('Selected image could not be read');
    }
    final res = await req.send().timeout(_timeout);
    final body = await res.stream.bytesToString();
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} $body');
    }
    return WFDBConversionResult.fromJson(jsonDecode(body));
  }

  Future<void> sendEmergencyAlert({
    required String patientName,
    required Position pos,
  }) async {
    final uri = _u('/emergency');
    final res = await _postJson(uri, {
      'patientName': patientName,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
    });
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
  }

  Future<List<PatientModel>> listPatients() async {
    final uri = _u('/patients');
    final res = await _get(uri);
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => PatientModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PatientModel> createPatient(PatientModel input) async {
    final uri = _u('/patients');
    final res = await _postJson(uri, input.toJson());
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    return PatientModel.fromJson(jsonDecode(res.body));
  }

  Future<StatsModel> getStats() async {
    final uri = _u('/stats');
    final res = await _get(uri);
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    return StatsModel.fromJson(jsonDecode(res.body));
  }

  Future<List<MessageModel>> listMessagesForPatient(int patientId) async {
    final uri = _u('/messages?patientId=$patientId');
    final res = await _get(uri);
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MessageModel> sendMessage({
    required int patientId,
    required String text,
    required String senderRole,
    required String senderName,
  }) async {
    final uri = _u('/messages');
    final res = await _postJson(uri, {
      'patientId': patientId,
      'text': text,
      'senderRole': senderRole,
      'senderName': senderName,
    });
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    return MessageModel.fromJson(jsonDecode(res.body));
  }

  Future<MessageSummaryModel> getMessageSummary(int patientId) async {
    final uri = _u('/messages/summary?patientId=$patientId');
    final res = await _get(uri);
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    return MessageSummaryModel.fromJson(jsonDecode(res.body));
  }

  Future<MonitoringEventModel> createMonitoringEvent({
    String? sessionId,
    required int patientId,
    required String title,
    required String detail,
    String severity = 'info',
    String source = 'live_ai',
  }) async {
    final uri = _u('/monitoring/events');
    final res = await _postJson(uri, {
      'sessionId': sessionId,
      'patientId': patientId,
      'title': title,
      'detail': detail,
      'severity': severity,
      'source': source,
    });
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    return MonitoringEventModel.fromJson(jsonDecode(res.body));
  }

  Future<List<MonitoringEventModel>> listMonitoringEvents(
    int patientId, {
    int limit = 20,
  }) async {
    final uri = _u('/monitoring/$patientId/events?limit=$limit');
    final res = await _get(uri);
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => MonitoringEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppointmentModel>> listAppointments({int? patientId}) async {
    final query = patientId == null ? '' : '?patientId=$patientId';
    final uri = _u('/appointments$query');
    final res = await _get(uri);
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AppointmentModel> createAppointment(AppointmentModel input) async {
    final uri = _u('/appointments');
    final res = await _postJson(uri, input.toJson());
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    return AppointmentModel.fromJson(jsonDecode(res.body));
  }

  Future<ReportModel> getReport(int patientId) async {
    final uri = _u('/reports/patient/$patientId');
    final res = await _get(uri);
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    return ReportModel.fromJson(jsonDecode(res.body));
  }

  Future<ReportModel> generateReport({
    String? analysisId,
    int? patientId,
  }) async {
    final uri = _u('/reports/generate');
    final res = await _postJson(uri, {
      'analysisId': analysisId,
      'patientId': patientId,
    });
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    return ReportModel.fromJson(jsonDecode(res.body));
  }

  String reportDownloadUrl(String reportId) =>
      '$_base/reports/$reportId/download';

  Future<String> exportReport() async {
    final uri = _u('/reports/export');
    final res = await _get(uri);
    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode} ${res.body}');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/report.pdf');
    await file.writeAsBytes(res.bodyBytes);
    return file.path;
  }
}

class AnalysisResult {
  final String analysisId;
  final String recordingId;
  final String classification;
  final String riskLevel;
  final String region;
  final double confidence;
  final int bpm;
  final double? signalQuality;
  final String? signalQualityLabel;
  final List<String> activeCoils;
  final List<String> recommendations;
  final List<String> findings;
  final Map<String, MeasurementValue> measurements;
  final List<double> waveform;
  final String modelVersion;
  final double threshold;

  AnalysisResult({
    required this.analysisId,
    required this.recordingId,
    required this.classification,
    required this.riskLevel,
    required this.region,
    required this.confidence,
    required this.bpm,
    this.signalQuality,
    this.signalQualityLabel,
    required this.activeCoils,
    required this.recommendations,
    required this.findings,
    required this.measurements,
    required this.waveform,
    required this.modelVersion,
    required this.threshold,
  });

  Color get riskColor {
    if (riskLevel == 'High') return AppColors.danger;
    if (riskLevel == 'Medium') return AppColors.warning;
    return AppColors.success;
  }

  String get rhythmLabel =>
      classification.isEmpty ? 'AI screening output' : classification;

  static AnalysisResult demo(String region) {
    final rnd = math.Random();
    final conf = (0.75 + rnd.nextDouble() * 0.23).clamp(0.0, 1.0);
    final bpm = 70 + rnd.nextInt(30);
    final risk = conf > 0.9 ? 'High' : (conf > 0.82 ? 'Medium' : 'Low');

    final coils = CoilLogic.coilsForRegion(region);
    return AnalysisResult(
      analysisId: 'demo-analysis',
      recordingId: 'demo-record',
      classification: 'Demo screening pattern',
      riskLevel: risk,
      region: region,
      confidence: conf,
      bpm: bpm,
      signalQuality: 0.92,
      signalQualityLabel: 'high',
      activeCoils: coils,
      recommendations: [
        'Stay calm and avoid physical effort.',
        'Hydrate and sit down.',
        'If symptoms appear, seek medical support immediately.',
        'Doctor has been notified (demo).',
      ],
      findings: [
        'Demo screening output.',
        'No backend analysis attached.',
      ],
      measurements: const {},
      waveform: const [],
      modelVersion: 'demo',
      threshold: 0.5,
    );
  }

  factory AnalysisResult.fromJson(Map<String, dynamic> j) {
    final measurementsJson =
        j['measurements'] as Map<String, dynamic>? ?? const {};
    final graphData = j['graphData'] as Map<String, dynamic>? ?? const {};
    return AnalysisResult(
      analysisId: j['analysisId'] as String? ?? '',
      recordingId: j['recordingId'] as String? ?? '',
      classification: j['classification'] as String? ?? '',
      riskLevel: j['riskLevel'] ?? 'Low',
      region: j['region'] ?? 'Undetermined',
      confidence: (j['confidence'] ?? 0.85).toDouble(),
      bpm: (j['bpm'] ?? 80) as int,
      signalQuality: (j['signalQuality'] as num?)?.toDouble(),
      signalQualityLabel: j['signalQualityLabel'] as String?,
      activeCoils: List<String>.from(j['activeCoils'] ?? []),
      recommendations: List<String>.from(j['recommendations'] ?? []),
      findings: List<String>.from(j['findings'] ?? []),
      measurements: measurementsJson.map(
        (key, value) => MapEntry(
          key,
          MeasurementValue.fromJson(value as Map<String, dynamic>),
        ),
      ),
      waveform: (graphData['waveform'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),
      modelVersion: j['modelVersion'] as String? ?? '',
      threshold: (j['threshold'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

class AppMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final Color accent;
  final IconData icon;

  const AppMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class MeasurementValue {
  final String name;
  final double? value;
  final String? unit;
  final String source;

  const MeasurementValue({
    required this.name,
    required this.value,
    required this.unit,
    required this.source,
  });

  factory MeasurementValue.fromJson(Map<String, dynamic> j) {
    return MeasurementValue(
      name: j['name'] as String? ?? '',
      value: (j['value'] as num?)?.toDouble(),
      unit: j['unit'] as String?,
      source: j['source'] as String? ?? 'UNAVAILABLE',
    );
  }
}

class WFDBConversionResult {
  final String conversionId;
  final String recordId;
  final String heaFileName;
  final String datFileName;
  final String zipFileName;
  final String outputDir;
  final String downloadUrl;
  final String createdAt;

  const WFDBConversionResult({
    required this.conversionId,
    required this.recordId,
    required this.heaFileName,
    required this.datFileName,
    required this.zipFileName,
    required this.outputDir,
    required this.downloadUrl,
    required this.createdAt,
  });

  factory WFDBConversionResult.fromJson(Map<String, dynamic> j) {
    return WFDBConversionResult(
      conversionId: j['conversionId'] as String? ?? '',
      recordId: j['recordId'] as String? ?? '',
      heaFileName: j['heaFileName'] as String? ?? '',
      datFileName: j['datFileName'] as String? ?? '',
      zipFileName: j['zipFileName'] as String? ?? '',
      outputDir: j['outputDir'] as String? ?? '',
      downloadUrl: j['downloadUrl'] as String? ?? '',
      createdAt: j['createdAt'] as String? ?? '',
    );
  }
}

class PatientModel {
  final int? id;
  final String name;
  final int? age;
  final String? gender;
  final String? phone;
  final String? notes;
  final String? createdAt;

  PatientModel({
    this.id,
    required this.name,
    this.age,
    this.gender,
    this.phone,
    this.notes,
    this.createdAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> j) {
    return PatientModel(
      id: j['id'] as int?,
      name: j['name'] as String? ?? '',
      age: j['age'] as int?,
      gender: j['gender'] as String?,
      phone: j['phone'] as String?,
      notes: j['notes'] as String?,
      createdAt: j['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'notes': notes,
    };
  }
}

class AuthUser {
  final String token;
  final int userId;
  final String role;
  final String? name;

  AuthUser({
    required this.token,
    required this.userId,
    required this.role,
    this.name,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) {
    return AuthUser(
      token: j['token'] as String,
      userId: j['userId'] as int,
      role: j['role'] as String,
      name: j['name'] as String?,
    );
  }
}

class StatsModel {
  final int patients;
  final int emergencies;
  final int messages;

  StatsModel({
    required this.patients,
    required this.emergencies,
    required this.messages,
  });

  factory StatsModel.fromJson(Map<String, dynamic> j) {
    return StatsModel(
      patients: j['patients'] as int? ?? 0,
      emergencies: j['emergencies'] as int? ?? 0,
      messages: j['messages'] as int? ?? 0,
    );
  }
}

class MessageModel {
  final int id;
  final String senderRole;
  final String senderName;
  final String text;
  final String createdAt;

  MessageModel({
    required this.id,
    required this.senderRole,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) {
    return MessageModel(
      id: j['id'] as int? ?? 0,
      senderRole: j['senderRole'] as String? ?? '',
      senderName: j['senderName'] as String? ?? '',
      text: j['text'] as String? ?? '',
      createdAt: j['createdAt'] as String? ?? '',
    );
  }
}

class MessageSummaryModel {
  final int patientId;
  final String headline;
  final String status;
  final String urgency;
  final String summary;
  final List<String> suggestedReplies;
  final List<String> keySignals;

  MessageSummaryModel({
    required this.patientId,
    required this.headline,
    required this.status,
    required this.urgency,
    required this.summary,
    required this.suggestedReplies,
    required this.keySignals,
  });

  factory MessageSummaryModel.fromJson(Map<String, dynamic> j) {
    return MessageSummaryModel(
      patientId: j['patientId'] as int? ?? 0,
      headline: j['headline'] as String? ?? '',
      status: j['status'] as String? ?? '',
      urgency: j['urgency'] as String? ?? 'low',
      summary: j['summary'] as String? ?? '',
      suggestedReplies: (j['suggestedReplies'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      keySignals: (j['keySignals'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

class MonitoringEventModel {
  final int id;
  final String? sessionId;
  final int patientId;
  final String title;
  final String detail;
  final String severity;
  final String source;
  final String createdAt;

  MonitoringEventModel({
    required this.id,
    required this.sessionId,
    required this.patientId,
    required this.title,
    required this.detail,
    required this.severity,
    required this.source,
    required this.createdAt,
  });

  factory MonitoringEventModel.fromJson(Map<String, dynamic> j) {
    return MonitoringEventModel(
      id: j['id'] as int? ?? 0,
      sessionId: j['sessionId'] as String?,
      patientId: j['patientId'] as int? ?? 0,
      title: j['title'] as String? ?? '',
      detail: j['detail'] as String? ?? '',
      severity: j['severity'] as String? ?? 'info',
      source: j['source'] as String? ?? 'live_ai',
      createdAt: j['createdAt'] as String? ?? '',
    );
  }
}

class AppointmentModel {
  final int id;
  final int patientId;
  final String doctorName;
  final String when;
  final String status;
  final String? notes;
  final String createdAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorName,
    required this.when,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> j) {
    return AppointmentModel(
      id: j['id'] as int? ?? 0,
      patientId: j['patientId'] as int? ?? 0,
      doctorName: j['doctorName'] as String? ?? '',
      when: j['when'] as String? ?? '',
      status: j['status'] as String? ?? '',
      notes: j['notes'] as String?,
      createdAt: j['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'doctorName': doctorName,
      'when': when,
      'status': status,
      'notes': notes,
    };
  }
}

class ReportModel {
  final String reportId;
  final String? analysisId;
  final int patientId;
  final String? filePath;
  final String? createdAt;
  final List<int> bpm;
  final List<String> labels;
  final List<String> riskLevels;

  ReportModel({
    required this.reportId,
    required this.analysisId,
    required this.patientId,
    required this.filePath,
    required this.createdAt,
    required this.bpm,
    required this.labels,
    required this.riskLevels,
  });

  factory ReportModel.fromJson(Map<String, dynamic> j) {
    return ReportModel(
      reportId: j['reportId'] as String? ?? '',
      analysisId: j['analysisId'] as String?,
      patientId: j['patientId'] as int? ?? 0,
      filePath: j['filePath'] as String?,
      createdAt: j['createdAt'] as String?,
      bpm: (j['bpm'] as List<dynamic>? ?? []).map((e) => e as int).toList(),
      labels: (j['labels'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      riskLevels: (j['riskLevels'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

class CoilLogic {
  static List<String> coilsForRegion(String region) {
    switch (region) {
      case 'Anterior':
        return ['C1', 'C2'];
      case 'Inferior':
        return ['C5', 'C6'];
      case 'Lateral':
        return ['C3', 'C4'];
      case 'Septal':
        return ['C7', 'C8'];
      default:
        return ['C1', 'C2'];
    }
  }
}

class DoctorAlert {
  final String patient;
  final String message;
  final String time;
  final Color color;

  DoctorAlert({
    required this.patient,
    required this.message,
    required this.time,
    required this.color,
  });
}

class HistoryItem {
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  HistoryItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });
}

class AlertItem {
  final String title;
  final String detail;
  final String time;
  final Color color;

  AlertItem({
    required this.title,
    required this.detail,
    required this.time,
    required this.color,
  });
}

class SessionLogItem {
  final String title;
  final String detail;
  final String time;
  final String risk;

  SessionLogItem({
    required this.title,
    required this.detail,
    required this.time,
    required this.risk,
  });
}

class CarePlanItem {
  final String title;
  final String detail;
  final String time;
  final bool done;

  CarePlanItem({
    required this.title,
    required this.detail,
    required this.time,
    required this.done,
  });
}

List<DoctorAlert> _mockAlerts() {
  return [
    DoctorAlert(
      patient: 'Patient B',
      message: 'High risk detected, immediate review needed.',
      time: '2 min',
      color: AppColors.danger,
    ),
    DoctorAlert(
      patient: 'Patient D',
      message: 'Irregular rhythm flagged by AI.',
      time: '15 min',
      color: AppColors.warning,
    ),
  ];
}

List<HistoryItem> _mockHistory() {
  final now = DateTime.now();
  final fmt = DateFormat('MMM d, HH:mm');
  return [
    HistoryItem(
      title: 'Session Completed',
      subtitle: 'Normal sinus rhythm',
      time: fmt.format(now.subtract(const Duration(minutes: 20))),
      color: AppColors.success,
    ),
    HistoryItem(
      title: 'Minor Alert',
      subtitle: 'Transient spike detected',
      time: fmt.format(now.subtract(const Duration(hours: 4))),
      color: AppColors.warning,
    ),
    HistoryItem(
      title: 'Risk Report',
      subtitle: 'Low risk confirmed',
      time: fmt.format(now.subtract(const Duration(days: 1))),
      color: AppColors.success,
    ),
  ];
}

List<AlertItem> _mockPatientAlerts() {
  return [
    AlertItem(
      title: 'AI Risk Spike',
      detail: 'Transient spike detected on lead II.',
      time: 'Today 10:24',
      color: AppColors.warning,
    ),
    AlertItem(
      title: 'Stable Window',
      detail: 'No abnormal patterns in last 4 hours.',
      time: 'Today 08:10',
      color: AppColors.success,
    ),
  ];
}

List<SessionLogItem> _mockSessionLogs() {
  final now = DateTime.now();
  final fmt = DateFormat('MMM d, HH:mm');
  return [
    SessionLogItem(
      title: 'Morning Session',
      detail: 'Normal sinus rhythm',
      time: fmt.format(now.subtract(const Duration(hours: 2))),
      risk: 'Low',
    ),
    SessionLogItem(
      title: 'Afternoon Session',
      detail: 'Mild irregularity detected',
      time: fmt.format(now.subtract(const Duration(hours: 5))),
      risk: 'Medium',
    ),
    SessionLogItem(
      title: 'Evening Session',
      detail: 'Stable baseline',
      time: fmt.format(now.subtract(const Duration(hours: 9))),
      risk: 'Low',
    ),
  ];
}

List<CarePlanItem> _mockCarePlan() {
  return [
    CarePlanItem(
      title: 'Medication Reminder',
      detail: 'Take beta blocker after breakfast',
      time: '09:00',
      done: true,
    ),
    CarePlanItem(
      title: 'Hydration',
      detail: 'Drink 2 cups of water',
      time: '11:30',
      done: false,
    ),
    CarePlanItem(
      title: 'Light Walk',
      detail: '15 minutes',
      time: '16:00',
      done: false,
    ),
  ];
}

List<double> _mockWeeklyBpm() {
  const base = 72.0;
  return List.generate(7, (i) => base + math.Random().nextDouble() * 12 - 6);
}

Widget _field(
  String label,
  IconData icon,
  TextEditingController controller, {
  bool obscure = false,
}) {
  return TextField(
    controller: controller,
    obscureText: obscure,
    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.accent),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
    ),
  );
}

Widget _roleCard({
  required IconData icon,
  required String title,
  required String sub,
  required Color color,
  required VoidCallback onTap,
}) {
  final dark = AppState.isDarkMode.value;
  return GlassPanel(
    onTap: onTap,
    padding: const EdgeInsets.all(20),
    radius: BorderRadius.circular(26),
    child: Row(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withAlpha(230), color.withAlpha(120)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sub,
                style: TextStyle(
                  color: dark ? Colors.white60 : AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: dark ? Colors.white10 : AppColors.accentSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.arrow_forward_rounded,
              size: 18, color: dark ? Colors.white : AppColors.primary),
        ),
      ],
    ),
  );
}

Widget _signalChip(IconData icon, String text) {
  final dark = AppState.isDarkMode.value;
  return GlassPanel(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    radius: BorderRadius.circular(999),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.accentDeep),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: dark ? Colors.white : AppColors.primary,
          ),
        ),
      ],
    ),
  );
}

Widget _dashboardCard({
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  final dark = AppState.isDarkMode.value;
  return GlassPanel(
    onTap: onTap,
    padding: const EdgeInsets.all(20),
    radius: BorderRadius.circular(AppRadii.lg),
    child: Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withAlpha(dark ? 115 : 70),
                color.withAlpha(dark ? 70 : 35),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withAlpha(90)),
          ),
          child: Icon(icon, color: dark ? Colors.white : color, size: 28),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: dark ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: dark ? AppColors.textSecondary : AppColors.primaryDark,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (dark ? Colors.white : AppColors.primary).withAlpha(18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.chevron_right_rounded,
            color: dark ? Colors.white70 : AppColors.primary,
          ),
        ),
      ],
    ),
  );
}

Route<T> _fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

Route<T> _scaleRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(scale: animation, child: child);
    },
  );
}
