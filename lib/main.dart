import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game.dart';
import 'scoreboard.dart';
import 'infobar.dart';
import 'start_prompt.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: GameWidget<MyPhysicsGame>.controlled(
          gameFactory: MyPhysicsGame.new,
          overlayBuilderMap: {
            'Scoreboard': (context, MyPhysicsGame game) => ScoreboardWidget(game: game),
            'InfoBar': (context, MyPhysicsGame game) => InfoBarWidget(game: game),
            'StartPrompt': (context, MyPhysicsGame game) => StartPromptWidget(game: game),
          },
          initialActiveOverlays: const ['Scoreboard', 'InfoBar', 'StartPrompt'],
        ),
      ),
    );
  }
}