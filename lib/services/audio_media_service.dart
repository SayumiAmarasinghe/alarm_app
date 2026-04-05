import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class AudioMediaService {

  // --- REAL SPOTIFY LOGIC ---
  Future<bool> connectToSpotify(String clientId, String redirectUrl) async {
    try {
      // This will pop open the Spotify app, ask for permission, and bounce back!
      bool result = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl,
      );
      return result;
    } catch (e) {
      debugPrint("Spotify Connection Failed: $e");
      return false;
    }
  }

  // --- ALARM TRIGGER LOGIC ---
  Future<void> triggerAlarmSound(String mediaType, String mediaUri) async {
    try {
      if (mediaType == 'spotify') {

        // If we didn't save a specific song, default to Spotify's "Wake Up Happy" playlist
        String uriToPlay = mediaUri.isNotEmpty
            ? mediaUri
            : "spotify:playlist:37i9dQZF1DXdPec7aLTmlC";

        // 🚨 PLAY THE MUSIC 🚨
        await SpotifySdk.play(spotifyUri: uriToPlay);

      } else {
        // Play the Android System Default Alarm!
        FlutterRingtonePlayer().playAlarm();
      }
    } catch (e) {
      debugPrint("Error playing alarm sound: $e");
      // Fallback to system ringtone if Spotify crashes or isn't connected
      FlutterRingtonePlayer().playAlarm();
    }
  }

  // --- ALARM STOP LOGIC ---
  Future<void> stopAlarmSound() async {
    try {
      // 1. Stop the System Ringtone
      FlutterRingtonePlayer().stop();

      // 2. Pause Spotify
      try {
        await SpotifySdk.pause();
      } catch (e) {
        debugPrint("Spotify was not playing: $e");
      }

    } catch (e) {
      debugPrint("Error stopping sound: $e");
    }
  }
}