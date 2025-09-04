import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/custom_button.dart';

class QrAttendanceScreen extends StatefulWidget {
  const QrAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<QrAttendanceScreen> createState() => _QrAttendanceScreenState();
}

class _QrAttendanceScreenState extends State<QrAttendanceScreen>
    with TickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final FirestoreService _firestoreService = FirestoreService();
  
  QRViewController? controller;
  bool _isScanning = false;
  bool _isProcessing = false;
  bool _showSuccess = false;
  String _scannedBusNo = '';
  List<Map<String, dynamic>> _recentAttendance = [];
  
  late AnimationController _successAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadRecentAttendance();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    controller?.dispose();
    _successAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  Future<void> _loadRecentAttendance() async {
    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user != null) {
        // In a real implementation, you would fetch user's recent attendance from Firestore
        // For now, we'll use sample data
        setState(() {
          _recentAttendance = [
            {
              'busNo': '123',
              'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
            },
            {
              'busNo': '456',
              'timestamp': DateTime.now().subtract(const Duration(days: 1)),
            },
          ];
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load recent attendance');
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing && scanData.code != null) {
        _processQRCode(scanData.code!);
      }
    });
  }

  Future<void> _processQRCode(String qrData) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Parse QR code data - assuming format: "BUS_123" or just "123"
      String busNo = qrData.replaceAll('BUS_', '').replaceAll('bus_', '');
      
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null) {
        _showErrorSnackBar('You must be logged in to mark attendance');
        return;
      }

      // Log attendance to Firestore
      await _firestoreService.logAttendance(user.uid, busNo);
      
      setState(() {
        _scannedBusNo = busNo;
        _showSuccess = true;
        _isScanning = false;
      });
      
      // Stop camera and show success animation
      controller?.pauseCamera();
      _successAnimationController.forward();
      
      // Add to recent attendance
      _recentAttendance.insert(0, {
        'busNo': busNo,
        'timestamp': DateTime.now(),
      });
      
      // Auto-hide success screen after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showSuccess = false;
            _isProcessing = false;
          });
          _successAnimationController.reset();
        }
      });
      
    } catch (e) {
      _showErrorSnackBar('Failed to mark attendance: ${e.toString()}');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });
    controller?.resumeCamera();
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
    controller?.pauseCamera();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return DateFormat('MMM d, yyyy h:mm a').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildSuccessScreen() {
    return Container(
      color: AppColors.backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/success.json',
            width: 200,
            height: 200,
            controller: _successAnimationController,
            onLoaded: (composition) {
              _successAnimationController.duration = composition.duration;
            },
            // Fallback if Lottie file doesn't exist
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.successColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 100,
                  color: AppColors.successColor,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Attendance Marked!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.successColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bus #$_scannedBusNo',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('h:mm a - MMM d, yyyy').format(DateTime.now()),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 40),
          CustomButton(
            text: 'Done',
            onPressed: () {
              setState(() {
                _showSuccess = false;
                _isProcessing = false;
              });
              _successAnimationController.reset();
            },
            color: AppColors.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildScannerScreen() {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Stack(
            children: [
              QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: AppColors.primaryColor,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 250,
                ),
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primaryColor),
                        SizedBox(height: 16),
                        Text(
                          'Processing...',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Position the QR code within the frame to scan',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            color: AppColors.surfaceColor,
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () async {
                    await controller?.toggleFlash();
                  },
                  icon: const Icon(Icons.flash_on, color: Colors.white, size: 30),
                ),
                CustomButton(
                  text: 'Stop Scanning',
                  onPressed: _stopScanning,
                  isOutlined: true,
                ),
                IconButton(
                  onPressed: () async {
                    await controller?.flipCamera();
                  },
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    size: 60,
                    color: AppColors.primaryColor,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          const Text(
            'QR Attendance',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan the QR code on your bus to mark attendance',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
          ),
          const SizedBox(height: 40),
          CustomButton(
            text: 'Start Scanning',
            onPressed: _startScanning,
          ),
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: AppColors.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Recent Attendance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_recentAttendance.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No recent attendance records',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  )
                else
                  ...List.generate(
                    _recentAttendance.length > 5 ? 5 : _recentAttendance.length,
                    (index) {
                      final attendance = _recentAttendance[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.directions_bus,
                                color: AppColors.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bus #${attendance['busNo']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _formatTimestamp(attendance['timestamp']),
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.successColor,
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Attendance'),
        backgroundColor: AppColors.surfaceColor,
        actions: [
          if (_isScanning)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _stopScanning,
            ),
        ],
      ),
      body: _showSuccess
          ? _buildSuccessScreen()
          : _isScanning
              ? _buildScannerScreen()
              : _buildMainScreen(),
    );
  }
}