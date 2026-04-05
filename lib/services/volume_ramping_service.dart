import 'dart:async';
import 'package:volume_controller/volume_controller.dart';

class VolumeRampingService {
  Timer? _rampTimer;

  void startVolumeRamp({Duration duration = const Duration(minutes: 1)}) {
    double currentVolume = 0.0;
    VolumeController().setVolume(currentVolume);

    int steps = 30;
    int intervalMs = duration.inMilliseconds ~/ steps;
    double volumeStep = 1.0 / steps;

    _rampTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (currentVolume < 1.0) {
        currentVolume += volumeStep;
        if (currentVolume > 1.0) currentVolume = 1.0;
        VolumeController().setVolume(currentVolume);
      } else {
        timer.cancel();
      }
    });
  }

  void stopRamp() {
    _rampTimer?.cancel();
  }
}