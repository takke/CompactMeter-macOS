# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Windows版CompactMeterのmacOS移植版。Swift + SwiftUIを使用したメニューバーアプリケーション。
システムメトリクス（CPU、メモリ、ネットワーク、ディスクI/O）をリアルタイムで表示する。

## 技術スタック

- **言語**: Swift 5.5+
- **UIフレームワーク**: SwiftUI + AppKit（ハイブリッド構成）
- **非同期処理**: async/await + Combine
- **グラフィックス**: Core Graphics + Core Animation
- **データ永続化**: UserDefaults + Property Wrappers
- **システムAPI**: IOKit、SystemConfiguration、Quartz

## 開発コマンド

```bash
# Xcodeでプロジェクトを開く
open CompactMeter-macOS.xcodeproj

# コマンドラインビルド
xcodebuild -project CompactMeter-macOS.xcodeproj -scheme CompactMeter-macOS build

# テスト実行
xcodebuild test -project CompactMeter-macOS.xcodeproj -scheme CompactMeter-macOS

# デバッグビルド
xcodebuild -project CompactMeter-macOS.xcodeproj -scheme CompactMeter-macOS -configuration Debug build

# リリースビルド
xcodebuild -project CompactMeter-macOS.xcodeproj -scheme CompactMeter-macOS -configuration Release build
```

## アーキテクチャ

**MVVM + Repository パターン**を採用：

```
UI Layer (SwiftUI Views)
   ↓
ViewModel Layer (ObservableObject)
   ↓
Repository Layer (データ取得抽象化)
   ↓
Data Source Layer (システムAPI呼び出し)
```

### 主要コンポーネント

#### UI Layer
- `MenuBarView`: メニューバーアイコンとポップオーバー
- `MeterView`: メーター描画
- `SettingsView`: 設定画面
- `CircularMeter` / `LinearMeter`: メーターコンポーネント

#### ViewModel Layer
- `MenuBarViewModel`: メニューバー状態管理
- `MeterViewModel`: メーターデータ管理
- `SettingsViewModel`: 設定データ管理

#### Repository Layer
- `SystemMetricsRepository`: システム情報取得の抽象化
- `SettingsRepository`: 設定データの抽象化

#### Data Source Layer
- `CPUMonitor`: CPU使用率取得
- `MemoryMonitor`: メモリ使用量取得
- `NetworkMonitor`: ネットワーク通信量取得
- `DiskMonitor`: ディスクI/O取得

## プロジェクト構造

```
CompactMeter-macOS/
├── App/                    # アプリケーション基盤
├── Views/                  # UI コンポーネント
│   ├── MenuBar/           # メニューバー関連
│   ├── Meters/            # メーター表示
│   ├── Settings/          # 設定画面
│   └── Components/        # 共通コンポーネント
├── ViewModels/            # ビジネスロジック
├── Services/              # データサービス
│   ├── Repositories/      # データアクセス抽象化
│   └── DataSources/       # システム情報取得
├── Models/                # データモデル
├── Utils/                 # ユーティリティ
└── Resources/             # リソースファイル
```

## システムメトリクス取得

- **CPU使用率**: `host_processor_info()` または `sysctl()`
- **メモリ使用量**: `mach_host_self()` + `vm_statistics64()`
- **ネットワーク**: `getifaddrs()` または System Configuration framework
- **ディスクI/O**: IOKit framework経由

## 開発時の注意点

### パフォーマンス
- `@StateObject`、`@ObservedObject`の適切な使い分け
- バックグラウンド時の監視頻度調整
- 非同期処理によるUIスレッドの保護

### セキュリティ
- App Sandboxing対応が必要
- システム情報アクセス権限の適切な処理
- Developer ID Application証明書での署名

### UI/UX
- macOS Human Interface Guidelinesに準拠
- `NSStatusItem`でメニューバー常駐
- SwiftUIの`Canvas`または`Shape`でメーター描画

## 開発ロードマップ

1. **Phase 1**: プロジェクト初期化、基本メニューバーアプリ、システムメトリクス取得
2. **Phase 2**: メーター描画、設定画面、アニメーション実装
3. **Phase 3**: パフォーマンス最適化、エラーハンドリング、テスト、配布準備

## 言語設定

- 日本語でコメントを記述
- エラーメッセージやログも日本語で説明
- 簡潔で分かりやすいコードを心がける