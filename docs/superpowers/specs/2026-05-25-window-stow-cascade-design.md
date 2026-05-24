# WindowStow.spoon — Cascade Windows Design

**Date:** 2026-05-25  
**Scope:** Fork of masaki39/ryoiki — rename to WindowStow + Cascade Windows built-in action

---

## 1. Rename: Ryoiki → WindowStow

| Item | Before | After |
|------|--------|-------|
| Spoon directory | `Ryoiki.spoon/` | `WindowStow.spoon/` |
| `obj.name` | `"Ryoiki"` | `"WindowStow"` |
| All notify strings | `"Ryoiki"` | `"WindowStow"` |
| File comments | `Ryoiki.spoon` | `WindowStow.spoon` |
| `docs.json` name | `"Ryoiki"` | `"WindowStow"` |
| `version.sh` paths | `Ryoiki.spoon/…` | `WindowStow.spoon/…` |
| `Spoons/` zip | `Ryoiki.spoon.zip` | `WindowStow.spoon.zip` |
| Usage | `spoon.Ryoiki` | `spoon.WindowStow` |

author は `masaki39` のまま維持（fork元クレジット）。

---

## 2. New Built-in Action: Cascade Windows

### 概要

カーソル画面の可視ウィンドウ（Finder除外）を左上→右下へ斜めにずらしながら重ねて配置する。

### chooser への統合

```lua
{ name = "Cascade Windows", description = "Stagger visible windows diagonally on screen (excludes Finder)" }
```

`bindHotkeys` で `cascadeWindows` キーをサポート:

```lua
spoon.WindowStow:bindHotkeys({
    cascadeWindows = { {"ctrl", "alt"}, "c" },
})
```

---

## 3. Cascade アルゴリズム

### マージン

| 辺 | マージン |
|----|---------|
| 左 | 5% |
| 上 | 5% |
| 右 | 5% |
| 下 | 0%（マージンなし） |

### ずらし量 S

```
S = cascadeStagger or clamp(floor(screen.w × 0.02), 20, 60)
```

例: 2560px → 51px, 1920px → 38px, 1440px → 28px

`obj.cascadeStagger` に数値を設定することで上書き可能。

### ウィンドウサイズ・位置

```
winW = max(areaW × 0.4,  areaW − (N−1)×S)
winH = max(areaH × 0.4,  areaH − (N−1)×S)
window[i].frame = { x = x0 + (i−1)×S,  y = y0 + (i−1)×S,  w = winW,  h = winH }
```

最低サイズ (40%) の保証により、ウィンドウ数が多くても極端に小さくならない。

---

## 4. ウィンドウ選択 UI（トグル型 chooser）

### フロー

1. メイン chooser → "Cascade Windows" 選択
2. サブ chooser が開く（全ウィンドウが初期選択状態）
3. ウィンドウ行を選択 → 含める/除外 toggle → chooser 再表示
4. "Apply Cascade (N windows)" を選択 → カスケード実行
5. ESC で中断

### chooser 表示例

```
Apply Cascade (3 windows)          Arrange selected windows diagonally
✓ Safari — GitHub
✓ Terminal — zsh
○ Slack — #general
```

### 対象ウィンドウの収集条件

- `win:isStandard()` = true
- `win:screen()` = カーソル画面
- `win:application():bundleID()` ≠ `"com.apple.finder"`

---

## 5. 設定オプション

| 設定 | デフォルト | 説明 |
|------|-----------|------|
| `cascadeStagger` | `nil` | ずらし量 (px)。nil で自動計算 |
| `centerCursor` | `false` | 既存オプション（変更なし） |

---

## 6. ファイル変更一覧

| ファイル | 変更 |
|---------|------|
| `Ryoiki.spoon/` → `WindowStow.spoon/` | ディレクトリリネーム |
| `WindowStow.spoon/init.lua` | リネーム + Cascade 実装追加 |
| `WindowStow.spoon/parser.lua` | コメント・通知文字列更新 |
| `WindowStow.spoon/chooser.lua` | コメント更新 |
| `WindowStow.spoon/layout.lua` | コメント・通知文字列更新 |
| `WindowStow.spoon/hotkeys.lua` | コメント・通知文字列更新 |
| `WindowStow.spoon/docs.json` | API ドキュメント更新 + Cascade 追加 |
| `docs/docs.json` | name 更新 |
| `README.md` | 全面更新 |
| `version.sh` | パス更新 |
| `Spoons/Ryoiki.spoon.zip` → `Spoons/WindowStow.spoon.zip` | zip 再生成 |
