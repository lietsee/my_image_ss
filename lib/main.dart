import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ウィンドウマネージャーの初期化
  await windowManager.ensureInitialized();

  // ウィンドウオプションの設定
  const windowOptions = WindowOptions(
    size: Size(700, 600),
    minimumSize: Size(600, 500),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Screenshot Tool',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyImageSSApp());
}
