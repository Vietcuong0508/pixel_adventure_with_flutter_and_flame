bool checkCollision(player, block) {
  final hitbox = player.hitbox;
  final playerX = player.position.x + hitbox.offsetX;
  final playerY = player.position.y + hitbox.offsetY;
  final playerWidth = hitbox.width;
  final playerHeight = hitbox.height;

  final blockX = block.x;
  final blockY = block.y;
  final blockWidth = block.width;
  final blockHeight = block.height;

  final fixeX = player.scale.x < 0
      ? playerX - (hitbox.offsetX * 2) - playerWidth
      : playerX;
  final fixeY = block.isPlatform ? playerY + playerHeight : playerY;

  return (fixeY < blockY + blockHeight &&
      playerY + playerHeight > blockY &&
      fixeX < blockX + blockWidth &&
      fixeX + playerWidth > blockX);
}
