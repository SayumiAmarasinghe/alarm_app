import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Loading...';
  String _email = 'Loading...';
  String _initials = '--';
  int _activeAlarmsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // 1. Get Name & Email (Fallback to email prefix if name is missing)
      final email = user.email ?? 'No email linked';
      final displayName = user.displayName ?? email.split('@')[0];

      // 2. Generate Avatar Initials
      String initials = 'U';
      if (displayName.isNotEmpty) {
        final parts = displayName.trim().split(RegExp(r'\s+'));
        if (parts.length > 1) {
          initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
        } else {
          initials = displayName.substring(0, 1).toUpperCase();
        }
      }

      // 3. Count Active Alarms from Firestore
      int activeCount = 0;
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('alarms')
            .where('isActive', isEqualTo: true)
            .get();
        activeCount = snapshot.docs.length;
      } catch (e) {
        debugPrint("Error counting alarms: $e");
      }

      // 4. Update the UI
      if (mounted) {
        setState(() {
          _name = displayName;
          _email = email;
          _initials = initials;
          _activeAlarmsCount = activeCount;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Route back to Auth Screen and destroy the navigation history
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B52FF)))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // --- PROFILE HEADER ---
          Row(
            children: [
              Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF7B52FF), Colors.greenAccent]),
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child: Center(
                      child: Text(
                          _initials,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                      )
                  )
              ),
              const SizedBox(width: 16),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        _name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 4),
                    Text(
                        '$_activeAlarmsCount active alarms',
                        style: const TextStyle(color: Colors.grey)
                    )
                  ]
              )
            ],
          ),
          const SizedBox(height: 32),

          // --- ACCOUNT DETAILS ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ACCOUNT', style: TextStyle(color: Color(0xFF7B52FF), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Email', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      Text(_email, style: const TextStyle(fontSize: 16))
                    ]
                ),

                const SizedBox(height: 12),

                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Plan', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      Text('Basic', style: TextStyle(fontSize: 16)) // Hardcoded until subscriptions are built
                    ]
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // --- LOG OUT BUTTON ---
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                  'Log Out',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}