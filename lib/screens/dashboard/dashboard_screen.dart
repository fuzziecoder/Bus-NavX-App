import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../../config/constants.dart';
import '../../widgets/rive/rive_asset.dart';
import '../../widgets/rive/rive_utils.dart';
import '../home/home_screen.dart';
import '../bus_nav/bus_nav_screen.dart';
import '../comments/comments_screen.dart';
import '../qr_attendance/qr_attendance_screen.dart';
import '../profile/profile_screen.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  
  // Rive animation controllers
  List<SMIBool?> _riveIconInputs = [];
  
  // This would be replaced with actual Rive animations
  final List<RiveAsset> bottomNavs = [
    RiveAsset(
      src: "assets/rive/icons.riv",
      artboard: "HOME",
      stateMachineName: "HOME_interactivity",
      title: "Home",
    ),
    RiveAsset(
      src: "assets/rive/icons.riv",
      artboard: "SEARCH",
      stateMachineName: "SEARCH_interactivity",
      title: "BUS Nav",
    ),
    RiveAsset(
      src: "assets/rive/icons.riv",
      artboard: "CHAT",
      stateMachineName: "CHAT_interactivity",
      title: "Comments",
    ),
    RiveAsset(
      src: "assets/rive/icons.riv",
      artboard: "SCAN",
      stateMachineName: "SCAN_interactivity",
      title: "QR Scan",
    ),
    RiveAsset(
      src: "assets/rive/icons.riv",
      artboard: "USER",
      stateMachineName: "USER_interactivity",
      title: "Profile",
    ),
  ];
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const BusNavScreen(),
    const CommentsScreen(),
    const QrAttendanceScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with empty inputs that will be set when animations load
    _riveIconInputs = List.generate(bottomNavs.length, (_) => null);
  }

  void _updateSelectedTab(int index) {
    // Reset all animations
    for (int i = 0; i < _riveIconInputs.length; i++) {
      if (_riveIconInputs[i] != null) {
        _riveIconInputs[i]!.value = false;
      }
    }
    
    // Activate selected animation
    if (_riveIconInputs[index] != null) {
      _riveIconInputs[index]!.value = true;
    }
    
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              bottomNavs.length,
              (index) => GestureDetector(
                onTap: () => _updateSelectedTab(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 36,
                      width: 36,
                      child: Opacity(
                        opacity: 1.0,
                        child: _buildNavIcon(index),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bottomNavs[index].title,
                      style: TextStyle(
                        color: _currentIndex == index 
                            ? AppColors.primaryColor 
                            : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // SOS functionality
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('SOS Alert'),
              content: const Text('Do you want to send an SOS alert?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      final auth = Provider.of<AuthService>(context, listen: false);
                      final userId = auth.isAuthenticated ? (auth.currentUser?.uid) : null;
                      if (userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please log in to send SOS')),
                        );
                        return;
                      }

                      final locationService = Provider.of<LocationService>(context, listen: false);
                      final position = await locationService.getCurrentLocation();

                      final notificationService = Provider.of<NotificationService>(context, listen: false);
                      await notificationService.sendSOS(userId, position.latitude, position.longitude);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SOS Alert sent!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to send SOS: ${e.toString()}')),
                      );
                    }
                  },
                  child: const Text('Send SOS'),
                ),
              ],
            ),
          );
        },
        backgroundColor: AppColors.errorColor,
        child: const Icon(Icons.sos, color: Colors.white),
      ),
    );
  }

  Widget _buildNavIcon(int index) {
    // Use Rive animations when assets are available
    try {
      return RiveAnimation.asset(
        bottomNavs[index].src,
        artboard: bottomNavs[index].artboard,
        onInit: (artboard) {
          StateMachineController? controller = RiveUtils.getRiveController(
            artboard,
            stateMachineName: bottomNavs[index].stateMachineName,
          );
          if (controller != null) {
            _riveIconInputs[index] = controller.findSMI("active") as SMIBool?;
            // Set initial state
            if (index == _currentIndex && _riveIconInputs[index] != null) {
              _riveIconInputs[index]!.value = true;
            }
          }
        },
      );
    } catch (e) {
      // Fallback to icons if Rive assets are not available
      return Icon(
        index == 0 ? Icons.home :
        index == 1 ? Icons.map :
        index == 2 ? Icons.comment :
        index == 3 ? Icons.qr_code :
        Icons.person,
        color: _currentIndex == index 
            ? AppColors.primaryColor 
            : Colors.grey,
        size: 24,
      );
    }
  }
}