import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// 🚨 NEW: Import the config screen so we can route directly to it
import 'alarm_config_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, '/settings')),
          IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.pushNamed(context, '/profile')),
        ],
      ),
      // --- THE LIVE DATABASE STREAM ---
      body: user == null
          ? const Center(child: Text("Please log in to view alarms."))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('alarms')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF7B52FF)));
          }

          // 2. Error State
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 3. Empty State
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No alarms set.\nTap + to create one!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
            );
          }

          // 4. Data Loaded State
          final alarms = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alarms.length,
            itemBuilder: (context, index) {
              final alarmDoc = alarms[index];
              final data = alarmDoc.data() as Map<String, dynamic>;

              // Parse data from Firebase
              final docId = alarmDoc.id;
              final timeString = data['time'] ?? '00:00';
              final isActive = data['isActive'] ?? false;
              final mediaType = data['mediaType'] == 'spotify' ? 'Spotify' : 'Default Audio';

              // Format the date nicely
              String dateString = "Unknown Date";
              if (data['date'] != null) {
                try {
                  DateTime parsedDate = DateTime.parse(data['date']);
                  dateString = DateFormat('EEEE, MMM d').format(parsedDate).toUpperCase();
                } catch (e) {
                  debugPrint("Date parse error: $e");
                }
              }

              // Swipe to delete wrapper
              return Dismissible(
                key: Key(docId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  // Delete from Firebase
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('alarms')
                      .doc(docId)
                      .delete();
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildAlarmCard(
                    context, // Pass context for navigation
                    user.uid,
                    docId,
                    data,    // 🚨 NEW: Pass the raw data bundle
                    dateString,
                    timeString,
                    mediaType,
                    isActive,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/config'),
        backgroundColor: const Color(0xFF7B52FF),
        label: const Text('+ New Alarm', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- THE DYNAMIC ALARM CARD ---
  Widget _buildAlarmCard(
      BuildContext context,
      String userId,
      String docId,
      Map<String, dynamic> alarmData, // 🚨 NEW
      String date,
      String time,
      String subtitle,
      bool isActive) {

    // Format "14:30" back to "2:30 PM" for display
    String displayTime = time;
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      String period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      displayTime = '$hour:$minute $period';
    } catch (e) {
      // Fallback to raw time
    }

    // 🚨 NEW: Wrap the card in a GestureDetector to handle taps!
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlarmConfigScreen(
              existingAlarmId: docId,
              existingAlarmData: alarmData,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: TextStyle(color: isActive ? const Color(0xFF7B52FF) : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    displayTime,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.grey[700], // Dims if turned off
                    )
                ),
                Switch(
                    value: isActive,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF7B52FF),
                    onChanged: (val) {
                      // This updates Firebase immediately when toggled!
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('alarms')
                          .doc(docId)
                          .update({'isActive': val});
                    }
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: isActive ? Colors.grey : Colors.grey[800])),
          ],
        ),
      ),
    );
  }
}