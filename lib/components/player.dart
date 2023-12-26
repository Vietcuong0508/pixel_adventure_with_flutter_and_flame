import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/components/Checkpoint.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
import 'package:pixel_adventure/components/enemies/chicken.dart';
import 'package:pixel_adventure/components/fruit.dart';
import 'package:pixel_adventure/components/saw.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState {
  idle,
  running,
  jumping,
  falling,
  hit,
  appearing,
  disappearing,
  doubleJump,
  wallJump,
}

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, KeyboardHandler, CollisionCallbacks {
  String character;
  Player({position, this.character = 'Ninja Frog'}) : super(position: position);

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation appearingAnimation;
  late final SpriteAnimation disappearingAnimation;
  late final SpriteAnimation doubleJumpAnimation;
  late final SpriteAnimation wallJumpAnimation;
  final double stepTime = 0.05;

  final double _gravity = 10;
  final double _jumpForce = 260;
  final double _terminalVelocity = 300;

  double horizontalMovement = 0;
  double horizontal = 1;
  double moveSpeed = 100;
  Vector2 startingPosition = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool hasJumped = false;
  bool onAir = false;
  bool gotHit = false;
  bool isWall = false;
  bool secondJump = false;
  bool reachedCheckpoint = false;
  List<CollisionBlock> collisionBlocks = [];
  List<String> lstCharacter = [
    'Mask Dude',
    'Ninja Frog',
    'Pink Man',
    'Virtual Guy'
  ];
  CustomHitbox hitbox =
      CustomHitbox(offsetX: 10, offsetY: 5, width: 14, height: 28);

  double fixedDeltaTime = 1 / 60;
  double accumulateTime = 0;
  static const _bounceHeight = 260.0;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimation();

    startingPosition = Vector2(position.x, position.y);

    add(RectangleHitbox(
        position: Vector2(hitbox.offsetX, hitbox.offsetY),
        size: Vector2(hitbox.width, hitbox.height)));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    accumulateTime += dt;

    while (accumulateTime >= fixedDeltaTime) {
      if (!gotHit && !reachedCheckpoint) {
        _updatePlayerState();
        _updatePlayerMovement(fixedDeltaTime);
        _checkHorizontalCollisions();
        _applyGravity(fixedDeltaTime);
        _checkVerticalCollisions();
        _checkOnTheAir();
        _checkOnWall();
      }
      accumulateTime -= fixedDeltaTime;
    }

    super.update(dt);
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isKeyDown = event is RawKeyDownEvent;

    if (!event.repeat && isKeyDown) {
      hasJumped = keysPressed.contains(LogicalKeyboardKey.space) ||
          keysPressed.contains(LogicalKeyboardKey.arrowUp);
    }

    final isLeftKeyPress = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPress = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);

    if (isLeftKeyPress) {
      isWall = false;
    }

    if (isRightKeyPress) {
      isWall = false;
    }

    horizontalMovement += isLeftKeyPress ? -1 : 0;
    horizontalMovement += isRightKeyPress ? 1 : 0;

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!reachedCheckpoint) {
      if (other is Fruit) other.collidedWithPlayer();
      if (other is Saw) respawn();
      if (other is Chicken) other.collidedWithPlayer();
      if (other is Checkpoint && !reachedCheckpoint) _reachedCheckpoint();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void _loadAllAnimation() {
    idleAnimation = _spriteAnimation('Idle', 11);
    runningAnimation = _spriteAnimation('Run', 12);
    jumpingAnimation = _spriteAnimation('Jump', 1);
    fallingAnimation = _spriteAnimation('Fall', 1);
    hitAnimation = _spriteAnimation('Hit', 7)..loop = false;
    appearingAnimation = _specialSpriteAnimation('Appearing', 7);
    disappearingAnimation = _specialSpriteAnimation('Desappearing', 7);
    doubleJumpAnimation = _spriteAnimation('Double Jump', 6);
    wallJumpAnimation = _spriteAnimation('Wall Jump', 5);

    /// List of all animations
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.appearing: appearingAnimation,
      PlayerState.disappearing: disappearingAnimation,
      PlayerState.doubleJump: doubleJumpAnimation,
      PlayerState.wallJump: wallJumpAnimation,
    };

    /// Set current animations
    current = PlayerState.running;
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
        game.images.fromCache('Main Characters/$character/$state (32x32).png'),
        SpriteAnimationData.sequenced(
            amount: amount, stepTime: stepTime, textureSize: Vector2.all(32)));
  }

  SpriteAnimation _specialSpriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
        game.images.fromCache('Main Characters/$state (96x96).png'),
        SpriteAnimationData.sequenced(
            amount: amount,
            stepTime: stepTime,
            textureSize: Vector2.all(96),
            loop: false));
  }

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    /// Checking if moving, set running
    if (velocity.x > 0 || velocity.x < 0) playerState = PlayerState.running;

    /// Checking if jumping, set jumping
    if (velocity.y < 0 && onAir) {
      playerState = PlayerState.jumping;
    }

    /// Checking if falling, set falling
    if (velocity.y > 0 && onAir && isWall == false) {
      playerState = PlayerState.falling;
    }

    /// Checking if double jumping set double jumping
    if (velocity.y < 0 && secondJump == false && isWall == false) {
      playerState = PlayerState.doubleJump;
    }

    /// Checking if wall jumping set wall jumping
    if (velocity.y > 0 && isWall == true) {
      playerState = PlayerState.wallJump;
    }

    current = playerState;
  }

  void _updatePlayerMovement(double dt) {
    if (hasJumped && (isOnGround || secondJump || isWall)) _playerJump(dt);

    // if (velocity.y > _gravity) isOnGround = false; /// optional jump on the air

    velocity.x = horizontalMovement * moveSpeed;

    position.x += velocity.x * dt;
  }

  void _playerJump(double dt) async {
    if (game.playSounds) {
      FlameAudio.play('jump.wav', volume: game.soundVolume);
    }
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;

    secondJump = !secondJump;
    isOnGround = false;
    hasJumped = false;
    if (isWall && isOnGround == false && secondJump == false) {
      position.x = position.x + (hitbox.offsetX * horizontal);
      isWall = false;
      isOnGround = true;
      secondJump = false;
    }
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (!block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            horizontal = -1;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            break;
          }
          if (velocity.x < 0) {
            velocity.x = 0;
            horizontal = 1;
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
            break;
          }
        }
      }
    }
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
    if (velocity.y > 0 && isWall) {
      velocity.y = 10;
    }
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            secondJump = false;
            break;
          }
        }
      } else if (block.isBox) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = -_bounceHeight;
            // position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            secondJump = false;
            block.removeFromParent();
            break;
          }
          if (velocity.y < 0) {
            // position.y = block.y + block.height - hitbox.offsetY;
            block.removeFromParent();
          }
        }
      } else {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            secondJump = false;
            break;
          }
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height - hitbox.offsetY;
          }
        }
      }
    }
  }

  void respawn() async {
    if (game.playSounds) {
      FlameAudio.play('hit.wav', volume: game.soundVolume);
    }
    const canMoveDuration = Duration(milliseconds: 400);
    gotHit = true;
    current = PlayerState.hit;

    await animationTicker?.completed;
    animationTicker?.reset();

    scale.x = 1;
    position = startingPosition - Vector2.all(32);
    current = PlayerState.appearing;

    await animationTicker?.completed;
    animationTicker?.reset();

    velocity = Vector2.zero();
    position = startingPosition;
    _updatePlayerState();
    Future.delayed(canMoveDuration, () => gotHit = false);
  }

  void _reachedCheckpoint() async {
    reachedCheckpoint = true;

    if (game.playSounds) {
      FlameAudio.play('disappear.wav', volume: game.soundVolume);
    }

    if (scale.x > 0) {
      position = position - Vector2.all(32);
    } else if (scale.x < 0) {
      position = position + Vector2(32, -32);
    }

    current = PlayerState.disappearing;

    await animationTicker?.completed;
    animationTicker?.reset();

    reachedCheckpoint = false;

    position = Vector2.all(-640);

    const waitToChangeDuration = Duration(seconds: 3);
    Future.delayed(waitToChangeDuration, () => game.loadNextLevel());
  }

  void collidedWithEnemy() {
    respawn();
  }

  void _checkOnTheAir() {
    if (velocity.y != 0 && isWall == false) {
      onAir = true;
    }
  }

  void _checkOnWall() {
    for (var block in collisionBlocks) {
      if (velocity.x == 0 &&
          horizontal == 1 &&
          position.x - hitbox.offsetX - hitbox.width - block.width == block.x) {
        isWall = true;
        if (position.y + hitbox.offsetY > block.y + block.height) {
          isWall = false;
        }
        if (position.y + 2 * hitbox.offsetY < block.y) {
          isWall = false;
        }
      }
      if (velocity.x == 0 &&
          horizontal == -1 &&
          position.x + hitbox.offsetX + hitbox.width == block.x) {
        isWall = true;
        if (position.y + hitbox.offsetY > block.y + block.height) {
          isWall = false;
        }
        if (position.y + 2 * hitbox.offsetY < block.y) {
          isWall = false;
        }
      }
    }
  }
}
