/// アプリの状態を表す列挙型
enum AppScreen {
  setup,    // 設定画面
  capture,  // キャプチャ画面
}

/// アプリ全体の状態を保持するモデルクラス
class AppState {
  final AppScreen currentScreen;
  final int captureCount;
  final bool isResizing;

  const AppState({
    this.currentScreen = AppScreen.setup,
    this.captureCount = 0,
    this.isResizing = true,
  });

  AppState copyWith({
    AppScreen? currentScreen,
    int? captureCount,
    bool? isResizing,
  }) {
    return AppState(
      currentScreen: currentScreen ?? this.currentScreen,
      captureCount: captureCount ?? this.captureCount,
      isResizing: isResizing ?? this.isResizing,
    );
  }
}
