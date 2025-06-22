# CompactMeter-macOS アーキテクチャ設計

Windows版CompactMeterをmacOSに移植するためのアーキテクチャ検討結果

## プロジェクト概要

### 目標
Windows版CompactMeterの機能をmacOSで再現し、macOSネイティブな体験を提供する

### 対象機能
- CPU使用率モニタリング
- メモリ使用率モニタリング  
- ネットワーク通信量モニタリング
- ディスクI/Oモニタリング
- リアルタイムビジュアルメーター表示
- 設定画面
- メニューバーアプリとしての動作

## 技術スタック

### Core Technologies
- **言語**: Swift 5.5+
- **UIフレームワーク**: SwiftUI + AppKit (ハイブリッド)
- **非同期処理**: async/await + Combine
- **グラフィックス**: Core Graphics + Core Animation
- **データ永続化**: UserDefaults + Property Wrappers

### システムAPI
- **IOKit**: ハードウェア情報取得
- **SystemConfiguration**: ネットワーク状態監視
- **Quartz**: 高DPI対応描画
- **Foundation**: 基本的なシステムAPI

## アーキテクチャパターン

### MVVM + Repository パターン

```
┌─────────────────┐
│   SwiftUI Views │ ← メーター表示、設定画面
└─────────────────┘
         │
┌─────────────────┐
│   ViewModels    │ ← ObservableObject、UI状態管理
└─────────────────┘
         │
┌─────────────────┐
│  Repositories   │ ← データ取得の抽象化
└─────────────────┘
         │
┌─────────────────┐
│  Data Sources   │ ← システムAPI呼び出し
└─────────────────┘
```

### コンポーネント設計

#### 1. UI Layer (SwiftUI Views)
```swift
// メイン表示
- MenuBarView: メニューバーアイコンとポップオーバー
- MeterView: メーター描画
- SettingsView: 設定画面
- AboutView: アプリ情報

// コンポーネント
- CircularMeter: 円形メーター
- LinearMeter: 線形メーター
- MeterLabel: ラベル表示
```

#### 2. ViewModel Layer
```swift
- MenuBarViewModel: メニューバー状態管理
- MeterViewModel: メーターデータ管理
- SettingsViewModel: 設定データ管理
```

#### 3. Repository Layer
```swift
- SystemMetricsRepository: システム情報取得の抽象化
- SettingsRepository: 設定データの抽象化
```

#### 4. Data Source Layer
```swift
- CPUMonitor: CPU使用率取得
- MemoryMonitor: メモリ使用量取得
- NetworkMonitor: ネットワーク通信量取得
- DiskMonitor: ディスクI/O取得
```

## プロジェクト構造

```
CompactMeter-macOS/
├── CompactMeter-macOS.xcodeproj
├── CompactMeter-macOS/
│   ├── App/
│   │   ├── CompactMeterApp.swift
│   │   ├── AppDelegate.swift
│   │   └── MenuBarManager.swift
│   ├── Views/
│   │   ├── MenuBar/
│   │   │   ├── MenuBarView.swift
│   │   │   └── MenuBarPopover.swift
│   │   ├── Meters/
│   │   │   ├── MeterContainerView.swift
│   │   │   ├── CircularMeterView.swift
│   │   │   └── LinearMeterView.swift
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift
│   │   │   ├── GeneralSettingsView.swift
│   │   │   └── MeterSettingsView.swift
│   │   └── Components/
│   │       ├── MeterLabel.swift
│   │       └── ColorPicker.swift
│   ├── ViewModels/
│   │   ├── MenuBarViewModel.swift
│   │   ├── MeterViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Services/
│   │   ├── Repositories/
│   │   │   ├── SystemMetricsRepository.swift
│   │   │   └── SettingsRepository.swift
│   │   └── DataSources/
│   │       ├── CPUMonitor.swift
│   │       ├── MemoryMonitor.swift
│   │       ├── NetworkMonitor.swift
│   │       └── DiskMonitor.swift
│   ├── Models/
│   │   ├── MetricData.swift
│   │   ├── MeterConfiguration.swift
│   │   └── AppSettings.swift
│   ├── Utils/
│   │   ├── Extensions/
│   │   │   ├── Color+Extensions.swift
│   │   │   └── View+Extensions.swift
│   │   ├── Constants.swift
│   │   └── Formatters.swift
│   └── Resources/
│       ├── Assets.xcassets
│       ├── Info.plist
│       └── Localizable.strings
├── Tests/
│   ├── CompactMeter-macOSTests/
│   └── CompactMeter-macOSUITests/
├── README.md
├── ARCHITECTURE.md
└── CHANGELOG.md
```

## システムメトリクス取得方法

### CPU使用率
```swift
// host_processor_info()またはsysctl()を使用
// リアルタイム取得のためタイマーベースで定期実行
```

### メモリ使用量
```swift
// mach_host_self() + vm_statistics64()
// 物理メモリ、仮想メモリ、スワップ情報を取得
```

### ネットワーク通信量
```swift
// getifaddrs()またはSystem Configuration framework
// インターフェース別の送受信バイト数を監視
```

### ディスクI/O
```swift
// IOKit framework
// IOServiceMatching()でディスクサービスを取得
// 読み書きバイト数、IOPS情報を監視
```

## UI/UX設計

### メニューバーアプリ仕様
- `NSStatusItem`を使用してメニューバーに常駐
- クリックでポップオーバー表示
- 設定画面は独立ウィンドウ

### メーター表示
- SwiftUIの`Canvas`または`Shape`を使用
- Core Animationによるスムーズなアニメーション
- カスタマイズ可能な色とレイアウト

### 設定画面
- SwiftUI標準のSettings API使用
- タブベースの設定画面
- リアルタイムプレビュー

## パフォーマンス考慮事項

### メモリ効率
- `@StateObject`、`@ObservedObject`の適切な使い分け
- 不要なView再描画の防止
- タイマーのライフサイクル管理

### CPU効率
- バックグラウンド時の監視頻度調整
- 非同期処理による UI スレッドの保護
- Core Animationハードウェアアクセラレーション活用

## セキュリティ・権限

### 必要な権限
- システム情報アクセス権限
- ネットワーク情報アクセス権限
- App Sandboxing対応

### 配布準備
- Developer ID Application証明書
- 公証 (Notarization) 対応
- Gatekeeper対応

## 開発ロードマップ

### Phase 1: 基盤構築
1. プロジェクト初期化
2. 基本的なメニューバーアプリ作成
3. システムメトリクス取得の実装

### Phase 2: UI実装
1. メーター描画機能
2. 設定画面
3. アニメーション実装

### Phase 3: 最適化・仕上げ
1. パフォーマンス最適化
2. エラーハンドリング
3. テスト作成
4. 配布準備

## 技術的課題と対策

### 課題1: システム情報取得の複雑さ
**対策**: Repository パターンで抽象化し、プラットフォーム固有のコードを分離

### 課題2: リアルタイム更新のパフォーマンス
**対策**: Combineを使用した効率的なデータストリーム設計

### 課題3: macOS版固有のUI/UX
**対策**: Human Interface Guidelines準拠とSwiftUIベストプラクティス採用

## まとめ

この設計により、Windows版CompactMeterの機能を保持しつつ、macOSネイティブな体験を提供できる高品質なアプリケーションを構築できます。SwiftUI + Combineの組み合わせにより、モダンで保守性の高いコードベースを実現します。