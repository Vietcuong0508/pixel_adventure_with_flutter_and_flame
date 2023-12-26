import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class NextLevel extends SpriteComponent
    with HasGameRef<PixelAdventure>, TapCallbacks {
  NextLevel() : super(priority: 10);

  final margin = 32;
  final buttonSize = 20;

  @override
  FutureOr<void> onLoad() {
    sprite = Sprite(game.images.fromCache('Menu/Buttons/Next.png'));
    position = Vector2(game.size.x - 2 * margin - 2 * buttonSize, 0.0 + margin);
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (game.currentLevelIndex < game.levelNames.length - 1) {
      game.currentLevelIndex++;
      game.loadLevel();
    }
    super.onTapDown(event);
  }
}
