import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: DigitalPetApp()));
}

class DigitalPetApp extends StatefulWidget {
  const DigitalPetApp({super.key});

  @override
  State<DigitalPetApp> createState() => _DigitalPetAppState();
}

class _DigitalPetAppState extends State<DigitalPetApp> {
  // Part 1 core state
  String petName = "Your Pet";
  int happinessLevel = 50;
  int hungerLevel = 50;

  final TextEditingController _nameController = TextEditingController();

  // 30-second hunger countdown (visible)
  static const int hungerIntervalSeconds = 30;
  int secondsUntilHungerTick = hungerIntervalSeconds;
  Timer? secondTimer;

  // Win/Loss
  Timer? winCheckTimer;
  DateTime? winStartAbove80;
  bool winShown = false;
  bool gameOverShown = false;

  // ✅ Part 2 Step A: Energy
  int energyLevel = 60; // 0..100

  @override
  void initState() {
    super.initState();

    secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_blockedIfGameEnded()) return;

      setState(() {
        secondsUntilHungerTick--;
        if (secondsUntilHungerTick <= 0) {
          _increaseHungerOnce();
          secondsUntilHungerTick = hungerIntervalSeconds;
        }
      });
    });

    winCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkWinCondition();
    });
  }

  @override
  void dispose() {
    secondTimer?.cancel();
    winCheckTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  int _clamp100(int v) => v.clamp(0, 100);

  Color _moodColor(int happiness) {
    if (happiness > 70) return Colors.green;
    if (happiness >= 30) return Colors.yellow;
    return Colors.red;
  }

  String _moodLabel(int happiness) {
    if (happiness > 70) return "Happy 😄";
    if (happiness >= 30) return "Neutral 🙂";
    return "Unhappy 😢";
  }

  void _setName() {
    final text = _nameController.text.trim();
    if (text.isEmpty) return;
    if (_blockedIfGameEnded()) return;

    setState(() => petName = text);
    FocusScope.of(context).unfocus();
  }

  void _playWithPet() {
    if (_blockedIfGameEnded()) return;

    setState(() {
      happinessLevel = _clamp100(happinessLevel + 10);
      hungerLevel = _clamp100(hungerLevel + 5);

      // ✅ Energy decreases when playing
      energyLevel = _clamp100(energyLevel - 10);

      _applyHungerToHappiness();
      _checkLossCondition();
    });
  }

  void _feedPet() {
    if (_blockedIfGameEnded()) return;

    setState(() {
      hungerLevel = _clamp100(hungerLevel - 10);

      // ✅ Small energy boost when fed (optional but reasonable)
      energyLevel = _clamp100(energyLevel + 5);

      _applyHungerToHappiness();
      _checkLossCondition();
    });
  }

  void _applyHungerToHappiness() {
    if (hungerLevel > 80) {
      happinessLevel = _clamp100(happinessLevel - 15);
    } else if (hungerLevel < 30) {
      happinessLevel = _clamp100(happinessLevel + 5);
    }
  }

  void _increaseHungerOnce() {
    hungerLevel = _clamp100(hungerLevel + 5);

    if (hungerLevel >= 100) {
      happinessLevel = _clamp100(happinessLevel - 20);
    }

    _applyHungerToHappiness();
    _checkLossCondition();
  }

  void _checkWinCondition() {
    if (!mounted || winShown || gameOverShown) return;

    final now = DateTime.now();
    if (happinessLevel > 80) {
      winStartAbove80 ??= now;
      final elapsed = now.difference(winStartAbove80!);

      if (elapsed >= const Duration(minutes: 3)) {
        winShown = true;
        _showEndDialog(
          title: "You Win! 🎉",
          message: "Your pet stayed happy (>80) for 3 minutes!",
        );
      }
    } else {
      winStartAbove80 = null;
    }
  }

  void _checkLossCondition() {
    if (winShown || gameOverShown) return;

    if (hungerLevel >= 100 && happinessLevel <= 10) {
      gameOverShown = true;
      _showEndDialog(
        title: "Game Over 💀",
        message: "Your pet is starving and very unhappy.",
      );
    }
  }

  bool _blockedIfGameEnded() => winShown || gameOverShown;

  Future<void> _showEndDialog({required String title, required String message}) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _resetGame();
            },
            child: const Text("Restart"),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      petName = "Your Pet";
      happinessLevel = 50;
      hungerLevel = 50;

      // reset energy
      energyLevel = 60;

      secondsUntilHungerTick = hungerIntervalSeconds;
      winStartAbove80 = null;
      winShown = false;
      gameOverShown = false;

      _nameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Digital Pet")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Pet name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _blockedIfGameEnded() ? null : _setName,
                    child: const Text("Set"),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text("Name: $petName", style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text("Mood: ${_moodLabel(happinessLevel)}", style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),

              Text(
                "Next hunger increase in: ${secondsUntilHungerTick}s",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              ColorFiltered(
                colorFilter: ColorFilter.mode(_moodColor(happinessLevel), BlendMode.modulate),
                child: Image.asset("assets/pet_image.png", width: 220, height: 220),
              ),
              const SizedBox(height: 18),

              Text("Happiness Level: $happinessLevel", style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 6),
              Text("Hunger Level: $hungerLevel", style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 14),

              // ✅ Energy bar UI
              Row(
                children: [
                  const Text("Energy", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: energyLevel / 100.0,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text("$energyLevel%"),
                ],
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _blockedIfGameEnded() ? null : _playWithPet,
                child: const Text("Play with Your Pet"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _blockedIfGameEnded() ? null : _feedPet,
                child: const Text("Feed Your Pet"),
              ),

              const SizedBox(height: 12),

              Text(
                (happinessLevel > 80)
                    ? "Win timer running… keep happiness > 80 for 3 minutes!"
                    : "Tip: Keep happiness above 80 to win.",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
