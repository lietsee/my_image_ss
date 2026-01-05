import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../models/window_info.dart';

/// Windowsウィンドウを列挙・操作するサービス
class WindowService {
  static final WindowService _instance = WindowService._internal();
  factory WindowService() => _instance;
  WindowService._internal();

  final List<WindowInfo> _windows = [];

  /// 可視ウィンドウの一覧を取得
  List<WindowInfo> enumerateWindows() {
    _windows.clear();

    final callback = Pointer.fromFunction<WNDENUMPROC>(
      _enumWindowsCallback,
      0,
    );
    EnumWindows(callback, 0);

    // フィルタリング: タイトルがあり、可視で、オーナーがないウィンドウ
    return _windows
        .where((w) => w.title.isNotEmpty && _isTopLevelWindow(w.hwnd))
        .toList();
  }

  static int _enumWindowsCallback(int hwnd, int lParam) {
    if (IsWindowVisible(hwnd) != 0) {
      final length = GetWindowTextLength(hwnd);
      if (length > 0) {
        final buffer = wsalloc(length + 1);
        GetWindowText(hwnd, buffer, length + 1);
        final title = buffer.toDartString();
        free(buffer);

        // クラス名取得
        final classBuffer = wsalloc(256);
        GetClassName(hwnd, classBuffer, 256);
        final className = classBuffer.toDartString();
        free(classBuffer);

        WindowService()._windows.add(WindowInfo(
          hwnd: hwnd,
          title: title,
          className: className,
        ));
      }
    }
    return TRUE; // 続行
  }

  bool _isTopLevelWindow(int hwnd) {
    // オーナーウィンドウがない（トップレベル）
    final owner = GetWindow(hwnd, GW_OWNER);
    if (owner != 0) return false;

    // WS_EX_TOOLWINDOWスタイルを持たない
    final exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
    if ((exStyle & WS_EX_TOOLWINDOW) != 0) return false;

    return true;
  }

  /// 指定ウィンドウをフォアグラウンドに設定
  bool setForegroundWindow(int hwnd) {
    // ウィンドウが最小化されていれば復元
    if (IsIconic(hwnd) != 0) {
      ShowWindow(hwnd, SW_RESTORE);
    }
    return SetForegroundWindow(hwnd) != 0;
  }

  /// 自アプリのウィンドウハンドルを取得
  int getAppWindowHandle() {
    return GetForegroundWindow();
  }
}
