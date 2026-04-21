import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pré-carrega a fonte Inter para evitar flash de fonte no web
  await GoogleFonts.pendingFonts([
    GoogleFonts.inter(),
    GoogleFonts.inter(fontWeight: FontWeight.w500),
    GoogleFonts.inter(fontWeight: FontWeight.w600),
    GoogleFonts.inter(fontWeight: FontWeight.w700),
    GoogleFonts.inter(fontWeight: FontWeight.w800),
  ]);

  await Supabase.initialize(
    url:     const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:            Colors.transparent,
    statusBarIconBrightness:   Brightness.dark,
    statusBarBrightness:       Brightness.light,
  ));

  runApp(const ProviderScope(child: FluxaApp()));
}

class FluxaApp extends StatelessWidget {
  const FluxaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluxa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGuard(),
    );
  }
}
