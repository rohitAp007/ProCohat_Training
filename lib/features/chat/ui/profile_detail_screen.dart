/// ============================================================================
/// PROFILE DETAIL SCREEN - View user profile information
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_bloc.dart';
import 'package:supabase_flutter_app/features/profile/bloc/profile_state.dart';
import 'package:supabase_flutter_app/features/profile/data/profile_model.dart';

class ProfileDetailScreen extends StatelessWidget {
  final String userId;
  final String? userName;

  const ProfileDetailScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (state is ProfileError) {
            return Center(child: Text('Error loading profile'));
          }
          
          if (state is! ProfileLoaded) {
            return Center(child: Text('No profile data'));
          }
          
          final profile = state.profile;
          
          return SingleChildScrollView(
            child: Column(
              children: [
                // Header section with avatar
               SizedBox(height: 40),
                
                // Profile Avatar
                CircleAvatar(
                  radius: 80,
                  backgroundColor: const Color(0xFF128C7E),
                  backgroundImage: profile.avatarUrl != null
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          _getInitials(profile.fullName),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                
                SizedBox(height: 24),
                
                // Name
                Text(
                  profile.fullName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 8),
                
                // Bio
                if (profile.bio != null && profile.bio!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      profile.bio!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                
                SizedBox(height: 32),
                Divider(),
                
                // Profile Info List
                _buildInfoTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  value: profile.bio ?? 'Hey there! I am using ProCohat',
                ),
                
                Divider(),
                SizedBox(height: 16),
                
                // Action Buttons
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildActionButton(
                        icon: Icons.block,
                        label: 'Block User',
                        color: Colors.red,
                        onTap: () {
                          _showBlockDialog(context);
                        },
                      ),
                      SizedBox(height: 12),
                      _buildActionButton(
                        icon: Icons.report,
                        label: 'Report User',
                        color: Colors.orange,
                        onTap: () {
                          _showReportDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF075E54)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block User'),
        content: Text('Are you sure you want to block this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement block functionality
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('User blocked')),
              );
            },
            child: Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Report User'),
        content: Text('Are you sure you want to report this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement report functionality
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('User reported')),
              );
            },
            child: Text('Report', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}
