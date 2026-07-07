# 新規 macOS アプリ（Cask）追加

novr org 配下の macOS アプリ repo から署名・公証済み ZIP を GitHub Release に出し、[homebrew-taps](https://github.com/novr/homebrew-taps) の Cask を `update-cask` dispatch で更新する手順。

## 前提

- repo に `NOVRD_BOT_CLIENT_ID` / `NOVRD_BOT_KEY`（GitHub App、homebrew-taps への dispatch 権限）
- org の Settings → Actions → General で、呼び出し元 repo から `novr/homebrew-taps` の reusable workflow へアクセス可能
- macOS リリースは `.app` を含む ZIP（例: `Nyap-macOS.zip`）

## 手順

1. release workflow に配布ビルド・公証・release asset アップロードを用意する
2. `release-macos` job outputs に `sha256` を載せる
3. 別 job `dispatch-cask` で reusable workflow を呼ぶ
4. `v*` tag を push する
5. `brew tap novr/taps && brew install --cask <cask>` で確認する

初回リリースでは `Casks/<cask>.rb` が未作成のため、`update-cask` dispatch が upsert で Cask を追加する。

## Reusable workflow

```yaml
dispatch-cask:
  needs: [prepare, release-macos]
  uses: novr/homebrew-taps/.github/workflows/dispatch-cask.yml@<sha-or-tag>
  with:
    cask: nyap
    version: ${{ needs.prepare.outputs.version }}
    sha256: ${{ needs.release-macos.outputs.sha256 }}
    desc: "Pomodoro timer with a cat overlay on breaks"
    app: Nyap.app
    asset: Nyap-macOS.zip
    name: Nyap
  secrets:
    NOVRD_BOT_CLIENT_ID: ${{ secrets.NOVRD_BOT_CLIENT_ID }}
    NOVRD_BOT_KEY: ${{ secrets.NOVRD_BOT_KEY }}
```

`source_repo` と `homepage` は reusable 側で呼び出し元 repo から自動導出する。本番では `source_repo` を渡さない。

ピン留めは commit SHA または tag を推奨する（`@main` は開発時のみ）。

## Inputs

| Input | 意味 |
|---|---|
| `cask` | tap 上の Cask 名（`Casks/<cask>.rb`） |
| `version` | セマンティックバージョン（`v` なし） |
| `sha256` | release asset の SHA-256 |
| `desc` | `brew info --cask` に出る一行説明（初回 upsert 時も必須） |
| `app` | ZIP 内の `.app` 名 |
| `asset` | release asset のファイル名 |
| `name` | Cask の表示名（省略時は cask 名から生成） |
| `minimum_macos` | 省略時 `sonoma` |

## アセット命名

```
<AppName>-macOS.zip
```

リリース間で asset 名は固定する。Cask の `url` は初回作成時に埋め込まれ、以降の `update-cask` は `version` と `sha256` のみ更新する。

## 参照

- [Nyap](https://github.com/novr/Nyap) — 初回 Cask 追加予定の macOS アプリ repo
- CLI Formula 向け手順: [new-tool.md](new-tool.md)

## 緊急再実行（reusable 非経由）

App token 取得後、payload を直接送る。

```bash
gh api repos/novr/homebrew-taps/dispatches --method POST --input - <<EOF
{
  "event_type": "update-cask",
  "client_payload": {
    "cask": "myapp",
    "version": "1.0.0",
    "sha256": "<sha256>",
    "desc": "One-line description",
    "homepage": "https://github.com/novr/myapp",
    "source_repo": "novr/myapp",
    "app": "MyApp.app",
    "asset": "MyApp-macOS.zip",
    "minimum_macos": "sonoma"
  }
}
EOF
```
