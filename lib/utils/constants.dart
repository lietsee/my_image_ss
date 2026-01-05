import 'package:flutter/material.dart';

/// アプリ全体で使用する定数
class AppConstants {
  // デフォルトのキャプチャ矩形サイズ
  static const double defaultRectWidth = 800;
  static const double defaultRectHeight = 600;
  static const double minRectSize = 100;

  // リサイズハンドルのサイズ
  static const double handleSize = 16;

  // 色設定
  static const Color overlayColor = Color(0x80000000);
  static const Color rectBorderColor = Colors.blue;
  static const Color handleColor = Colors.blue;

  // アニメーション時間
  static const Duration keyDelay = Duration(milliseconds: 50);
  static const Duration returnDelay = Duration(milliseconds: 100);
}
