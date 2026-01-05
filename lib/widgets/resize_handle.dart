import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// リサイズハンドルの位置を表す列挙型
enum HandlePosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// 四隅のリサイズハンドルウィジェット
class ResizeHandle extends StatelessWidget {
  final HandlePosition position;
  final VoidCallback? onDragStart;
  final Function(Offset delta)? onDragUpdate;
  final VoidCallback? onDragEnd;

  const ResizeHandle({
    super.key,
    required this.position,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => onDragStart?.call(),
      onPanUpdate: (details) => onDragUpdate?.call(details.delta),
      onPanEnd: (_) => onDragEnd?.call(),
      child: MouseRegion(
        cursor: _getCursor(),
        child: Container(
          width: AppConstants.handleSize,
          height: AppConstants.handleSize,
          decoration: BoxDecoration(
            color: AppConstants.handleColor,
            border: Border.all(color: Colors.white, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  MouseCursor _getCursor() {
    switch (position) {
      case HandlePosition.topLeft:
      case HandlePosition.bottomRight:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case HandlePosition.topRight:
      case HandlePosition.bottomLeft:
        return SystemMouseCursors.resizeUpRightDownLeft;
    }
  }
}
