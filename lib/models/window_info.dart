/// ウィンドウ情報を保持するモデルクラス
class WindowInfo {
  final int hwnd;
  final String title;
  final String className;

  const WindowInfo({
    required this.hwnd,
    required this.title,
    required this.className,
  });

  @override
  String toString() => 'WindowInfo(hwnd: $hwnd, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WindowInfo &&
          runtimeType == other.runtimeType &&
          hwnd == other.hwnd;

  @override
  int get hashCode => hwnd.hashCode;
}
