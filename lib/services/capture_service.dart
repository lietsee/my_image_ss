import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// 画面キャプチャサービス
class CaptureService {
  /// 指定領域のスクリーンショットを取得
  /// 戻り値はRGBA形式のピクセルデータ
  Uint8List? captureRegion(ui.Rect region) {
    final x = region.left.toInt();
    final y = region.top.toInt();
    final width = region.width.toInt();
    final height = region.height.toInt();

    if (width <= 0 || height <= 0) return null;

    // 画面のデバイスコンテキストを取得
    final hdcScreen = GetDC(NULL);
    if (hdcScreen == 0) return null;

    // メモリデバイスコンテキストを作成
    final hdcMem = CreateCompatibleDC(hdcScreen);
    if (hdcMem == 0) {
      ReleaseDC(NULL, hdcScreen);
      return null;
    }

    // 互換ビットマップを作成
    final hBitmap = CreateCompatibleBitmap(hdcScreen, width, height);
    if (hBitmap == 0) {
      DeleteDC(hdcMem);
      ReleaseDC(NULL, hdcScreen);
      return null;
    }

    // ビットマップをメモリDCに選択
    final hOldBitmap = SelectObject(hdcMem, hBitmap);

    // 画面からメモリDCにコピー
    BitBlt(hdcMem, 0, 0, width, height, hdcScreen, x, y, SRCCOPY);

    // ビットマップ情報ヘッダを設定
    final bmi = calloc<BITMAPINFO>();
    bmi.ref.bmiHeader.biSize = sizeOf<BITMAPINFOHEADER>();
    bmi.ref.bmiHeader.biWidth = width;
    bmi.ref.bmiHeader.biHeight = -height; // 上から下へ (Top-down DIB)
    bmi.ref.bmiHeader.biPlanes = 1;
    bmi.ref.bmiHeader.biBitCount = 32;
    bmi.ref.bmiHeader.biCompression = BI_RGB;

    // ピクセルデータ用のバッファを確保
    final bufferSize = width * height * 4;
    final pixels = calloc<Uint8>(bufferSize);

    // ビットマップデータを取得
    final result = GetDIBits(
      hdcMem,
      hBitmap,
      0,
      height,
      pixels,
      bmi,
      DIB_RGB_COLORS,
    );

    Uint8List? rgbaData;
    if (result != 0) {
      // BGRAからRGBAに変換
      final data = pixels.asTypedList(bufferSize);
      rgbaData = Uint8List(bufferSize);
      for (int i = 0; i < bufferSize; i += 4) {
        rgbaData[i] = data[i + 2];     // R <- B
        rgbaData[i + 1] = data[i + 1]; // G
        rgbaData[i + 2] = data[i];     // B <- R
        rgbaData[i + 3] = 255;         // A (完全不透明)
      }
    }

    // クリーンアップ
    SelectObject(hdcMem, hOldBitmap);
    DeleteObject(hBitmap);
    DeleteDC(hdcMem);
    ReleaseDC(NULL, hdcScreen);
    free(bmi);
    free(pixels);

    return rgbaData;
  }

  /// 画面サイズを取得
  ui.Size getScreenSize() {
    final width = GetSystemMetrics(SM_CXSCREEN);
    final height = GetSystemMetrics(SM_CYSCREEN);
    return ui.Size(width.toDouble(), height.toDouble());
  }
}
