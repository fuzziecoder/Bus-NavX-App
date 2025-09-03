import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../models/bus_model.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';

class BusNavScreen extends StatefulWidget {
  const BusNavScreen({Key? key}) : super(key: key);

  @override
  State<BusNavScreen> createState() => _BusNavScreenState();
}

class _BusNavScreenState extends State<BusNavScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final Completer<GoogleMapController> _controller = Completer();
  
  List<BusModel> _buses = [];
  BusModel? _selectedBus;
  bool _isLoading = true;
  bool _isFollowing = false;
  
  // Map markers
  final Set<Marker> _markers = {};
  
  // Default camera position (campus center)
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194), // Default coordinates - replace with your campus coordinates
    zoom: 14.0,
  );

  // Timer for periodic updates
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchBuses();
    // Set up periodic updates every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateBusLocations();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBuses() async {
    try {
      final buses = await _firestoreService.getAllBuses();
      
      // Get user's assigned bus
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      if (userId != null) {
        final user = await _firestoreService.getUserData(userId);
        final userBusNo = user?.busNo;
        
        if (userBusNo != null && userBusNo.isNotEmpty) {
          _selectedBus = buses.firstWhere(
            (bus) => bus.busNo == userBusNo,
            orElse: () => buses.first,
          );
        } else if (buses.isNotEmpty) {
          _selectedBus = buses.first;
        }
      } else if (buses.isNotEmpty) {
        _selectedBus = buses.first;
      }
      
      setState(() {
        _buses = buses;
        _isLoading = false;
      });
      
      _updateMarkers();
      _moveToSelectedBus();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching buses: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateBusLocations() async {
    try {
      final buses = await _firestoreService.getAllBuses();
      
      setState(() {
        _buses = buses;
        
        // Update selected bus with new data
        if (_selectedBus != null) {
          final updatedSelectedBus = buses.firstWhere(
            (bus) => bus.id == _selectedBus!.id,
            orElse: () => _selectedBus!,
          );
          _selectedBus = updatedSelectedBus;
        }
      });
      
      _updateMarkers();
      
      // If following mode is on, move camera to selected bus
      if (_isFollowing && _selectedBus != null) {
        _moveToSelectedBus();
      }
    } catch (e) {
      // Silent update, don't show error for background updates
      print('Error updating bus locations: ${e.toString()}');
    }
  }

  void _updateMarkers() {
    final Set<Marker> markers = {};
    
    for (final bus in _buses) {
      final bool isSelected = _selectedBus?.id == bus.id;
      
      // Create custom marker icon based on selection state
      final BitmapDescriptor markerIcon = isSelected
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet)
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      
      markers.add(
        Marker(
          markerId: MarkerId(bus.id),
          position: LatLng(bus.latitude, bus.longitude),
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: 'Bus #${bus.busNo}',
            snippet: '${bus.route} - ${bus.status}',
          ),
          onTap: () {
            setState(() {
              _selectedBus = bus;
            });
          },
        ),
      );
    }
    
    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }

  Future<void> _moveToSelectedBus() async {
    if (_selectedBus == null || !_controller.isCompleted) return;
    
    final GoogleMapController controller = await _controller.future;
    final CameraPosition position = CameraPosition(
      target: LatLng(_selectedBus!.latitude, _selectedBus!.longitude),
      zoom: 16.0,
    );
    
    controller.animateCamera(CameraUpdate.newCameraPosition(position));
  }

  String _getTimeRemaining(DateTime estimatedArrival) {
    final now = DateTime.now();
    final difference = estimatedArrival.difference(now);
    
    if (difference.isNegative) {
      return 'Arrived';
    }
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BUS Nav'),
        backgroundColor: AppColors.surfaceColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchBuses();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _defaultPosition,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                    _moveToSelectedBus();
                  },
                ),
                
                // Bus selection panel at the bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Selected bus info
                        if (_selectedBus != null) ...[                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Current Bus', style: TextStyle(color: Colors.grey)),
                                  Text(
                                    'Bus #${_selectedBus!.busNo}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_selectedBus!.route, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('ETA', style: TextStyle(color: Colors.grey)),
                                  Text(
                                    _getTimeRemaining(_selectedBus!.estimatedArrival),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accentColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${_selectedBus!.status}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _selectedBus!.status == 'active'
                                          ? AppColors.successColor
                                          : AppColors.warningColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Driver info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Driver: ${_selectedBus!.driverName}'),
                              GestureDetector(
                                onTap: () {
                                  // Implement call driver functionality
                                },
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone, size: 16, color: AppColors.primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedBus!.driverPhone,
                                      style: const TextStyle(color: AppColors.primaryColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Bus selection dropdown and action buttons
                        Row(
                          children: [
                            // Bus selection dropdown
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedBus?.id,
                                    hint: const Text('Select Bus'),
                                    dropdownColor: AppColors.backgroundColor,
                                    isExpanded: true,
                                    items: _buses.map((bus) {
                                      return DropdownMenuItem<String>(
                                        value: bus.id,
                                        child: Text('Bus #${bus.busNo} - ${bus.route}'),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedBus = _buses.firstWhere((bus) => bus.id == value);
                                        });
                                        _moveToSelectedBus();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Follow button
                            IconButton(
                              icon: Icon(
                                _isFollowing ? Icons.gps_fixed : Icons.gps_not_fixed,
                                color: _isFollowing ? AppColors.primaryColor : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isFollowing = !_isFollowing;
                                });
                                if (_isFollowing) {
                                  _moveToSelectedBus();
                                }
                              },
                              tooltip: _isFollowing ? 'Stop following' : 'Follow bus',
                            ),
                            // Center on bus button
                            IconButton(
                              icon: const Icon(Icons.center_focus_strong),
                              onPressed: _moveToSelectedBus,
                              tooltip: 'Center on bus',
                            ),
                          ],
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