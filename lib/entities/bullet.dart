import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spacehero/entities/entity.dart';

class Bullet extends Entity {
  final double shootAngle;
  final double _speed = 8;

  final double screenWidth;
  final double screenHeight;

  Bullet({
    required this.shootAngle,
    required shootPositionX,
    required shootPositionY,
    required this.screenWidth,
    required this.screenHeight,
  }) : super(
          spriteName: "bullet",
          x: shootPositionX,
          y: shootPositionY,
        );

  @override
  Widget build() {
    return Positioned(
      top: y,
      left: x,
      child: Transform.rotate(
        angle: shootAngle,
        child: sprites[currentSprite],
      ),
    );
  }

  @override
  void move() {
    x += sin(shootAngle) * _speed;
    y -= cos(shootAngle) * _speed;

    if (x > screenWidth || y > screenHeight || x < 0 || y < 0) {
      visible = false;
    }
  }
}
