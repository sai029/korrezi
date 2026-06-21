---
description: Launch flutter_application_1 on Chrome (web) or a connected Android device. Covers the full flow from pre-flight checks through live hot-reload.
---

# Run Skill — flutter_application_1

## 対象プラットフォーム
- **Web (Chrome)** — `flutter run -d chrome`
- **Web (headless server)** — `flutter run -d web-server --web-port 5050`
- **Android 実機** — USB 接続した物理デバイス

---

## 事前チェック（共通）

```bash
flutter doctor
```

既知の警告:
- `Android toolchain: Some Android licenses not accepted` → 初回のみ `flutter doctor --android-licenses` で承認
- Chrome/Edge は通常 `[√]` のはず

接続デバイス一覧:
```bash
flutter devices
```

---

## Web (Chrome) で起動

```bash
flutter run -d chrome
```

- Chrome が自動で開き、`http://localhost:<port>` に接続される。
- ターミナルで `r` → Hot reload、`R` → Hot restart。
- 終了は `q`。

### ポートを固定したい場合

```bash
flutter run -d chrome --web-port 8080
```

### ブラウザを開かずサーバーだけ立てる（スクリーンショット確認など）

```bash
flutter run -d web-server --web-port 5050
```

起動後 `http://localhost:5050` をブラウザで手動アクセス。
ポート競合エラーが出たら別ポートに変更すること。

---

## Android 実機で起動

### 1. デバイス準備

1. Android デバイスで **設定 → 開発者オプション → USB デバッグ** を有効にする。
2. USB ケーブルで PC と接続。
3. デバイス側に「USB デバッグを許可しますか？」が出たら **許可** をタップ。

### 2. 認識確認

```bash
flutter devices
```

デバイス名と ID が表示されれば OK。例:
```
Pixel 8 Pro (mobile) • XXXXXXXX • android-arm64 • Android 14
```

表示されない場合のトラブルシュート:
- `adb devices` で認識されているか確認
- ドライバ未インストールの場合は Android SDK の Google USB Driver を適用
- ライセンス未承認なら `flutter doctor --android-licenses`

### 3. 起動

デバイスが1台だけなら:
```bash
flutter run
```

複数台 or 明示指定:
```bash
flutter run -d <device-id>
```

### 4. ログとデバッグ

```bash
# クラッシュログを tail
adb logcat -s flutter

# ビルドログを詳細表示
flutter run -d <device-id> -v
```

---

## リリースビルド（動作確認用）

### Web
```bash
flutter build web
# 成果物: build/web/  → 静的ホスティングで配信
```

### Android APK（サイドロード）
```bash
flutter build apk --release
# 成果物: build/app/outputs/flutter-apk/app-release.apk
# そのままデバイスにインストール:
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## よくある問題

| 症状 | 原因 | 対処 |
|---|---|---|
| ポート競合 `errno=10048` | 前回の flutter run が残存 | 別ポート指定 or タスクマネージャで dart プロセスを終了 |
| `No connected devices` | USB デバッグ未許可 | デバイス画面で「許可」をタップ |
| Android licenses エラー | ライセンス未承認 | `flutter doctor --android-licenses` で y を連打 |
| Web でフォントが読み込まれない | Google Fonts CDN が必要 | ネット接続を確認、または `flutter pub get` を再実行 |
| `MissingPluginException` | プラグインのネイティブビルド未完了 | `flutter clean && flutter pub get && flutter run` |
