import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/bus_model.dart';
import '../../models/notification_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/custom_button.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<BusModel> _buses = [];
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchBuses();
    _fetchNotifications();
  }

  Future<void> _fetchBuses() async {
    try {
      final buses = await _firestoreService.getAllBuses();
      setState(() {
        _buses = buses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching buses: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final userId = auth.currentUser?.uid;
      if (userId == null) return;
      final notifs = await _firestoreService.getUserNotifications(userId);
      setState(() {
        _notifications = notifs;
      });
    } catch (e) {
      // silent failure; keep UI responsive
    }
  }

  String _getTimeRemaining(DateTime estimatedArrival) {
    final now = DateTime.now();
    final difference = estimatedArrival.difference(now);
    
    if (difference.isNegative) {
      return 'Departed';
    }
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes';
    } else {
      return '${difference.inHours} hours ${difference.inMinutes % 60} minutes';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: AppColors.surfaceColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchBuses();
              _fetchNotifications();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchBuses();
                await _fetchNotifications();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUpcomingBusesSection(),
                      const SizedBox(height: 24),
                      _buildNotificationsSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildUpcomingBusesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Bus Schedule',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // Navigate to detailed schedule view
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buses.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No upcoming buses'),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _buses.length > 3 ? 3 : _buses.length,
                itemBuilder: (context, index) {
                  final bus = _buses[index];
                  final timeRemaining = _getTimeRemaining(bus.estimatedArrival);
                  final isSubscribed = index == 0; // Placeholder logic
                  
                  return Card(
                    color: AppColors.surfaceColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            bus.busNo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      title: Text(bus.route),
                      subtitle: Text('Arriving in $timeRemaining'),
                      trailing: IconButton(
                        icon: Icon(
                          isSubscribed
                              ? Icons.notifications
                              : Icons.notifications_none,
                          color: isSubscribed
                              ? AppColors.primaryColor
                              : Colors.grey,
                        ),
                        onPressed: () {
                          // Toggle notification subscription
                        },
                      ),
                      onTap: () {
                        // Navigate to bus details
                      },
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all notifications
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _notifications.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No notifications'),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  final formattedDate = DateFormat('MMM d, h:mm a').format(notification.timestamp);
                  
                  // Choose icon based on notification type
                  IconData iconData;
                  Color iconColor;
                  
                  switch (notification.type) {
                    case 'bus':
                      iconData = Icons.directions_bus;
                      iconColor = AppColors.primaryColor;
                      break;
                    case 'alert':
                      iconData = Icons.warning_amber;
                      iconColor = AppColors.warningColor;
                      break;
                    case 'system':
                    default:
                      iconData = Icons.info;
                      iconColor = AppColors.infoColor;
                      break;
                  }
                  
                  return Card(
                    color: notification.isRead
                        ? AppColors.surfaceColor
                        : AppColors.surfaceColor.withOpacity(0.8),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(iconData, color: iconColor),
                      ),
                      title: Text(notification.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.body),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () async {
                        // Mark as read and handle notification tap
                        setState(() {
                          _notifications[index] = NotificationModel(
                            id: notification.id,
                            title: notification.title,
                            body: notification.body,
                            type: notification.type,
                            timestamp: notification.timestamp,
                            isRead: true,
                            data: notification.data,
                          );
                        });
                        try {
                          await _firestoreService.markNotificationRead(notification.id);
                        } catch (_) {}
                      },
                    ),
                  );
                },
              ),
      ],
    );
  }
}