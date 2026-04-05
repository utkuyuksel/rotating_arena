import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart'; 
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart'; 
import 'arena_boundary.dart';
import 'dart:math' as math;
import 'goal.dart';
import 'ball.dart';

// --- ARKA PLAN VE TRIBÜN IŞIKLARI ---
class GridBackground extends Component {
  @override
  int get priority => -1; 

  @override
  void render(Canvas canvas) {
    canvas.drawColor(const Color(0xFF030804), BlendMode.src);

    // KASMA YAPAN BLUR EFEKTLERİ KALDIRILDI (Performans Odaklı)
    final gridPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.08) 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;

    const double step = 5.0;
    for (double i = -100; i <= 100; i += step) {
      canvas.drawLine(Offset(i, -100), Offset(i, 100), gridPaint); 
      canvas.drawLine(Offset(-100, i), Offset(100, i), gridPaint); 
    }

    // Tribün Işık Şiddeti (0.4)
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        45.0, 
        [
          Colors.greenAccent.withOpacity(0.40), 
          Colors.greenAccent.withOpacity(0.0),  
        ],
      );
    canvas.drawCircle(Offset.zero, 45.0, glowPaint);
  }
}

class TeamData {
  final String name;
  final Color primaryColor;
  final String logoPath;
  final String uiLogoPath; 
  final String folder; 

  TeamData({
    required this.name, 
    required this.primaryColor, 
    required this.logoPath, 
    required this.uiLogoPath,
    required this.folder
  });
}

class MyPhysicsGame extends Forge2DGame with ChangeNotifier, TapCallbacks {
  MyPhysicsGame() : super(gravity: Vector2.zero(), zoom: 6.0);

  // Turnuva ve Lig Verileri
  final Map<String, Map<String, TeamData>> allLeagues = {};
  List<String> leagueNames = []; 

  String selectedLeague = "SÜPER LİG"; 
  String teamALeague = "SÜPER LİG"; 
  String teamBLeague = "SÜPER LİG"; 
  
  String matchStartTime = "19:00";
  String previousScoreInfo = ""; 
  
  double teamAStrength = 50.0; 
  double get teamBStrength => 100.0 - teamAStrength; 
  
  late TeamData teamA;
  late TeamData teamB;

  int scoreA = 0;
  int scoreB = 0;
  double matchTimer = 0;
  final double totalMatchTime = 20.0;
  
  bool isMatchStarted = false; 
  bool isMatchOver = false;
  bool _hasPlayedEndWhistle = false; 
  
  double _resetTimer = 0.0; 
  double _baseArenaSpeed = 0.0; 

  late ArenaBoundary arena;
  late AudioPool kickPool;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.position = Vector2.zero();

    await FlameAudio.audioCache.loadAll(['start_whistle.mp3', 'end_whistle.mp3', 'goal_cheer.mp3', 'crowd.mp3']);
    kickPool = await FlameAudio.createPool('kick.mp3', minPlayers: 3, maxPlayers: 15);
    
    await world.add(GridBackground());

    arena = ArenaBoundary();
    await world.add(arena);
    await world.add(Goal(arena: arena));

    _baseArenaSpeed = arena.body.angularVelocity;

