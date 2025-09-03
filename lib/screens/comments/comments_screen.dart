import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/constants.dart';
import '../../models/comment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({Key? key}) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _commentController = TextEditingController();
  final List<CommentModel> _comments = [];
  bool _isLoading = true;
  String _selectedBusNo = '';
  List<String> _availableBuses = [];
  List<File> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadBuses() async {
    try {
      final buses = await _firestoreService.getAllBuses();
      if (buses.isNotEmpty) {
        setState(() {
          _availableBuses = buses.map((bus) => bus.busNo).toList();
          _selectedBusNo = buses.first.busNo;
          _isLoading = false;
        });
        _loadComments();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load buses: ${e.toString()}');
    }
  }

  Future<void> _loadComments() async {
    if (_selectedBusNo.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final comments = await _firestoreService.getCommentsByBus(_selectedBusNo);
      setState(() {
        _comments.clear();
        _comments.addAll(comments);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load comments: ${e.toString()}');
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      return;
    }

    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) {
      _showErrorSnackBar('You must be logged in to comment');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // In a real app, you would upload images to Firebase Storage first
      // and get the download URLs to store in Firestore
      List<String> imageUrls = [];
      // For now, we'll just use placeholder URLs if images are selected
      if (_selectedImages.isNotEmpty) {
        imageUrls = List.generate(
            _selectedImages.length, (index) => 'https://placeholder.com/image$index');
      }

      final comment = CommentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // This will be replaced by Firestore
        userId: user.uid,
        userName: user.name,
        userProfileImage: user.profileImageUrl,
        busNo: _selectedBusNo,
        text: _commentController.text.trim(),
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        type: _selectedImages.isNotEmpty ? 'image' : 'text',
      );

      await _firestoreService.addComment(comment);

      // Clear input fields
      _commentController.clear();
      setState(() {
        _selectedImages = [];
        _isSubmitting = false;
      });

      // Reload comments to show the new one
      _loadComments();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showErrorSnackBar('Failed to submit comment: ${e.toString()}');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: AppColors.surfaceColor,
        actions: [
          DropdownButton<String>(
            value: _selectedBusNo.isNotEmpty ? _selectedBusNo : null,
            hint: const Text('Select Bus', style: TextStyle(color: Colors.white)),
            dropdownColor: AppColors.surfaceColor,
            underline: Container(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            style: const TextStyle(color: Colors.white),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedBusNo = newValue;
                });
                _loadComments();
              }
            },
            items: _availableBuses.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text('Bus #$value'),
              );
            }).toList(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(child: Text('No comments yet'))
                    : RefreshIndicator(
                        onRefresh: _loadComments,
                        child: ListView.builder(
                          itemCount: _comments.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return Card(
                              color: AppColors.surfaceColor,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppColors.primaryColor,
                                          backgroundImage: comment.userProfileImage.isNotEmpty
                                              ? NetworkImage(comment.userProfileImage)
                                              : null,
                                          child: comment.userProfileImage.isEmpty
                                              ? const Icon(Icons.person, color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              comment.userName,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              _formatTimestamp(comment.createdAt),
                                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (comment.text.isNotEmpty)
                                      Text(
                                        comment.text,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    if (comment.imageUrls.isNotEmpty) ...[  
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 120,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: comment.imageUrls.length,
                                          itemBuilder: (context, imgIndex) {
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 8),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  comment.imageUrls[imgIndex],
                                                  height: 120,
                                                  width: 120,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      height: 120,
                                                      width: 120,
                                                      color: Colors.grey[800],
                                                      child: const Icon(Icons.broken_image),
                                                    );
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          icon: const Icon(Icons.thumb_up, size: 16),
                                          label: const Text('Like'),
                                          onPressed: () {},
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(Icons.reply, size: 16),
                                          label: const Text('Reply'),
                                          onPressed: () {},
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surfaceColor,
            child: Column(
              children: [
                if (_selectedImages.isNotEmpty)
                  Container(
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_selectedImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: AppColors.primaryColor),
                      onPressed: _pickImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[800],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: AppColors.primaryColor,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _submitComment,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}