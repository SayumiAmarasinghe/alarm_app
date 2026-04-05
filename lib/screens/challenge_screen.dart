import 'package:flutter/material.dart';
import 'dart:math';
import '../services/audio_media_service.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late int _num1;
  late int _num2;
  late int _correctAnswer;

  @override
  void initState() {
    super.initState();
    _generateProblem();
  }

  void _generateProblem() {
    final random = Random();
    // Generates a random multiplication problem (e.g., between 2x2 and 12x12)
    _num1 = random.nextInt(11) + 2;
    _num2 = random.nextInt(11) + 2;
    _correctAnswer = _num1 * _num2;
  }

  void _checkAnswer(String input) {
    // Parse the text box input into an integer
    final int? guessedAnswer = int.tryParse(input);

    // If it perfectly matches, dismiss the screen instantly!
    if (guessedAnswer == _correctAnswer) {
      // Hide the keyboard so it doesn't get stuck on the screen
      FocusScope.of(context).unfocus();
      AudioMediaService().stopAlarmSound();

      // Dismiss the challenge screen and return to the dashboard
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16161E), // Match your app's dark theme
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calculate, size: 80, color: Color(0xFF7B52FF)),
                const SizedBox(height: 24),
                const Text(
                    'Wake Up Challenge',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)
                ),
                const SizedBox(height: 40),

                // THE MATH PROBLEM
                Text(
                    '$_num1 × $_num2 = ?',
                    style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white)
                ),
                const SizedBox(height: 40),

                // THE DIRECT INPUT TEXTBOX
                TextField(
                  autofocus: true, // Pops the keyboard open immediately
                  keyboardType: TextInputType.number, // Shows the number pad instead of letters
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF7B52FF)),
                  decoration: InputDecoration(
                    hintText: 'Tap to type',
                    hintStyle: TextStyle(fontSize: 24, color: Colors.grey[700]),
                    filled: true,
                    fillColor: const Color(0xFF2A2A35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  // This is the magic trigger: it checks the math every single time a key is pressed
                  onChanged: _checkAnswer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}