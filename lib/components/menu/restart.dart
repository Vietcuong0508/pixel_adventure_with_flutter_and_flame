import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class Restart extends SpriteComponent
    with HasGameRef<PixelAdventure>, TapCallbacks {
  Restart() : super(priority: 10);

  final margin = 32;
  final buttonSize = 20;

  @override
  FutureOr<void> onLoad() {
    sprite = Sprite(game.images.fromCache('Menu/Buttons/Restart.png'));
    position = Vector2(game.size.x - 2 * margin - buttonSize, 0.0 + margin);
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.loadLevel();
    super.onTapDown(event);
  }
}
