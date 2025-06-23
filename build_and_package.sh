#!/bin/bash

# CompactMeter-macOS ビルド&パッケージ作成スクリプト
# 使用方法: ./build_and_package.sh

set -e  # エラー時に停止

# 色付きメッセージ用の定数
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ出力関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# プロジェクト設定
PROJECT_NAME="CompactMeter-macOS"
PROJECT_FILE="${PROJECT_NAME}.xcodeproj"
SCHEME_NAME="${PROJECT_NAME}"
CONFIGURATION="Release"
BUILD_DIR="./build"
APP_NAME="${PROJECT_NAME}.app"

# 日付フォーマット (YYYYMMDD)
DATE_STR=$(date +"%Y%m%d")
ZIP_NAME="${PROJECT_NAME}-${DATE_STR}.zip"
OUTPUT_DIR="./release"

log_info "=== CompactMeter-macOS ビルド&パッケージ作成開始 ==="
log_info "日付: $(date)"
log_info "ZIPファイル名: ${ZIP_NAME}"

# プロジェクトファイルの存在確認
if [ ! -f "${PROJECT_FILE}/project.pbxproj" ]; then
    log_error "プロジェクトファイルが見つかりません: ${PROJECT_FILE}"
    exit 1
fi

# 1. 既存のビルドディレクトリをクリーンアップ
log_info "既存のビルドディレクトリをクリーンアップ中..."
if [ -d "${BUILD_DIR}" ]; then
    rm -rf "${BUILD_DIR}"
fi

# 2. リリースディレクトリを作成
log_info "リリースディレクトリを準備中..."
mkdir -p "${OUTPUT_DIR}"

# 3. プロジェクトをクリーンビルド
log_info "プロジェクトをクリーンビルド中..."
xcodebuild \
    -project "${PROJECT_FILE}" \
    -scheme "${SCHEME_NAME}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath "${BUILD_DIR}" \
    clean build

if [ $? -ne 0 ]; then
    log_error "ビルドに失敗しました"
    exit 1
fi

log_success "ビルド完了"

# 4. .appファイルの存在確認
APP_PATH="${BUILD_DIR}/Build/Products/${CONFIGURATION}/${APP_NAME}"
if [ ! -d "${APP_PATH}" ]; then
    log_error ".appファイルが見つかりません: ${APP_PATH}"
    exit 1
fi

log_info ".appファイルを確認: ${APP_PATH}"

# 5. コード署名の確認
log_info "コード署名を確認中..."
codesign -dv --verbose=4 "${APP_PATH}" 2>&1 | head -5
if [ $? -ne 0 ]; then
    log_warning "コード署名の確認に失敗しましたが、続行します"
fi

# 6. .appファイルをリリースディレクトリにコピー
log_info ".appファイルをリリースディレクトリにコピー中..."
RELEASE_APP_PATH="${OUTPUT_DIR}/${APP_NAME}"
if [ -d "${RELEASE_APP_PATH}" ]; then
    rm -rf "${RELEASE_APP_PATH}"
fi
cp -R "${APP_PATH}" "${OUTPUT_DIR}/"

# 7. ZIPパッケージを作成
log_info "ZIPパッケージを作成中..."
cd "${OUTPUT_DIR}"
ZIP_PATH="${ZIP_NAME}"

# 既存のZIPファイルがあれば削除
if [ -f "${ZIP_PATH}" ]; then
    rm "${ZIP_PATH}"
fi

# ZIPを作成（macOSの隠しファイルを除外）
zip -r "${ZIP_PATH}" "${APP_NAME}" -x "*.DS_Store" "__MACOSX/*"

if [ $? -ne 0 ]; then
    log_error "ZIPパッケージの作成に失敗しました"
    cd ..
    exit 1
fi

cd ..

# 8. 結果の確認とサマリー
ZIP_FULL_PATH="${OUTPUT_DIR}/${ZIP_PATH}"
APP_SIZE=$(du -h "${RELEASE_APP_PATH}" | cut -f1)
ZIP_SIZE=$(du -h "${ZIP_FULL_PATH}" | cut -f1)

log_success "=== パッケージ作成完了 ==="
echo ""
log_info "📦 パッケージ情報:"
echo "  • .appファイル: ${RELEASE_APP_PATH} (${APP_SIZE})"
echo "  • ZIPファイル: ${ZIP_FULL_PATH} (${ZIP_SIZE})"
echo ""
log_info "🚀 使用方法:"
echo "  • 実行: open \"${RELEASE_APP_PATH}\""
echo "  • 配布: ${ZIP_FULL_PATH} を共有"
echo ""

# 9. 自動実行オプション
read -p "ビルドしたアプリを今すぐ実行しますか？ (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "アプリを起動中..."
    open "${RELEASE_APP_PATH}"
fi

log_success "スクリプト実行完了 🎉"