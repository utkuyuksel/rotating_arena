import 'package:flutter/material.dart';
import 'game.dart';

class InfoBarWidget extends StatelessWidget {
  final MyPhysicsGame game;

  const InfoBarWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, child) {
        // YENİ: Seçili mod bir "Turnuva" mı kontrolü
        final bool isTournament = ["CHAMPIONS LEAGUE", "UEFA EUROPA LEAGUE", "WORLD CUP"].contains(game.selectedLeague);

        return Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  DropdownButton<String>(
                    value: game.selectedLeague,
                    alignment: AlignmentDirectional.center,
                    dropdownColor: Colors.black87,
                    style: const TextStyle(
                      color: Colors.white54, 
                      fontSize: 11, 
                      letterSpacing: 2, 
                      fontWeight: FontWeight.bold,
                    ),
                    underline: const SizedBox(),
                    icon: const SizedBox.shrink(), 
                    items: [
                      "WORLD CUP", 
                      "CHAMPIONS LEAGUE", 
                      "UEFA EUROPA LEAGUE", 
                      ...game.leagueNames // JSON'dan gelen tüm normal ligler
                    ].map((e) => DropdownMenuItem(
                      value: e, 
                      alignment: Alignment.center, 
                      child: Text(e),
                    )).toList(),
                    onChanged: game.isMatchStarted ? null : (val) => game.updateLeague(val!),
                  ),
                  
                  const SizedBox(height: 5),
                  
                  Row(
                    mainAxisSize: MainAxisSize.max, 
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                    children: [
                      // SOL TAKIM (A TAKIMI)
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isTournament) _subLeaguePicker(isTeamA: true), // Turnuvadaysa lig seçiciyi göster
                            _buildInfoBarLogo(game.teamA), 
                            _teamPicker(isTeamA: true),
                          ],
                        ),
                      ),
                      
                      _timePicker(context),
                      
                      // SAĞ TAKIM (B TAKIMI)
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isTournament) _subLeaguePicker(isTeamA: false), // Turnuvadaysa lig seçiciyi göster
                            _buildInfoBarLogo(game.teamB), 
                            _teamPicker(isTeamA: false),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (!game.isMatchStarted)
                    Container(
                      margin: const EdgeInsets.only(top: 15),
                      width: 280,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("%${game.teamAStrength.toInt()}", style: TextStyle(color: game.teamA.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                              const Text("GÜÇ DENGESİ", style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1)),
                              Text("%${game.teamBStrength.toInt()}", style: TextStyle(color: game.teamB.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              activeTrackColor: game.teamA.primaryColor, 
                              inactiveTrackColor: game.teamB.primaryColor, 
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: game.teamAStrength,
                              min: 10,  
                              max: 90,
                              divisions: 16, 
                              onChanged: (val) => game.updateStrength(val),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!game.isMatchStarted)
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 250,
                      height: 30,
                      child: TextField(
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: "Örn: İlk Maç 2-1 (Opsiyonel)",
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.white10,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                        ),
                        onChanged: (val) => game.updatePreviousScore(val),
                      ),
                    )
                  else if (game.previousScoreInfo.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        game.previousScoreInfo.toUpperCase(),
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // YENİ: Turnuva Modunda Takımların Alt Ligini Seçmeye Yarayan Minik Wİdget
  Widget _subLeaguePicker({required bool isTeamA}) {
    return DropdownButton<String>(
      value: isTeamA ? game.teamALeague : game.teamBLeague,
      alignment: AlignmentDirectional.center,
      dropdownColor: Colors.black87,
      style: const TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      underline: const SizedBox(),
      icon: const SizedBox.shrink(), 
      items: game.leagueNames.map((e) => DropdownMenuItem(
        value: e, 
        alignment: Alignment.center,
        child: Text(e),
      )).toList(),
      onChanged: game.isMatchStarted ? null : (val) => isTeamA ? game.updateTeamALeague(val!) : game.updateTeamBLeague(val!),
    );
  }

  Widget _buildInfoBarLogo(TeamData team) {
    return Container(
      width: 45,
      height: 45,
      margin: const EdgeInsets.only(bottom: 4),
      child: Image.asset(
        team.uiLogoPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.shield, color: team.primaryColor.withOpacity(0.5), size: 30),
      ),
    );
  }

  Widget _teamPicker({required bool isTeamA}) {
    // YENİ: Takım listesi artık sadece kendi "Alt Ligine" bağlı
    final currentLeague = isTeamA ? game.teamALeague : game.teamBLeague;
    final teamKeys = game.allLeagues[currentLeague]!.keys;

    return DropdownButton<String>(
      value: isTeamA ? game.teamA.name : game.teamB.name,
      alignment: AlignmentDirectional.center,
      dropdownColor: Colors.black87,
      style: TextStyle(color: isTeamA ? game.teamA.primaryColor : game.teamB.primaryColor, fontWeight: FontWeight.w900, fontSize: 12),
      underline: const SizedBox(),
      icon: const SizedBox.shrink(), 
      items: teamKeys.map((e) => DropdownMenuItem(
        value: e, 
        alignment: Alignment.center,
        child: ConstrainedBox( 
          constraints: const BoxConstraints(maxWidth: 120), 
          child: Text(
            e,
            overflow: TextOverflow.ellipsis, 
            maxLines: 1, 
            textAlign: TextAlign.center,
          ),
        ),
      )).toList(),
      onChanged: game.isMatchStarted ? null : (val) => isTeamA ? game.updateTeamA(val!) : game.updateTeamB(val!),
    );
  }

  Widget _timePicker(BuildContext context) {
    return InkWell(
      onTap: game.isMatchStarted ? null : () {
        TextEditingController controller = TextEditingController(text: game.matchStartTime);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.black87,
            title: const Text("Maç Saati", style: TextStyle(color: Colors.white, fontSize: 14)),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                hintText: "20:45",
                hintStyle: TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  game.updateTime(controller.text);
                  Navigator.pop(context);
                },
                child: const Text("KAYDET", style: TextStyle(color: Colors.green)),
              )
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
        child: Text(game.matchStartTime, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}