import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const BizIdeasApp());
}

class BizIdeasApp extends StatelessWidget {
  const BizIdeasApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Premium Minimalist Black, Neon Pink, and White Palette
    final primaryGold = const Color(0xFF111111); // Black (replaces gold)
    final neonPink = const Color(0xFFFF187F); // Neon Pink
    final bgWhite = const Color(0xFFFDFDFD); // Premium Off-White
    final cardWhite = const Color(0xFFFFFFFF); // Pure White

    return MaterialApp(
      title: 'B Scout',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('de'),
        Locale('es'),
        Locale('fr'),
        Locale('hi'),
        Locale('it'),
        Locale('ja'),
        Locale('ko'),
        Locale('pt'),
        Locale('zh'),
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.white,
        scaffoldBackgroundColor: bgWhite,
        cardColor: cardWhite,
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.light().textTheme,
        ).apply(
          bodyColor: const Color(0xFF111111),
          displayColor: const Color(0xFF000000),
        ),
        colorScheme: ColorScheme.light(
          primary: neonPink,
          secondary: neonPink,
          surface: cardWhite,
          background: bgWhite,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
