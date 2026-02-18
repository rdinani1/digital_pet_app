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
  String petName = "Your Pet";
  int happinessLevel = 50;
  int hungerLevel = 50;

  Timer? hungerTimer;

  @override
  void initState() {
    super.initState();

    // Auto hunger every 30 seconds (this is Feature 4 but harmless to keep)
    hungerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateHungerAuto();
    });
  }

  @override
  void dispose() {
    hungerTimer?.cancel();
    super.dispose();
  }

  int _clamp100(int v) => v.clamp(0, 100);

  // ✅ Feature 1: Dynamic color based on happiness
  Color _moodColor(int happinessLevel) {
    if (happinessLevel > 70) {
      return Colors.green;
    } else if (happinessLevel >= 30) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  // ✅ Feature 2: Mood indicator text + emoji
  String _moodLabel(int happinessLevel) {
    if (happinessLevel > 70) {
      return "Happy 😄";
    } else if (happinessLevel >= 30) {
      return "Neutral 🙂";
    } else {
      return "Unhappy 😢";
    }
  }

  void _playWithPet() {
    setState(() {
      happinessLevel = _clamp100(happinessLevel + 10);
      hungerLevel = _clamp100(hungerLevel + 5);
      _applyHungerToHappiness();
    });
  }

  void _feedPet() {
    setState(() {
      hungerLevel = _clamp100(hungerLevel - 10);
      _applyHungerToHappiness();
    });
  }

  void _applyHungerToHappiness() {
    if (hungerLevel > 80) {
      happinessLevel = _clamp100(happinessLevel - 15);
    } else if (hungerLevel < 30) {
      happinessLevel = _clamp100(happinessLevel + 5);
    }
  }

  void _updateHungerAuto() {
    setState(() {
      hungerLevel = _clamp100(hungerLevel + 5);

      if (hungerLevel >= 100) {
        happinessLevel = _clamp100(happinessLevel - 20);
      }

      _applyHungerToHappiness();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              Text('Name: $petName', style: const TextStyle(fontSize: 20.0)),
              const SizedBox(height: 10),

              // ✅ Feature 2: Mood indicator
              Text(
                'Mood: ${_moodLabel(happinessLevel)}',
                style: const TextStyle(fontSize: 18.0),
              ),
              const SizedBox(height: 16),

              // ✅ Feature 1: ColorFiltered pet image
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
              const SizedBox(height: 20),

              Text(
                'Happiness Level: $happinessLevel',
                style: const TextStyle(fontSize: 20.0),
              ),
              const SizedBox(height: 10),
              Text(
                'Hunger Level: $hungerLevel',
                style: const TextStyle(fontSize: 20.0),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _playWithPet,
                child: const Text('Play with Your Pet'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _feedPet,
                child: const Text('Feed Your Pet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
