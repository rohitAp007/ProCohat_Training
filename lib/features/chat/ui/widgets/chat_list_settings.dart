  // ========================================================================
  // SETTINGS MENU ACTIONS  
  // =========================================================================
  
  void _navigateToProfile() {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ProfileBloc(
            repository: ProfileRepository(),
          ),
          child: ProfileViewScreen(
            userId: currentUserId,
          ),
        ),
      ),
    );
  }
  
  void _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    if (shouldLogout == true && mounted) {
      await AuthRepository().signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
