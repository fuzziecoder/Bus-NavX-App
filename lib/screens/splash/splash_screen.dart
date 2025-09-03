import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import '../../services/auth_service.dart';
import '../../config/constants.dart';
import '../../widgets/rive/rive_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showLogo = false;
  bool _showTagline = false;
  
  // Rive animation controller
  StateMachineController? _riveController;
  SMIBool? _busAnimationTrigger;
  bool _riveAvailable = true;
  
  @override
  void initState() {
    super.initState();
    _animateElements();
    _checkAuthAndNavigate();
  }
  
  @override
  void dispose() {
    _riveController?.dispose();
    super.dispose();
  }

  Widget _buildRiveOrFallback() {
    if (_riveAvailable) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: RiveAnimation.asset(
          'assets/rive/bus_animation.riv',
          fit: BoxFit.cover,
          onInit: _onRiveInit,
          // If asset missing, Rive throws; guard with try-catch via Future microtask
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Icon(
          Icons.directions_bus_rounded,
          size: 100,
          color: Colors.white,
        ),
      ),
    );
  }

  void _animateElements() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _showLogo = true);
    
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _showTagline = true);
    
    // Trigger Rive animation when available
    if (_busAnimationTrigger != null) {
      _busAnimationTrigger!.value = true;
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final isLoggedIn = await authService.isUserLoggedIn();
    
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
  
  void _onRiveInit(Artboard artboard) {
    final controller = RiveUtils.getRiveController(
      artboard,
      stateMachineName: "BUS_ANIMATION",
    );
    
    if (controller != null) {
      _riveController = controller;
      _busAnimationTrigger = controller.findSMI("trigger") as SMIBool?;
      
      // Start animation
      if (_showLogo && _busAnimationTrigger != null) {
        _busAnimationTrigger!.value = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: AnimatedOpacity(
                opacity: _showLogo ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: _buildRiveOrFallback(),
              ),
            ),
            const SizedBox(height: 40),
            AnimatedOpacity(
              opacity: _showTagline ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 800),
              child: const Column(
                children: [
                  Text(
                    'BUS NavX',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Navigate Your Journey',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
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