    await loadAllData();
  }

  Future<void> loadAllData() async {
    try {
      final String response = await rootBundle.loadString('assets/data/teams.json');
      final data = json.decode(response) as Map<String, dynamic>;
      
      allLeagues.clear();
      leagueNames.clear();

      for (String lName in data.keys) {
        leagueNames.add(lName);
        final leagueData = data[lName];
        final String folder = leagueData['folder'];
        
        Map<String, TeamData> teamsInLeague = {};

        for (var t in leagueData['teams']) {
          final team = TeamData(
            name: t['name'],
            primaryColor: Color(int.parse(t['color'])),
            logoPath: '$folder/${t['id']}.png', 
            uiLogoPath: 'assets/logolar/$folder/${t['id']}.png', 
            folder: folder,
          );
          teamsInLeague[t['name']] = team;
        }
        allLeagues[lName] = teamsInLeague;
      }

      teamALeague = leagueNames.first;
      teamBLeague = leagueNames.first;
      teamA = allLeagues[teamALeague]!.values.first;
      teamB = allLeagues[teamBLeague]!.values.length > 1 ? allLeagues[teamBLeague]!.values.elementAt(1) : allLeagues[teamBLeague]!.values.first;

      updateLeague(selectedLeague);
    } catch (e) {
      debugPrint("JSON yükleme hatası: $e");
    }
  }

  void updateLeague(String newMode) {
    selectedLeague = newMode;
    
    if (allLeagues.containsKey(newMode)) {
      teamALeague = newMode;
      teamBLeague = newMode;
      teamA = allLeagues[teamALeague]!.values.first;
      teamB = allLeagues[teamBLeague]!.values.length > 1 ? allLeagues[teamBLeague]!.values.elementAt(1) : allLeagues[teamBLeague]!.values.first;
    }

    scoreA = 0; 
    scoreB = 0;
    resetMatch(isGoal: false);
    notifyListeners();
  }

  void updateTeamALeague(String lName) {
    teamALeague = lName;
    teamA = allLeagues[teamALeague]!.values.first;
    scoreA = 0; scoreB = 0;
    resetMatch(isGoal: false); 
    notifyListeners(); 
  }

  void updateTeamBLeague(String lName) {
    teamBLeague = lName;
    teamB = allLeagues[teamBLeague]!.values.first;
    scoreA = 0; scoreB = 0;
    resetMatch(isGoal: false); 
    notifyListeners(); 
  }

  void updateTeamA(String name) { 
    teamA = allLeagues[teamALeague]![name]!; 
    scoreA = 0; scoreB = 0;
    resetMatch(isGoal: false); 
    notifyListeners(); 
  }
  
  void updateTeamB(String name) { 
    teamB = allLeagues[teamBLeague]![name]!; 
    scoreA = 0; scoreB = 0;
    resetMatch(isGoal: false); 
    notifyListeners(); 
  }
  
  void updateTime(String newTime) { matchStartTime = newTime; notifyListeners(); }
  void updatePreviousScore(String val) { previousScoreInfo = val; notifyListeners(); }
  void updateStrength(double val) { teamAStrength = val; notifyListeners(); }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (!isMatchStarted) {
      isMatchStarted = true;
      _resetTimer = 0.0;
      FocusManager.instance.primaryFocus?.unfocus(); 
      FlameAudio.play('start_whistle.mp3', volume: 0.8);
      FlameAudio.bgm.play('crowd.mp3', volume: 0.3); 
      for (var ball in world.children.whereType<Ball>()) { ball.launch(); }
      notifyListeners();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isMatchStarted) return;

    if (matchTimer < totalMatchTime) {
      matchTimer += dt;
      notifyListeners();
    } else {
      
      // MAÇ BİTİŞ ANI - SÜRTÜNME DEVREYE GİRER
      if (!isMatchOver) {
        isMatchOver = true;
        for (var ball in world.children.whereType<Ball>()) {
          ball.body.linearDamping = 1.6; // 2 saniyede pürüzsüz duruş sağlar
          ball.body.angularDamping = 2.0;
        }
      }
      
      if (isMatchOver && !_hasPlayedEndWhistle) {
        FlameAudio.play('end_whistle.mp3', volume: 1.0); 
        FlameAudio.bgm.stop(); 
        _hasPlayedEndWhistle = true;
      }

      if (isMatchOver) {
        _resetTimer += dt;

        // FREN SİSTEMİ: Topu yağ gibi kaydırarak durdurur
        for (var ball in world.children.whereType<Ball>()) {
          ball.body.linearVelocity.scale(0.97); 
          ball.body.angularVelocity *= 0.97;
        }
        
        // Tam 3 saniye sonra maçı sıfırla
        if (_resetTimer >= 3.0) { 
          isMatchStarted = false; 
          isMatchOver = false;
          _hasPlayedEndWhistle = false;
          matchTimer = 0;         
          _resetTimer = 0.0;      
          
          scoreA = 0;
          scoreB = 0;

          resetMatch(isGoal: false); 
          notifyListeners(); 
        }
      }
    }
  }

  void resetMatch({bool isGoal = false, bool teamAScored = true}) {
    if (isMatchOver && isGoal) return; 
    
    if (isGoal) { 
      if (teamAScored) { scoreA++; } else { scoreB++; }
      FlameAudio.play('goal_cheer.mp3', volume: 0.9);
      notifyListeners(); 
    }

    final existingBalls = world.children.whereType<Ball>().toList();
    for (var b in existingBalls) b.removeFromParent();

    // AGRESİF BAŞLANGIÇ: Toplar birbirine daha yakın başlar (6'ya 6)
    world.add(Ball(
      initialPosition: Vector2(-6, 0), 
      color: teamA.primaryColor, 
      radius: 3.52, 
      isTeamA: true, 
      autoLaunch: isMatchStarted, 
      strengthRatio: teamAStrength / 100.0,
    ));
    world.add(Ball(
      initialPosition: Vector2(6, 0), 
      color: teamB.primaryColor, 
      radius: 3.52, 
      isTeamA: false, 
      autoLaunch: isMatchStarted, 
      strengthRatio: teamBStrength / 100.0,
    ));
  }

  String get formattedTime {
    double progress = (matchTimer / totalMatchTime).clamp(0, 1);
    int simulatedMinutes = (progress * 90).toInt();
    int simulatedSeconds = ((progress * 90 * 60) % 60).toInt();
    return "${simulatedMinutes.toString().padLeft(2, '0')}:${simulatedSeconds.toString().padLeft(2, '0')}";
  }
}