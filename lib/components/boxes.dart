import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class Boxes extends SpriteAnimationComponent
    with HasGameRef<PixelAdventure>, CollisionCallbacks {
  Boxes({position, size}) : super(position: position, size: size);

  static final hitbox =
      CustomHitbox(offsetX: 5, offsetY: 2, width: 27, height: 24);
  bool hit = false;

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));

    animation = SpriteAnimation.fromFrameData(
        game.images.fromCache('Items/Boxes/Box1/Idle.png'),
        SpriteAnimationData.sequenced(
            amount: 1, stepTime: 1, textureSize: Vector2(24, 28)));
    return super.onLoad();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) _reachedBoxes();

    super.onCollisionStart(intersectionPoints, other);
  }

  void _reachedBoxes() async {
    animation = SpriteAnimation.fromFrameData(
        game.images.fromCache('Items/Boxes/Box1/Hit (28x24).png'),
        SpriteAnimationData.sequenced(
            amount: 3,
            stepTime: 0.05,
            textureSize: Vector2(28, 24),
            loop: false));

    await animationTicker?.completed;
    // removeFromParent();

    animation = SpriteAnimation.fromFrameData(
        game.images.fromCache('Items/Boxes/Box1/Break.png'),
        SpriteAnimationData.sequenced(
            amount: 1, stepTime: 1, textureSize: Vector2(28, 24), loop: false));
    await animationTicker?.completed;
    removeFromParent();
  }
}
