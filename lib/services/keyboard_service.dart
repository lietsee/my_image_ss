import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'window_service.dart';

/// キーボード入力を送信するサービス
class KeyboardService {
  static const int VK_LEFT = 0x25;
  static const int VK_RIGHT = 0x27;

  final WindowService _windowService = WindowService();

  /// 指定ウィンドウにキーを送信
  /// ウィンドウをアクティブ化してキーを送り、その後元に戻す
  Future<void> sendKeyToWindow(int targetHwnd, int virtualKeyCode) async {
    // 現在のフォアグラウンドウィンドウを保存
    final currentForeground = GetForegroundWindow();

    try {
      // ターゲットウィンドウをアクティブ化
      _windowService.setForegroundWindow(targetHwnd);

      // ウィンドウがアクティブになるまで少し待機
      await Future.delayed(const Duration(milliseconds: 50));

      // キー入力を送信
      _sendKey(virtualKeyCode);

      // キー入力が処理されるまで待機
      await Future.delayed(const Duration(milliseconds: 100));
    } finally {
      // 元のウィンドウに戻す
      if (currentForeground != 0 && currentForeground != targetHwnd) {
        SetForegroundWindow(currentForeground);
      }
    }
  }

  /// SendInputを使用してキー入力を送信
  void _sendKey(int vkCode) {
    final inputs = calloc<INPUT>(2);

    // キーダウン
    inputs[0].type = INPUT_KEYBOARD;
    inputs[0].ki.wVk = vkCode;
    inputs[0].ki.dwFlags = 0;
    inputs[0].ki.time = 0;
    inputs[0].ki.dwExtraInfo = 0;

    // キーアップ
    inputs[1].type = INPUT_KEYBOARD;
    inputs[1].ki.wVk = vkCode;
    inputs[1].ki.dwFlags = KEYEVENTF_KEYUP;
    inputs[1].ki.time = 0;
    inputs[1].ki.dwExtraInfo = 0;

    SendInput(2, inputs, sizeOf<INPUT>());
    free(inputs);
  }

  /// 左矢印キーを送信
  Future<void> sendLeftArrow(int targetHwnd) async {
    await sendKeyToWindow(targetHwnd, VK_LEFT);
  }

  /// 右矢印キーを送信
  Future<void> sendRightArrow(int targetHwnd) async {
    await sendKeyToWindow(targetHwnd, VK_RIGHT);
  }
}
