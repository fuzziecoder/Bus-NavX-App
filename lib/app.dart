import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/themes.dart';
import 'screens/splash/splash_screen.dart';
import 'services/auth_service.dart';

class BusNavXApp extends StatelessWidget {
  const BusNavXApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BUS NavX',
      theme: AppThemes.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: AppRoutes.routes,
      home: const SplashScreen(),
    );
  }
}