import 'dart:math' as math;
import 'dart:ui' as ui; 
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:flame/extensions.dart'; 
import 'package:flame_forge2d/flame_forge2d.dart';
import 'game.dart';

class Ball extends BodyComponent<MyPhysicsGame> with ContactCallbacks {
  final Vector2 initialPosition;
  final Color color;
  final double radius;
  final bool isTeamA;
  final bool autoLaunch;
  final double strengthRatio;
  
  ui.Image? _textureImage;
  Rect? _srcRect; 

  final double minSpeed = 55.0; // ✅ Videodaki tempo için alt limit
  final double maxSpeed = 70.0; // ✅ Agresif kapışma için üst limit
  
  double currentSpeed = 0.0; 
  int _lastCollisionTime = 0; 

  Ball({
    required this.initialPosition, 
    required this.color, 
    required this.radius,
    required this.isTeamA,
    required this.autoLaunch,
    required this.strengthRatio,
  });

  @override
  Body createBody() {
    final bodyDef = BodyDef()
      ..type = BodyType.dynamic
      ..position = initialPosition
      ..bullet = true 
      ..linearDamping = 0.0 
      ..angularDamping = 0.8 
      ..userData = this; 

    final body = world.createBody(bodyDef);
    final shape = CircleShape()..radius = radius;
    
    final calculatedDensity = strengthRatio * 15.0; // ✅ Çarpışma şiddeti videoya göre artırıldı

    final fixtureDef = FixtureDef(shape)
      ..restitution = 1.0  
      ..density = calculatedDensity 
      ..friction = 0.0; // ✅ Sürtünme sıfır (Video akıcılığı)

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (autoLaunch) {
      launch();
    }
    
    try {
      final team = isTeamA ? game.teamA : game.teamB;
      
      String ballPath = team.logoPath.replaceFirst('.png', '_ball.png');
      
      try {
        _textureImage = await game.images.load(ballPath);
      } catch (e) {
        _textureImage = await game.images.load(team.logoPath);
      }

      if (_textureImage != null) {
        _srcRect = await _calculateBoundingBox(_textureImage!);
      }

    } catch (e) {
      debugPrint("Top görseli yüklenemedi: $e");
    }
  }

  // ✅ BU FONKSİYONUNU %100 KORUDUM (SİLMEMELİYDİM, HATA BENDEN)
  Future<Rect> _calculateBoundingBox(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      return Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    }

    int minX = image.width;
    int minY = image.height;
    int maxX = 0;
    int maxY = 0;

    final Uint8List bytes = byteData.buffer.asUint8List();
    final int width = image.width;
    final int height = image.height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int offset = (y * width + x) * 4;
        final int r = bytes[offset];
        final int g = bytes[offset + 1];
        final int b = bytes[offset + 2];
        final int alpha = bytes[offset + 3];

        if (alpha > 10 && (r > 15 || g > 15 || b > 15)) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (minX > maxX || minY > maxY) {
       return Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    }

    return Rect.fromLTRB(minX.toDouble(), minY.toDouble(), maxX.toDouble(), maxY.toDouble());
  }

  void _playKickSound() {
    if (currentSpeed < 10.0) return; 
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastCollisionTime > 150) {
      game.kickPool.start(volume: 1.0); 
      _lastCollisionTime = now;
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (!game.isMatchStarted || game.isMatchOver) return; 
    super.beginContact(other, contact);
    _playKickSound();

    if (other is Ball) {
      currentSpeed = maxSpeed; // ✅ Çarpışınca hız patlaması
      body.applyLinearImpulse(body.linearVelocity.normalized() * 50);
    } else {
      currentSpeed -= 2.0; 
    }
    
    currentSpeed = currentSpeed.clamp(minSpeed, maxSpeed);
  }

  void launch() {
    body.linearDamping = 0.0; 
    currentSpeed = minSpeed;
    final random = math.Random();
    
    // ✅ Hedef Merkez: Kapışma için toplar birbirine fırlatılır
    double targetX = isTeamA ? 1.0 : -1.0;
    double targetY = (random.nextDouble() - 0.5) * 0.4; 
    
    final dir = Vector2(targetX, targetY)..normalize();
    body.linearVelocity = dir * currentSpeed;
    body.angularVelocity = (random.nextDouble() - 0.5) * 12.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (!game.isMatchStarted) {
      body.linearVelocity = Vector2.zero();
      body.angularVelocity = 0;
      return;
    }

    if (game.isMatchOver) return;

    if (currentSpeed <= 0.0) {
      body.linearVelocity = Vector2.zero();
      body.angularVelocity = 0;
      return;
    }

    // ✅ MERKEZ ÇEKİMİ: Videodaki gibi orta saha kapışmasını sağlar
    final Vector2 centerGravity = (Vector2.zero() - body.position).normalized() * 5.0;
    body.applyForce(centerGravity);

    final pos = body.position;
    final velocity = body.linearVelocity;
    final distance = pos.length;

    // ✅ HIZ SABİTLEME
    if (velocity.length2 > 0) {
      final spin = body.angularVelocity;
      if (spin.abs() > 1.0) {
        final perpDir = Vector2(-velocity.y, velocity.x).normalized();
        final curveForce = perpDir * (spin * 15.0); // ✅ Falso gücü videodaki gibi artırıldı
        body.applyForce(curveForce);
      }
      body.linearVelocity = velocity.normalized() * currentSpeed;
    }

    if (distance > 22.0) {
      final velocityDir = velocity.normalized();
      final normal = pos.normalized(); 
      if (velocityDir.dot(normal).abs() < 0.3) {
        currentSpeed -= 3.0;
        currentSpeed = currentSpeed.clamp(minSpeed, maxSpeed);
        final kickDir = (Vector2.zero() - pos).normalized();
        body.linearVelocity = kickDir * currentSpeed;
        _playKickSound();
        body.angularVelocity += (math.Random().nextBool() ? 5.0 : -5.0); 
      }
    }

    if (math.Random().nextDouble() < 0.02) { 
      final chaos = Vector2.random()..scale(1.5 * (currentSpeed / 50.0)); 
      body.linearVelocity.add(chaos);
    }

    if (distance > 30.0) {
      game.resetMatch(isGoal: true, teamAScored: isTeamA);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_textureImage != null && _srcRect != null) {
      final double renderRadius = radius * 1.02; 
      final dst = Rect.fromLTWH(-renderRadius, -renderRadius, renderRadius * 2, renderRadius * 2);
      
      final paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high;

      canvas.drawImageRect(_textureImage!, _srcRect!, dst, paint);
    } else {
      canvas.drawCircle(Offset.zero, radius, Paint()..color = color);
      final linePaint = Paint()..color = Colors.black.withOpacity(0.4)..strokeWidth = 0.8;
      canvas.drawLine(Offset(0, -radius), Offset(0, radius), linePaint);
      canvas.drawLine(Offset(-radius, 0), Offset(radius, 0), linePaint);
    }
  }
}