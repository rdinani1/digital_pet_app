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
  // -------------------------
  // Part 1: core state
  // -------------------------
  String petName = "Your Pet";
  int happinessLevel = 50; // 0..100
  int hungerLevel = 50; // 0..100

  final TextEditingController _nameController = TextEditingController();

  // Visible countdown for 30-second hunger tick
  static const int hungerIntervalSeconds = 30;
  int secondsUntilHungerTick = hungerIntervalSeconds;
  Timer? secondTimer;

  // Win/Loss
  Timer? winCheckTimer;
  DateTime? winStartAbove80;
  bool winShown = false;
  bool gameOverShown = false;

  // -------------------------
  // Part 2: advanced state
  // -------------------------
  int energyLevel = 60; // 0..100
  final List<String> activities = ["Play", "Run", "Sleep"];
  String selectedActivity = "Play";

  @override
  void initState() {
    super.initState();

    // One timer that ticks every 1 second (drives the 30s hunger tick + visible countdown)
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

    // Win check every second
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

  // Part 1: Dynamic color
  Color _moodColor(int happiness) {
    if (happiness > 70) return Colors.green;
    if (happiness >= 30) return Colors.yellow;
    return Colors.red;
  }

  // Part 1: Mood label + emoji
  String _moodLabel(int happiness) {
    if (happiness > 70) return "Happy 😄";
    if (happiness >= 30) return "Neutral 🙂";
    return "Unhappy 😢";
  }

  // Part 1: Name customization
  void _setName() {
    final text = _nameController.text.trim();
    if (text.isEmpty) return;
    if (_blockedIfGameEnded()) return;

    setState(() => petName = text);
    FocusScope.of(context).unfocus();
  }

  // -------------------------
  // Part 1 actions
  // -------------------------
  void _playWithPet() {
    if (_blockedIfGameEnded()) return;

    setState(() {
      happinessLevel = _clamp100(happinessLevel + 10);
      hungerLevel = _clamp100(hungerLevel + 5);

      // ✅ Part 2: energy decreases when playing
      energyLevel = _clamp100(energyLevel - 8);

      _applyHungerToHappiness();
      _checkLossCondition();
    });
  }

  void _feedPet() {
    if (_blockedIfGameEnded()) return;

    setState(() {
      hungerLevel = _clamp100(hungerLevel - 10);

      // ✅ Part 2: energy slightly increases when fed
      energyLevel = _clamp100(energyLevel + 3);

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

  // Called once per 30 seconds (from the 1-second timer)
  void _increaseHungerOnce() {
    hungerLevel = _clamp100(hungerLevel + 5);

    if (hungerLevel >= 100) {
      happinessLevel = _clamp100(happinessLevel - 20);
    }

    _applyHungerToHappiness();
    _checkLossCondition();
  }

  // -------------------------
  // Part 2: Activity Selection + logic
  // -------------------------
  void _doActivity() {
    if (_blockedIfGameEnded()) return;

    setState(() {
      switch (selectedActivity) {
        case "Run":
          happinessLevel = _clamp100(happinessLevel + 12);
          hungerLevel = _clamp100(hungerLevel + 12);
          energyLevel = _clamp100(energyLevel - 15);
          break;

        case "Sleep":
          energyLevel = _clamp100(energyLevel + 20);
          hungerLevel = _clamp100(hungerLevel + 6);
          happinessLevel = _clamp100(happinessLevel + 2);
          break;

        case "Play":
        default:
          happinessLevel = _clamp100(happinessLevel + 10);
          hungerLevel = _clamp100(hungerLevel + 6);
          energyLevel = _clamp100(energyLevel - 8);
          break;
      }

      _applyHungerToHappiness();
      _checkLossCondition();
    });
  }

  // -------------------------
  // Win/Loss
  // -------------------------
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
      energyLevel = 60;

      secondsUntilHungerTick = hungerIntervalSeconds;
      selectedActivity = "Play";

      winStartAbove80 = null;
      winShown = false;
      gameOverShown = false;

      _nameController.clear();
    });
  }

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Digital Pet")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Name input
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

              // Visible hunger countdown
              Text(
                "Next hunger increase in: ${secondsUntilHungerTick}s",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // Pet image tint
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  _moodColor(happinessLevel),
                  BlendMode.modulate,
                ),
                child: Image.asset("assets/pet_image.png", width: 220, height: 220),
              ),
              const SizedBox(height: 18),

              Text("Happiness Level: $happinessLevel", style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 6),
              Text("Hunger Level: $hungerLevel", style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 14),

              // ✅ Part 2: Energy Bar
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

              const SizedBox(height: 18),

              // Play/Feed buttons
              ElevatedButton(
                onPressed: _blockedIfGameEnded() ? null : _playWithPet,
                child: const Text("Play with Your Pet"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _blockedIfGameEnded() ? null : _feedPet,
                child: const Text("Feed Your Pet"),
              ),

              const SizedBox(height: 18),

              // ✅ Part 2: Activity dropdown + action button
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedActivity,
                      items: activities
                          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: _blockedIfGameEnded()
                          ? null
                          : (val) {
                              if (val == null) return;
                              setState(() => selectedActivity = val);
                            },
                      decoration: const InputDecoration(
                        labelText: "Choose activity",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _blockedIfGameEnded() ? null : _doActivity,
                    child: const Text("Do it"),
                  ),
                ],
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
