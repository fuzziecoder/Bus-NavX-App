import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      // Fallback to SharedPreferences-stored id if needed
      if (userId == null) {
        setState(() {
          _error = 'Not logged in';
          _isLoading = false;
        });
        return;
      }
      final fetched = await _firestoreService.getUserData(userId);
      setState(() {
        _user = fetched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.surfaceColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.errorColor),
                  ),
                )
              : _user == null
                  ? const Center(child: Text('User not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primaryColor,
                            backgroundImage: _user!.profileImageUrl.isNotEmpty
                                ? NetworkImage(_user!.profileImageUrl)
                                : null,
                            child: _user!.profileImageUrl.isEmpty
                                ? const Icon(Icons.person, size: 50, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _user!.name,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _user!.email,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 30),
                          _buildProfileCard(title: 'Bus No', value: _user!.busNo, icon: Icons.directions_bus),
                          _buildProfileCard(title: 'Phone', value: _user!.phoneNo, icon: Icons.phone),
                          _buildProfileCard(
                            title: 'Joined',
                            value: _user!.createdAt.toLocal().toString().split('.').first,
                            icon: Icons.calendar_today,
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Provider.of<AuthService>(context, listen: false).signOut();
                              if (mounted) {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign Out'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildProfileCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      color: AppColors.surfaceColor,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor),
        title: Text(title, style: const TextStyle(color: Colors.grey)),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}