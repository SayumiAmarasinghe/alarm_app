import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_media_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- STATE VARIABLES ---
  bool _isSpotifyConnected = false;
  bool _is24HourTime = false;
  String _defaultSnooze = 'Off';

  final AudioMediaService _audioService = AudioMediaService();
  final String clientId = "fa7f6440f5304634b3b0eed08a5e307f";
  final String redirectUrl = "alarmapp://callback";

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Load everything from the hard drive on boot
  }

  // 🚨 LOAD FROM HARD DRIVE
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _is24HourTime = prefs.getBool('is24HourTime') ?? false;
        _defaultSnooze = prefs.getString('defaultSnooze') ?? 'Off';
        _isSpotifyConnected = prefs.getBool('isSpotifyConnected') ?? false;
      });
    }
  }

  // 🚨 SAVE SPOTIFY CONNECTION
  Future<void> _connectToSpotify() async {
    if (_isSpotifyConnected) return;

    bool connected = await _audioService.connectToSpotify(clientId, redirectUrl);

    if (connected) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSpotifyConnected', true); // Save permanently
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

  // 🚨 SAVE SNOOZE PREFERENCE
  Future<void> _pickSnooze() async {
    final options = ['Off', '5 minutes', '10 minutes', '15 minutes'];
    final selected = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          backgroundColor: const Color(0xFF16161E),
          title: const Text('Default Snooze', style: TextStyle(color: Colors.white)),
          children: options.map((opt) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, opt),
            child: Text(opt, style: const TextStyle(color: Colors.white, fontSize: 16)),
          )).toList(),
        )
    );

    if (selected != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('defaultSnooze', selected); // Save permanently
      setState(() => _defaultSnooze = selected);
    }
  }

  // 🚨 SAVE 24-HOUR PREFERENCE
  void _toggle24Hour(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is24HourTime', val); // Save permanently
    setState(() => _is24HourTime = val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // --- INTEGRATIONS ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('INTEGRATIONS', style: TextStyle(color: Color(0xFF7B52FF), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: _connectToSpotify,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Spotify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                    _isSpotifyConnected ? 'Spotify account linked' : 'Tap to connect account',
                                    style: const TextStyle(color: Colors.grey, fontSize: 14)
                                )
                              ]
                          )
                      ),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                              color: _isSpotifyConnected ? const Color(0xFF1E2A22) : const Color(0xFF2A2A35),
                              borderRadius: BorderRadius.circular(20)
                          ),
                          child: Text(
                              _isSpotifyConnected ? 'Connected' : 'Connect',
                              style: TextStyle(color: _isSpotifyConnected ? Colors.greenAccent : Colors.white)
                          )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- PREFERENCES ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PREFERENCES', style: TextStyle(color: Color(0xFF7B52FF), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                GestureDetector(
                  onTap: _pickSnooze,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Default snooze', style: TextStyle(fontSize: 16)),
                            Text(_defaultSnooze, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7B52FF)))
                          ]
                      )
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('24-hour time', style: TextStyle(fontSize: 16)),
                        Switch(
                            value: _is24HourTime,
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF7B52FF),
                            onChanged: _toggle24Hour // Triggers the save method
                        )
                      ]
                  ),
                ),

              ],
            ),
          )
        ],
      ),
    );
  }
}
