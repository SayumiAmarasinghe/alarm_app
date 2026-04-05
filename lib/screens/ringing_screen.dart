import 'package:flutter/material.dart';
import '../services/audio_media_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/alarm_service.dart';

class AlarmRingingScreen extends StatefulWidget {
  // These are the variables passed from main.dart when the alarm fires
  final String? alarmId;
  final bool requiresMathChallenge;
  final String mediaType;
  final String mediaUri;

  const AlarmRingingScreen({
    super.key,
    this.alarmId,
    this.requiresMathChallenge = false,
    this.mediaType = 'local',
    this.mediaUri = '',
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  final AudioMediaService _audioService = AudioMediaService();
  late String _currentTime;
  String _snoozeAmount = 'Off'; // 🚨 NEW: Holds the user's snooze preference

  @override
  void initState() {
    super.initState();
    _loadSnoozeSetting(); // Fetch the setting from the hard drive immediately
    _startAlarm();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This runs slightly after initState, when the "context" is finally ready to be used!
    _updateTime();
  }

  // 🚨 NEW: Fetch the snooze setting from SharedPreferences
  Future<void> _loadSnoozeSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _snoozeAmount = prefs.getString('defaultSnooze') ?? 'Off';
      });
    }
  }

  void _updateTime() {
    // Grabs the current time to display on the screen
    setState(() {
      _currentTime = TimeOfDay.now().format(context);
    });
  }

  Future<void> _startAlarm() async {
    // This physically starts the Spotify song or local audio!
    await _audioService.triggerAlarmSound(widget.mediaType, widget.mediaUri);
  }

  Future<void> _stopAlarm() async {
    if (mounted) {
      if (widget.requiresMathChallenge) {
        Navigator.pushReplacementNamed(context, '/challenge');
      } else {
        // 🚨 1. Navigate AWAY instantly! Do not wait for anything.
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);

        // 🚨 2. Tell the audio to stop in the background (Fire and forget)
        _audioService.stopAlarmSound().catchError((e) => debugPrint("Audio stop error: $e"));
      }
    }
  }

  Future<void> _snoozeAlarm() async {
    if (_snoozeAmount == 'Off') return;

    int minutes = 5;
    if (_snoozeAmount == '10 minutes') minutes = 10;
    if (_snoozeAmount == '15 minutes') minutes = 15;

    final scheduledTime = DateTime.now().add(Duration(minutes: minutes));

    // 🚨 1. Show the snackbar and navigate AWAY instantly!
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Snoozed for $_snoozeAmount')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    }

    // 🚨 2. Do the heavy lifting in the background (Fire and forget)
    final alarmService = AlarmService();

    // Schedule the next alarm without freezing the screen
    alarmService.scheduleAlarm(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      scheduledTime: scheduledTime,
      payload: "${widget.alarmId}|${widget.mediaType}|${widget.mediaUri}|${widget.requiresMathChallenge}",
      isSpotify: widget.mediaType == 'spotify',
    ).catchError((e) => debugPrint("Snooze schedule error: $e"));

    // Stop the audio without freezing the screen
    _audioService.stopAlarmSound().catchError((e) => debugPrint("Audio stop error: $e"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16161E), // Dark background
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.alarm, size: 80, color: Color(0xFF7B52FF)),
              const SizedBox(height: 24),
              const Text('Wake Up!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),

              // GIANT CLOCK
              Text(_currentTime, style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 60),

              // ACTION BUTTONS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Primary Action: Turn Off / Math Challenge
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B52FF),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _stopAlarm,
                      child: Text(
                          widget.requiresMathChallenge ? 'Verify & Wake Up' : 'Turn Off',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                    ),

                    // 🚨 NEW: Secondary Action: Conditionally rendered Snooze Button
                    if (_snoozeAmount != 'Off') ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          side: const BorderSide(color: Colors.grey, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: _snoozeAlarm,
                        child: Text(
                            'Snooze for $_snoozeAmount',
                            style: const TextStyle(fontSize: 20, color: Colors.grey)
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}