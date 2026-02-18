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
  // Core state
  // -------------------------
  String petName = "Your Pet";
  int happinessLevel = 50; // 0..100
  int hungerLevel = 50; // 0..100

  // -------------------------
  // Part 1: timers + win/loss
  // -------------------------
  Timer? hungerTimer;
  Timer? winCheckTimer;

  DateTime? winStartAbove80; // happiness > 80 start time
  bool gameOverShown = false;
  bool winShown = false;

  // -------------------------
  // Name customization
  // -------------------------
  final TextEditingController _nameController = TextEditingController();

  // -------------------------
  // Lifecycle
  // -------------------------
  @override
  void initState() {
    super.initState();

    // Auto hunger every 30 seconds
    hungerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _autoIncreaseHunger();
    });

    // Check win condition every second
    winCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkWinCondition();
    });
  }

  @override
  void dispose() {
    hungerTimer?.cancel();
    winCheckTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  // -------------------------
  // Helpers
  // -------------------------
  int _clamp100(int v) => v.clamp(0, 100);

  // Part 1: Dynamic color change using happiness
  Color _moodColor(int happiness) {
    if (happiness > 70) return Colors.green;
    if (happiness >= 30) return Colors.yellow;
    return Colors.red;
  }

  // Part 1: Mood indicator text + emoji
  String _moodLabel(int happiness) {
    if (happiness > 70) return "Happy 😄";
    if (happiness >= 30) return "Neutral 🙂";
    return "Unhappy 😢";
  }

  // -------------------------
  // Actions
  // -------------------------
  void _playWithPet() {
    if (_blockedIfGameEnded()) return;

    setState(() {
      happinessLevel = _clamp100(happinessLevel + 10);
      hungerLevel = _clamp100(hungerLevel + 5);

      _applyHungerToHappiness();
      _checkLossCondition();
    });
  }

  void _feedPet() {
    if (_blockedIfGameEnded()) return;

    setState(() {
      hungerLevel = _clamp100(hungerLevel - 10);

      _applyHungerToHappiness();
      _checkLossCondition();
    });
  }

  void _applyHungerToHappiness() {
    // Simple rule: if very hungry, lose happiness; if not too hungry, gain a little
    if (hungerLevel > 80) {
      happinessLevel = _clamp100(happinessLevel - 15);
    } else if (hungerLevel < 30) {
      happinessLevel = _clamp100(happinessLevel + 5);
    }
  }

  void _autoIncreaseHunger() {
    if (_blockedIfGameEnded()) return;

    setState(() {
      hungerLevel = _clamp100(hungerLevel + 5);

      // If hunger hits 100, reduce happiness a chunk
      if (hungerLevel >= 100) {
        happinessLevel = _clamp100(happinessLevel - 20);
      }

      _checkLossCondition();
    });
  }

  // -------------------------
  // Name customization
  // -------------------------
  void _setName() {
    if (_blockedIfGameEnded()) return;

    final text = _nameController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      petName = text;
    });
    FocusScope.of(context).unfocus();
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
      winStartAbove80 = null; // reset if happiness drops
    }
  }

  void _checkLossCondition() {
    if (gameOverShown || winShown) return;

    // Loss: Hunger reaches 100 AND Happiness drops to 10
    if (hungerLevel >= 100 && happinessLevel <= 10) {
      gameOverShown = true;
      _showEndDialog(
        title: "Game Over 💀",
        message: "Your pet is starving and very unhappy.",
      );
    }
  }

  bool _blockedIfGameEnded() => gameOverShown || winShown;

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

      winStartAbove80 = null;
      gameOverShown = false;
      winShown = false;

      _nameController.clear();
    });
  }

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final mood = _moodLabel(happinessLevel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Pet'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Name customization
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

              const SizedBox(height: 18),

              Text('Name: $petName', style: const TextStyle(fontSize: 20.0)),
              const SizedBox(height: 8),

              // Mood indicator
              Text('Mood: $mood', style: const TextStyle(fontSize: 18.0)),
              const SizedBox(height: 14),

              // Pet image with dynamic color tint
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  _moodColor(happinessLevel),
                  BlendMode.modulate,
                ),
                child: Image.asset(
                  'assets/pet_image.png',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 18),

              Text('Happiness Level: $happinessLevel',
                  style: const TextStyle(fontSize: 20.0)),
              const SizedBox(height: 8),
              Text('Hunger Level: $hungerLevel',
                  style: const TextStyle(fontSize: 20.0)),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _blockedIfGameEnded() ? null : _playWithPet,
                child: const Text('Play with Your Pet'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _blockedIfGameEnded() ? null : _feedPet,
                child: const Text('Feed Your Pet'),
              ),

              const SizedBox(height: 16),

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
