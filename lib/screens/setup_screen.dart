import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/window_info.dart';
import '../services/window_service.dart';
import 'capture_screen.dart';

/// 初期設定画面
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final WindowService _windowService = WindowService();
  final TextEditingController _baseNameController = TextEditingController(text: 'screenshot');

  List<WindowInfo> _windows = [];
  WindowInfo? _selectedWindow;
  String _outputFolder = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWindows();
  }

  @override
  void dispose() {
    _baseNameController.dispose();
    super.dispose();
  }

  Future<void> _loadWindows() async {
    setState(() => _isLoading = true);

    // 少し遅延を入れてUIが更新されるのを待つ
    await Future.delayed(const Duration(milliseconds: 100));

    final windows = _windowService.enumerateWindows();

    setState(() {
      _windows = windows;
      _isLoading = false;
    });
  }

  Future<void> _selectFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '保存先フォルダを選択',
    );
    if (result != null) {
      setState(() => _outputFolder = result);
    }
  }

  bool get _canStart =>
      _selectedWindow != null &&
      _outputFolder.isNotEmpty &&
      _baseNameController.text.isNotEmpty;

  void _startCapture() {
    if (!_canStart) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaptureScreen(
          targetWindow: _selectedWindow!,
          outputFolder: _outputFolder,
          baseName: _baseNameController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スクリーンショット設定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ウィンドウ選択
            const Text(
              '1. 対象ウィンドウを選択',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<WindowInfo>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'ウィンドウを選択してください',
                    ),
                    value: _selectedWindow,
                    isExpanded: true,
                    items: _windows.map((w) {
                      return DropdownMenuItem(
                        value: w,
                        child: Text(
                          w.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedWindow = v),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadWindows,
                  tooltip: '更新',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // フォルダ選択
            const Text(
              '2. 保存先フォルダを選択',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _outputFolder.isEmpty ? 'フォルダを選択してください' : _outputFolder,
                      style: TextStyle(
                        color: _outputFolder.isEmpty ? Colors.grey : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _selectFolder,
                  tooltip: 'フォルダを選択',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ファイル名設定
            const Text(
              '3. ファイル名を設定',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'ベースファイル名',
                helperText: '例: screenshot → screenshot_001.jpg, screenshot_002.jpg...',
              ),
              controller: _baseNameController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 32),

            // 開始ボタン
            Center(
              child: SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('キャプチャ開始'),
                  onPressed: _canStart ? _startCapture : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // 操作説明
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '操作説明',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Space / S: スクリーンショット撮影'),
                  Text('← →: ブラウザに左右キーを送信'),
                  Text('R: リサイズモード'),
                  Text('ESC: 終了確認ダイアログ'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
