import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class AppConfig {
  /// General App Info
  static const String appName = 'gymNOA';

  /// Localization & Time Settings (Argentina)
  static const Locale defaultLocale = Locale('es', 'AR');
  
  static const List<Locale> supportedLocales = [
    Locale('es', 'AR'), // Spanish (Argentina)
    Locale('en', 'US'), // English (US fallback)
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// Initialize any global configurations like date formatting
  static Future<void> initialize() async {
    // Initialize date formatting for Argentina
    await initializeDateFormatting('es_AR', null);
    Intl.defaultLocale = 'es_AR';
  }
}
