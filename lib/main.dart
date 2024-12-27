import 'package:flutter/material.dart';
import 'pages/Login_Page.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  initializeDateFormatting('tr_TR', null).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _currentThemeMode = ThemeMode.system;

  void _toggleTheme(ThemeMode themeMode) {
    setState(() {
      _currentThemeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      locale: const Locale('tr', 'TR'),
      debugShowCheckedModeBanner: false,
      title: "Projify",
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: MaterialColor(0xFF4285F4, {
          50: Color(0xFFE8F0FE),
          100: Color(0xFFD2E3FC),
          200: Color(0xFFBAD1FA),
          300: Color(0xFFA1BEF8),
          400: Color(0xFF89ABF6),
          500: Color(0xFF4285F4),
          600: Color(0xFF3A78E0),
          700: Color(0xFF326ACB),
          800: Color(0xFF295DB7),
          900: Color(0xFF1E4AA0),
        }),
        primaryColor: Color(0xFF4285F4),
        scaffoldBackgroundColor: Color(0xFFFDFDFD),
        cardColor: Color(0xFFA1BEF8),
        dividerColor: Color(0xFFE0E0E0),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF202124)),
          bodyMedium: TextStyle(color: Color(0xFF3C4043)),
          titleLarge: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold),
        ),
        colorScheme: ColorScheme.light(
          onSecondary: Colors.white60,
          secondaryContainer: Color(0xFF3A78E0),
          primary: Color(0xFF4285F4),
          secondary: Color(0xFF1A73E8),
          surface: Color(0xFFFFFFFF),
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: MaterialColor(0xFF303134, {
          50: Color(0xFF303134),
          100: Color(0xFF28292A),
          200: Color(0xFF242526),
          300: Color(0xFF202122),
          400: Color(0xFF1C1D1E),
          500: Color(0xFF18191A),
          600: Color(0xFF151617),
          700: Color(0xFF121314),
          800: Color(0xFF0F1011),
          900: Color(0xFF0B0C0D),
        }),
        primaryColor: Color(0xFF303134),
        scaffoldBackgroundColor: Color(0xFF121212),
        cardColor: Color(0xFF1E1E1E),
        dividerColor: Color(0xFF3C4043),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFFAFAFA), fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w400),
          titleLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
        ),
        colorScheme: ColorScheme.dark(
          onSecondary: Colors.grey,
          secondaryContainer: Color(0xFF303134),
          primary: Color(0xFF8AB4F8),
          secondary: Color(0xFF5F6368),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      themeMode: _currentThemeMode,
      home: LoginPage(toggleTheme: _toggleTheme),
    );
  }
}