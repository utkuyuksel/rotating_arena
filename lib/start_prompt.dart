import 'package:flutter/material.dart';
import 'game.dart';

class StartPromptWidget extends StatelessWidget {
  final MyPhysicsGame game;

  const StartPromptWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, child) {
        if (game.isMatchStarted) return const SizedBox.shrink(); 
        
        return Center(
          child: IgnorePointer( 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                "MAÇI BAŞLATMAK İÇİN DOKUN",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}