import 'dart:ui';

import 'window_info.dart';

/// キャプチャ設定を保持するモデルクラス
class CaptureSettings {
  final WindowInfo? targetWindow;
  final String outputFolder;
  final String baseName;
  final Rect captureRect;

  const CaptureSettings({
    this.targetWindow,
    this.outputFolder = '',
    this.baseName = 'screenshot',
    this.captureRect = const Rect.fromLTWH(0, 0, 800, 600),
  });

  CaptureSettings copyWith({
    WindowInfo? targetWindow,
    String? outputFolder,
    String? baseName,
    Rect? captureRect,
  }) {
    return CaptureSettings(
      targetWindow: targetWindow ?? this.targetWindow,
      outputFolder: outputFolder ?? this.outputFolder,
      baseName: baseName ?? this.baseName,
      captureRect: captureRect ?? this.captureRect,
    );
  }

  bool get isValid =>
      targetWindow != null && outputFolder.isNotEmpty && baseName.isNotEmpty;
}
