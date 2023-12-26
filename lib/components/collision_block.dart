import 'package:flame/components.dart';

class CollisionBlock extends PositionComponent {
  bool isPlatform;
  bool isBox;
  CollisionBlock({position, size, this.isPlatform = false, this.isBox = false})
      : super(position: position, size: size);
}
