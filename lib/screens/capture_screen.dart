import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/window_info.dart';
import '../services/capture_service.dart';
import '../services/file_service.dart';
import '../services/keyboard_service.dart';
import '../services/window_service.dart';
import '../utils/constants.dart';
import '../widgets/overlay_painter.dart';
import '../widgets/resize_handle.dart';

/// キャプチャ画面
class CaptureScreen extends StatefulWidget {
  final WindowInfo targetWindow;
  final String outputFolder;
  final String baseName;

  const CaptureScreen({
    super.key,
    required this.targetWindow,
    required this.outputFolder,
    required this.baseName,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final CaptureService _captureService = CaptureService();
  final FileService _fileService = FileService();
  final KeyboardService _keyboardService = KeyboardService();
  final WindowService _windowService = WindowService();

  late Rect _captureRect;
  bool _isResizing = true;
  int _captureCount = 0;
  int _appWindowHandle = 0;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeServices();

    // アプリ起動時に自分のウィンドウハンドルを記録
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appWindowHandle = _windowService.getAppWindowHandle();
    });
  }

  void _initializeServices() {
    _fileService.configure(
      baseName: widget.baseName,
      folder: widget.outputFolder,
    );

    // 画面サイズを取得してキャプチャ矩形を中央に配置
    final screenSize = _captureService.getScreenSize();
    _captureRect = Rect.fromCenter(
      center: Offset(screenSize.width / 2, screenSize.height / 2),
      width: AppConstants.defaultRectWidth,
      height: AppConstants.defaultRectHeight,
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// キーボードイベントハンドラ
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // Space または S: スクリーンショット
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyS) {
      if (!_isResizing) {
        _takeScreenshot();
        return KeyEventResult.handled;
      }
    }

    // 左矢印: ブラウザに送信
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (!_isResizing) {
        _sendLeftArrow();
        return KeyEventResult.handled;
      }
    }

    // 右矢印: ブラウザに送信
    if (key == LogicalKeyboardKey.arrowRight) {
      if (!_isResizing) {
        _sendRightArrow();
        return KeyEventResult.handled;
      }
    }

    // R: リサイズモード
    if (key == LogicalKeyboardKey.keyR) {
      setState(() => _isResizing = true);
      return KeyEventResult.handled;
    }

    // ESC: 終了確認
    if (key == LogicalKeyboardKey.escape) {
      _showExitDialog();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// スクリーンショットを撮影
  Future<void> _takeScreenshot() async {
    final data = _captureService.captureRegion(_captureRect);
    if (data != null) {
      await _fileService.saveScreenshot(
        data,
        _captureRect.width.toInt(),
        _captureRect.height.toInt(),
      );
      setState(() {
        _captureCount++;
      });
    }
  }

  /// 左矢印キーをブラウザに送信
  Future<void> _sendLeftArrow() async {
    await _keyboardService.sendLeftArrow(widget.targetWindow.hwnd);
    // 自分のウィンドウにフォーカスを戻す
    _windowService.setForegroundWindow(_appWindowHandle);
    _focusNode.requestFocus();
  }

  /// 右矢印キーをブラウザに送信
  Future<void> _sendRightArrow() async {
    await _keyboardService.sendRightArrow(widget.targetWindow.hwnd);
    // 自分のウィンドウにフォーカスを戻す
    _windowService.setForegroundWindow(_appWindowHandle);
    _focusNode.requestFocus();
  }

  /// 終了確認ダイアログを表示
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('終了確認'),
        content: Text(
          '$_captureCount枚のスクリーンショットを保存しました。\n'
          '保存先: ${widget.outputFolder}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // 設定画面に戻る
            },
            child: const Text('最初から'),
          ),
          TextButton(
            onPressed: () => exit(0),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('終了'),
          ),
        ],
      ),
    );
  }

  /// リサイズ処理
  void _onResize(HandlePosition position, Offset delta) {
    setState(() {
      var left = _captureRect.left;
      var top = _captureRect.top;
      var right = _captureRect.right;
      var bottom = _captureRect.bottom;

      switch (position) {
        case HandlePosition.topLeft:
          left += delta.dx;
          top += delta.dy;
          break;
        case HandlePosition.topRight:
          right += delta.dx;
          top += delta.dy;
          break;
        case HandlePosition.bottomLeft:
          left += delta.dx;
          bottom += delta.dy;
          break;
        case HandlePosition.bottomRight:
          right += delta.dx;
          bottom += delta.dy;
          break;
      }

      // 最小サイズを確保
      if (right - left >= AppConstants.minRectSize &&
          bottom - top >= AppConstants.minRectSize) {
        _captureRect = Rect.fromLTRB(left, top, right, bottom);
      }
    });
  }

  /// リサイズを確定
  void _confirmResize() {
    setState(() => _isResizing = false);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 半透明オーバーレイ（矩形外を暗くする）
            Positioned.fill(
              child: CustomPaint(
                painter: OverlayPainter(
                  holeRect: _captureRect,
                  overlayColor: AppConstants.overlayColor,
                ),
              ),
            ),

            // リサイズハンドル（リサイズモード時のみ）
            if (_isResizing) ...[
              // 左上
              Positioned(
                left: _captureRect.left - AppConstants.handleSize / 2,
                top: _captureRect.top - AppConstants.handleSize / 2,
                child: ResizeHandle(
                  position: HandlePosition.topLeft,
                  onDragUpdate: (delta) =>
                      _onResize(HandlePosition.topLeft, delta),
                ),
              ),
              // 右上
              Positioned(
                left: _captureRect.right - AppConstants.handleSize / 2,
                top: _captureRect.top - AppConstants.handleSize / 2,
                child: ResizeHandle(
                  position: HandlePosition.topRight,
                  onDragUpdate: (delta) =>
                      _onResize(HandlePosition.topRight, delta),
                ),
              ),
              // 左下
              Positioned(
                left: _captureRect.left - AppConstants.handleSize / 2,
                top: _captureRect.bottom - AppConstants.handleSize / 2,
                child: ResizeHandle(
                  position: HandlePosition.bottomLeft,
                  onDragUpdate: (delta) =>
                      _onResize(HandlePosition.bottomLeft, delta),
                ),
              ),
              // 右下
              Positioned(
                left: _captureRect.right - AppConstants.handleSize / 2,
                top: _captureRect.bottom - AppConstants.handleSize / 2,
                child: ResizeHandle(
                  position: HandlePosition.bottomRight,
                  onDragUpdate: (delta) =>
                      _onResize(HandlePosition.bottomRight, delta),
                ),
              ),

              // 確定ボタン（右上外側）
              Positioned(
                left: _captureRect.right + 8,
                top: _captureRect.top,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('確定'),
                  onPressed: _confirmResize,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],

            // ステータスバー（下部）
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // 対象ウィンドウ
                    const Icon(Icons.window, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.targetWindow.title,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // キャプチャ数
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'キャプチャ: $_captureCount枚',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 操作ガイド
                    Text(
                      _isResizing
                          ? 'ハンドルをドラッグしてサイズ調整 → 確定ボタン'
                          : 'Space/S: 撮影 | ←→: ページ移動 | R: リサイズ | ESC: 終了',
                      style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // サイズ表示（矩形の中央上）
            if (_isResizing)
              Positioned(
                left: _captureRect.left + (_captureRect.width - 120) / 2,
                top: _captureRect.top + 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_captureRect.width.toInt()} x ${_captureRect.height.toInt()}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
