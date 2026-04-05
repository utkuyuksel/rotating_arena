import 'package:flutter/material.dart';
import 'game.dart';

class ScoreboardWidget extends StatelessWidget {
  final MyPhysicsGame game;

  const ScoreboardWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, child) { 
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTeamLogo(game.teamA), 
                  const SizedBox(width: 12),
                  Text("${game.scoreA}", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      game.formattedTime,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                    ),
                  ),

                  Text("${game.scoreB}", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  _buildTeamLogo(game.teamB), 
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // YENİ: Flutter Image.asset ile logo çizimi
  Widget _buildTeamLogo(TeamData team) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: team.primaryColor.withOpacity(0.2), 
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          team.uiLogoPath,
          fit: BoxFit.contain,
          // Eğer klasörde resmi bulamazsa çökmez, takım rengini gösterir
          errorBuilder: (context, error, stackTrace) => Container(color: team.primaryColor),
        ),
      ),
    );
  }
}