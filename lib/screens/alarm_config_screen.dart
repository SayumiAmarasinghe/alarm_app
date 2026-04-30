import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_media_service.dart';
import '../services/alarm_service.dart';

class AlarmConfigScreen extends StatefulWidget {
  // 🚨 NEW: Optional parameters for editing!
  final String? existingAlarmId;
  final Map<String, dynamic>? existingAlarmData;

  const AlarmConfigScreen({
    super.key,
    this.existingAlarmId,
    this.existingAlarmData
  });

  @override
  State<AlarmConfigScreen> createState() => _AlarmConfigScreenState();
}

class _AlarmConfigScreenState extends State<AlarmConfigScreen> {
  // --- 1. INTERACTIVE STATE VARIABLES ---
  TimeOfDay _selectedTime = const TimeOfDay(hour: 6, minute: 30);
  DateTime _selectedDate = DateTime.now();
  String _repeatOption = 'Weekdays';
  bool _volumeRamping = true;
  bool _vibration = true;
  bool _requiresMathChallenge = true;
  double _rampDuration = 90.0;
  bool _isSaving = false;

  bool _is24HourFormat = false;
  bool _isSpotifyConnected = false;

  final TextEditingController _spotifyUrlController = TextEditingController();
  final AudioMediaService _audioService = AudioMediaService();
  final String clientId = "fa7f6440f5304634b3b0eed08a5e307f";
  final String redirectUrl = "alarmapp://callback";

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _prefillExistingData(); // 🚨 NEW: Check if we are editing!
  }

  @override
  void dispose() {
    _spotifyUrlController.dispose();
    super.dispose();
  }

  // 🚨 NEW: Pre-fill data if an alarm was passed in
  void _prefillExistingData() {
    if (widget.existingAlarmData != null) {
      final data = widget.existingAlarmData!;

      // Parse the saved time string (e.g. "06:30") back into a TimeOfDay
      final timeParts = data['time'].split(':');
      _selectedTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));

      _selectedDate = DateTime.parse(data['date']);
      _repeatOption = data['repeat'] ?? 'Weekdays';
      _volumeRamping = data['volumeRamping'] ?? true;
      _vibration = data['vibration'] ?? true;
      _requiresMathChallenge = data['requiresMathChallenge'] ?? true;
      _rampDuration = (data['rampDurationSeconds'] ?? 90).toDouble();

      // Check if it was a Spotify alarm
      if (data['mediaType'] == 'spotify') {
        _isSpotifyConnected = true;
        if (data['mediaUri'] != null) {
          _spotifyUrlController.text = data['mediaUri'];
        }
      }
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _is24HourFormat = prefs.getBool('is24HourTime') ?? false;

        // Only load the global Spotify pref if we AREN'T currently editing a Spotify alarm
        if (widget.existingAlarmData?['mediaType'] != 'spotify') {
          _isSpotifyConnected = prefs.getBool('isSpotifyConnected') ?? false;
        }
      });
    }
  }

  Future<void> _connectToSpotify() async {
    bool connected = await _audioService.connectToSpotify(clientId, redirectUrl);

    if (connected) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSpotifyConnected', true);
      setState(() => _isSpotifyConnected = true);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(connected ? "Spotify Connected!" : "Failed to connect to Spotify"),
            backgroundColor: connected ? const Color(0xFF1DB954) : Colors.red,
          )
      );
    }
  }

  // --- 3. DIALOGS & UI LOGIC ---
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickRepeat() async {
    final options = ['Never', 'Everyday', 'Weekdays', 'Weekends', 'Every Monday', 'Every Tuesday', 'Every Wednesday', 'Every Thursday', 'Every Friday', 'Every Saturday', 'Every Sunday'];
    final selected = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          backgroundColor: const Color(0xFF16161E),
          title: const Text('Repeat', style: TextStyle(color: Colors.white)),
          children: options.map((opt) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, opt),
            child: Text(opt, style: const TextStyle(color: Colors.white, fontSize: 16)),
          )).toList(),
        )
    );
    if (selected != null) setState(() => _repeatOption = selected);
  }

  void _toggleAmPm(bool setAm) {
    int newHour = _selectedTime.hour;
    if (setAm && newHour >= 12) newHour -= 12;
    if (!setAm && newHour < 12) newHour += 12;
    setState(() {
      _selectedTime = _selectedTime.replacing(hour: newHour);
    });
  }

  // --- NEW: Calculate the exact next target date based on repeat option ---
  DateTime _getNextAlarmDateTime() {
    final now = DateTime.now();
    DateTime target = DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);

    // If 'Never', we respect the exact date the user picked in the UI
    if (_repeatOption == 'Never') {
      return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
    }

    // Check up to 7 days in the future to find the next valid match
    for (int i = 0; i <= 7; i++) {
      DateTime candidate = target.add(Duration(days: i));

      // Skip if the time has already passed for this specific day
      if (candidate.isBefore(now)) continue;

      // Match the weekday based on ISO 8601 (1 = Monday, 7 = Sunday)
      if (_repeatOption == 'Everyday') return candidate;
      if (_repeatOption == 'Weekdays' && candidate.weekday >= 1 && candidate.weekday <= 5) return candidate;
      if (_repeatOption == 'Weekends' && (candidate.weekday == 6 || candidate.weekday == 7)) return candidate;
      if (_repeatOption == 'Every Monday' && candidate.weekday == 1) return candidate;
      if (_repeatOption == 'Every Tuesday' && candidate.weekday == 2) return candidate;
      if (_repeatOption == 'Every Wednesday' && candidate.weekday == 3) return candidate;
      if (_repeatOption == 'Every Thursday' && candidate.weekday == 4) return candidate;
      if (_repeatOption == 'Every Friday' && candidate.weekday == 5) return candidate;
      if (_repeatOption == 'Every Saturday' && candidate.weekday == 6) return candidate;
      if (_repeatOption == 'Every Sunday' && candidate.weekday == 7) return candidate;
    }

    return target; // Fallback
  }

  // --- 4. FIREBASE SAVE LOGIC ---
  Future<void> _saveAlarmToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final String formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      String parsedUri = '';
      if (_isSpotifyConnected && _spotifyUrlController.text.isNotEmpty) {
        String input = _spotifyUrlController.text;
        if (input.startsWith('spotify:track:')) {
          parsedUri = input;
        } else if (input.contains('track/')) {
          parsedUri = 'spotify:track:${input.split('track/')[1].split('?')[0]}';
        }
      }

      final alarmData = {
        'time': formattedTime,
        'date': _selectedDate.toIso8601String(),
        'repeat': _repeatOption,
        'volumeRamping': _volumeRamping,
        'vibration': _vibration,
        'rampDurationSeconds': _rampDuration.toInt(),
        'mediaType': _isSpotifyConnected ? 'spotify' : 'local',
        'mediaUri': parsedUri,
        'requiresMathChallenge': _requiresMathChallenge,
        'isActive': true,
        'createdAt': widget.existingAlarmId == null ? FieldValue.serverTimestamp() : widget.existingAlarmData!['createdAt'], // Preserve original creation date if editing
      };

      // 🚨 NEW: UPDATE IF EDITING, ADD IF NEW
      DocumentReference docRef;
      if (widget.existingAlarmId != null) {
        docRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('alarms').doc(widget.existingAlarmId);
        await docRef.update(alarmData);
      } else {
        docRef = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('alarms').add(alarmData);
      }

      // 🚨 UPDATED: Calculate the exact next occurrence for the OS scheduler
      DateTime scheduledDateTime = _getNextAlarmDateTime();

      // Because we use docRef.id.hashCode, if we are editing an existing alarm,
      // this generates the exact same integer ID as before, causing the Android OS
      // to seamlessly overwrite the old scheduled alarm with the new time!
      final int alarmId = docRef.id.hashCode;
      final String payloadData = "${docRef.id}|${_isSpotifyConnected ? 'spotify' : 'local'}|$parsedUri|$_requiresMathChallenge";

      final alarmService = AlarmService();
      await alarmService.scheduleAlarm(
        id: alarmId,
        scheduledTime: scheduledDateTime,
        payload: payloadData,
        isSpotify: _isSpotifyConnected,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String get _formattedTimeString {
    if (_is24HourFormat) {
      return '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    }

    int hour = _selectedTime.hourOfPeriod;
    if (hour == 0) hour = 12;
    return '${hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
  }

  String get _formattedDateString {
    return '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingAlarmId != null ? 'Edit Alarm' : 'New Alarm'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
              onPressed: _isSaving ? null : _saveAlarmToFirebase,
              child: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF7B52FF), strokeWidth: 2))
                  : const Text('Save', style: TextStyle(color: Color(0xFF7B52FF), fontSize: 16, fontWeight: FontWeight.bold))
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TIME DISPLAY
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formattedTimeString, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),

                  if (!_is24HourFormat) ...[
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFF2A2A35), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _toggleAmPm(true),
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                decoration: BoxDecoration(color: _selectedTime.period == DayPeriod.am ? const Color(0xFF7B52FF) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                                child: Text('AM', style: TextStyle(color: _selectedTime.period == DayPeriod.am ? Colors.white : Colors.grey))
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _toggleAmPm(false),
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                decoration: BoxDecoration(color: _selectedTime.period == DayPeriod.pm ? const Color(0xFF7B52FF) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                                child: Text('PM', style: TextStyle(color: _selectedTime.period == DayPeriod.pm ? Colors.white : Colors.grey))
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // GENERAL SETTINGS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  child: _buildRowItem('Date', _formattedDateString),
                ),
                GestureDetector(
                  onTap: _pickRepeat,
                  child: _buildRowItem('Repeat', _repeatOption),
                ),
                _buildToggleItem('Volume ramping', _volumeRamping, (val) => setState(() => _volumeRamping = val)),
                _buildToggleItem('Vibration', _vibration, (val) => setState(() => _vibration = val)),
                _buildToggleItem('Math challenge', _requiresMathChallenge, (val) => setState(() => _requiresMathChallenge = val)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // SPOTIFY INTEGRATION SECTION
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Alarm Sound', style: TextStyle(fontSize: 16)),
                    Text(_isSpotifyConnected ? 'Spotify' : 'Default', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isSpotifyConnected ? null : _connectToSpotify,
                    icon: Icon(
                        _isSpotifyConnected ? Icons.check_circle : Icons.music_note,
                        color: Colors.white
                    ),
                    label: Text(
                        _isSpotifyConnected ? 'Spotify Linked' : 'Link Spotify Account',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSpotifyConnected ? Colors.grey[800] : const Color(0xFF1DB954),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                if (_isSpotifyConnected) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _spotifyUrlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Paste Spotify Song Link here...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF2A2A35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.link, color: Color(0xFF7B52FF)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // RAMP DURATION
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Ramp duration'),
                    Text('${_rampDuration.toInt()} sec', style: const TextStyle(fontWeight: FontWeight.bold))
                  ]),
                  Slider(
                      value: _rampDuration,
                      min: 15.0,
                      max: 300.0,
                      divisions: 19,
                      activeColor: const Color(0xFF7B52FF),
                      inactiveColor: const Color(0xFF2A2A35),
                      onChanged: (val) => setState(() => _rampDuration = val)
                  )
                ],
              )
          )
        ],
      ),
    );
  }

  Widget _buildRowItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF7B52FF)))
          ]
      ),
    );
  }

  Widget _buildToggleItem(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Switch(
                value: value,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF7B52FF),
                onChanged: onChanged
            )
          ]
      ),
    );
  }
}