import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

/// ファイル保存サービス
class FileService {
  String _baseName = 'screenshot';
  String _outputFolder = '';
  int _counter = 1;

  /// 設定を初期化
  void configure({required String baseName, required String folder}) {
    _baseName = baseName;
    _outputFolder = folder;
    _counter = _findNextCounter();
  }

  /// 既存ファイルから次の連番を検索
  int _findNextCounter() {
    final dir = Directory(_outputFolder);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      return 1;
    }

    final pattern = RegExp('${RegExp.escape(_baseName)}_(\\d+)\\.jpg', caseSensitive: false);
    int maxCounter = 0;

    for (final entity in dir.listSync()) {
      if (entity is File) {
        final fileName = path.basename(entity.path);
        final match = pattern.firstMatch(fileName);
        if (match != null) {
          final num = int.tryParse(match.group(1)!) ?? 0;
          if (num > maxCounter) maxCounter = num;
        }
      }
    }

    return maxCounter + 1;
  }

  /// スクリーンショットをJPEGで保存
  /// 戻り値は保存されたファイルのパス
  Future<String> saveScreenshot(
    Uint8List rgbaData,
    int width,
    int height, {
    int quality = 90,
  }) async {
    // RGBAデータからImageオブジェクトを作成
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgbaData.buffer,
      format: img.Format.uint8,
      numChannels: 4,
    );

    // ファイル名を生成（3桁ゼロ埋め）
    final filename = '${_baseName}_${_counter.toString().padLeft(3, '0')}.jpg';
    final filePath = path.join(_outputFolder, filename);

    // JPEGエンコード
    final jpg = img.encodeJpg(image, quality: quality);

    // ファイル保存
    await File(filePath).writeAsBytes(jpg);

    // カウンターをインクリメント
    _counter++;

    return filePath;
  }

  /// 現在のカウンター値を取得
  int get currentCounter => _counter;

  /// 出力フォルダパスを取得
  String get outputFolder => _outputFolder;

  /// ベース名を取得
  String get baseName => _baseName;
}
