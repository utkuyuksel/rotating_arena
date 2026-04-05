import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'arena_boundary.dart';
import 'ball.dart';

class Goal extends Component with HasGameRef {
  final ArenaBoundary arena;
  final double depth = 6.0; // Kalenin derinliği biraz artırıldı

  double _netStretch = 0.0;
  double _netVelocity = 0.0;

  Goal({required this.arena});

  @override
  void update(double dt) {
    super.update(dt);
    double targetStretch = 0.0;

    // Oyundaki topları kontrol et
    final balls = gameRef.world.children.whereType<Ball>();
    for (final ball in balls) {
      final ballPos = ball.body.position;
      final arenaAngle = arena.body.angle;

      // Topu kalenin lokal koordinatlarına çevir
      final localX = ballPos.x * math.cos(arenaAngle) + ballPos.y * math.sin(arenaAngle);
      final localY = -ballPos.x * math.sin(arenaAngle) + ballPos.y * math.cos(arenaAngle);

      final localDistance = math.sqrt(localX * localX + localY * localY);
      final localAngle = math.atan2(localY, localX);

      // Top sadece gol boşluğundan GİRDİYSE (açı ve sınır kontrolü)
      if (localAngle.abs() < (arena.gapAngle / 2) * 0.9 && localDistance > arena.radius - ball.radius) {
        // Topun fileyi itme miktarı (Kalenin %85'inden fazla dışarı taşmasını engelliyoruz)
        double push = (localDistance + ball.radius) - arena.radius;
        if (push > targetStretch) {
          targetStretch = push.clamp(0.0, depth * 0.85); 
        }
      }
    }

    // GERÇEKÇİ YAY (SPRING) FİZİĞİ - Titreme ve sonsuz esneme düzeltildi
    const double k = 200.0; // Filenin sertliği (daha gergin)
    const double d = 15.0;  // Sönümleme (titremeyi anında keser)
    
    double force = -k * (_netStretch - targetStretch) - d * _netVelocity;
    _netVelocity += force * dt;
    _netStretch += _netVelocity * dt;

    // Mikro titreşimleri sıfırla (durduğu yerde sallanmayı ve titremeyi kesin olarak önler)
    if (targetStretch == 0 && _netStretch.abs() < 0.05 && _netVelocity.abs() < 0.05) {
      _netStretch = 0.0;
      _netVelocity = 0.0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    canvas.save();
    canvas.rotate(arena.body.angle);

    final x1 = arena.radius * math.cos(arena.gapAngle / 2);
    final y1 = arena.radius * math.sin(arena.gapAngle / 2);
    final x2 = arena.radius * math.cos(-arena.gapAngle / 2);
    final y2 = arena.radius * math.sin(-arena.gapAngle / 2);

    final path = Path()
      ..moveTo(x1, y1)
      ..lineTo(x1 + depth, y1) 
      ..lineTo(x1 + depth, y2) 
      ..lineTo(x2, y2);        

    // Kalenin zemin rengi
    final pitchPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, pitchPaint); 

    // Direkler ve Üst Çerçeve
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0; 
    canvas.drawPath(path, paint);

    // DAHA SIK VE GERÇEKÇİ FİLE ÇİZİMİ (GRID)
    final netPaint = Paint()
      ..color = Colors.white.withOpacity(0.55) // Görünürlüğü hafif artırıldı
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.25; // İpler inceltildi ki sıkı dursun

    int rows = 14; // Yatay ip sayısı artırıldı (daha sık)
    int cols = 12; // Dikey ip sayısı artırıldı (daha sık)
    
    // Yatay İpler
    for (int i = 0; i <= rows; i++) {
      double y = y2 + (y1 - y2) * (i / rows);
      // Gerçekçilik: Direk diplerindeki (kenarlardaki) ipler esnemez, sadece ortadaki ipler esner
      double stretchFactor = 1.0 - math.pow((y.abs() / y1.abs()), 2.0); 
      double currentDepth = depth + (_netStretch * stretchFactor); 
      
      final netPath = Path()
        ..moveTo(x1, y)
        ..quadraticBezierTo(x1 + currentDepth * 0.5, y, x1 + currentDepth, y);
      canvas.drawPath(netPath, netPaint);
    }

    // Dikey İpler
    for (int j = 1; j <= cols; j++) {
      double x = x1 + (depth * (j / cols));
      
      // Dikey iplerin esnemesi (Top vurduğunda ipler dışa doğru kavis yapar)
      double xOffset = (j / cols) * _netStretch;
      
      final netPath = Path()
        ..moveTo(x + xOffset, y1)
        ..quadraticBezierTo(x + xOffset + (_netStretch * 0.3), 0, x + xOffset, y2); 
      canvas.drawPath(netPath, netPaint);
    }

    canvas.restore();
  }
}