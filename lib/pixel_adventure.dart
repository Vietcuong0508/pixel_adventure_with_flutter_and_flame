import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:pixel_adventure/components/jump_button.dart';
import 'package:pixel_adventure/components/menu/next_level.dart';
import 'package:pixel_adventure/components/menu/previous_level.dart';
import 'package:pixel_adventure/components/menu/restart.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/components/level.dart';

class PixelAdventure extends FlameGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection,
        TapCallbacks {
  @override
  Color backgroundColor() => const Color(0xFF211F30);
  late CameraComponent cam;
  Player player = Player();
  late JoystickComponent joystick;
  bool showControls = false;
  bool playSounds = true;
  double soundVolume = 1.0;
  List<String> levelNames = [
    'Level-01',
    'Level-02',
    'Level-03',
    'Level-04',
  ];
  int currentLevelIndex = 0;

  @override
  FutureOr<void> onLoad() async {
    /// Load all image into cache
    await images.loadAllImages();

    loadLevel();

    if (showControls) {
      addJoystick();
      add(JumpButton());
    }
    addAll([Restart(), NextLevel(), PreviousLevel()]);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showControls) {
      updateJoystick();
    }
    super.update(dt);
  }

  void addJoystick() {
    joystick = JoystickComponent(
        knob: SpriteComponent(
          sprite: Sprite(images.fromCache('HUD/Knob.png')),
        ),
        background: SpriteComponent(
            sprite: Sprite(images.fromCache("HUD/Joystick.png"))),
        margin: const EdgeInsets.only(left: 32, bottom: 32));
    add(joystick..priority = 10);
  }

  void updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        player.horizontalMovement = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        player.horizontalMovement = 1;
        break;
      default:
        player.horizontalMovement = 0;
        break;
    }
  }

  void loadNextLevel() {
    if (currentLevelIndex < levelNames.length - 1) {
      currentLevelIndex++;
      loadLevel();
    } else {
      currentLevelIndex = 0;
      loadLevel();
    }
  }

  void loadLevel() {
    removeWhere((component) => component is Level);
    Level world =
        Level(player: player, levelName: levelNames[currentLevelIndex]);

    cam = CameraComponent.withFixedResolution(
        world: world, width: 640, height: 360);

    cam.viewfinder.anchor = Anchor.topLeft;

    addAll([cam..priority = -10, world]);
  }
}
