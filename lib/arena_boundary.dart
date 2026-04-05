import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class ArenaBoundary extends BodyComponent {
  final double radius = 30.0;
  final double gapAngle = 33 * math.pi / 180; 

  @override
  Body createBody() {
    final bodyDef = BodyDef()
      ..type = BodyType.kinematic
      ..position = Vector2.zero()
      ..angularVelocity = 1.0 // Stadyumun kusursuz dönüş hızı
      ..userData = this;

    final body = world.createBody(bodyDef);

    final List<Vector2> vertices = [];
    final double startAngle = gapAngle / 2;
    final double endAngle = 2 * math.pi - (gapAngle / 2);
    const int segments = 60; 

    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final angle = startAngle + (endAngle - startAngle) * t;
      vertices.add(Vector2(radius * math.cos(angle), radius * math.sin(angle)));
    }

    final shape = ChainShape()..createChain(vertices);
    
    final fixtureDef = FixtureDef(shape)
      ..restitution = 0.9 
      ..friction = 0.2;

    body.createFixture(fixtureDef);

    // --- YENİ: GERÇEKÇİ DİREK FİZİĞİ (YUVARLAK ÇARPIŞMA) ---
    // Sahanın kesildiği yerlerin (direklerin) uçlarına yuvarlak fiziksel silindirler ekliyoruz.
    // Böylece top direğin iç kısmına çarparsa açısına göre içeri, dışına çarparsa dışarı seker.
    final double postRadius = 0.8; // Direklerin fiziksel kalınlığı

    final topPostShape = CircleShape()
      ..radius = postRadius
      ..position.setFrom(vertices.first); // Üst direğin konumu
    final topPostFixture = FixtureDef(topPostShape)
      ..restitution = 0.8  // Direkler duvardan biraz daha az esnektir (gerçekçi tok sekme)
      ..friction = 0.2;
    body.createFixture(topPostFixture);

    final bottomPostShape = CircleShape()
      ..radius = postRadius
      ..position.setFrom(vertices.last); // Alt direğin konumu
    final bottomPostFixture = FixtureDef(bottomPostShape)
      ..restitution = 0.8
      ..friction = 0.2;
    body.createFixture(bottomPostFixture);
    // -------------------------------------------------------

    return body;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final pitchPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius, pitchPaint);

    final fakeGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.15) 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final solidLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;

    // Alt katman (Hafif kalın transparan parlama)
    canvas.drawLine(Offset(0, -radius), Offset(0, radius), fakeGlowPaint);
    canvas.drawCircle(Offset.zero, 8.0, fakeGlowPaint);
    
    // Üst katman (Net çizgi)
    canvas.drawLine(Offset(0, -radius), Offset(0, radius), solidLinePaint);
    canvas.drawCircle(Offset.zero, 8.0, solidLinePaint);
    canvas.drawCircle(Offset.zero, 0.8, Paint()..color = Colors.white);
    
    final wallPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0; 

    // Fiziksel sınırları çizerken eklediğimiz yeni direkleri (CircleShape) atlıyoruz, 
    // sadece dış duvarı (ChainShape) çizdiriyoruz ki görsel bozulmasın.
    for (final fixture in body.fixtures) {
      if (fixture.shape is ChainShape) {
        final shape = fixture.shape as ChainShape;
        final path = Path();
        
        path.moveTo(shape.vertices[0].x, shape.vertices[0].y);
        for (int i = 1; i < shape.vertices.length; i++) {
          path.lineTo(shape.vertices[i].x, shape.vertices[i].y);
        }
        canvas.drawPath(path, wallPaint);
      }
    }
  }
}