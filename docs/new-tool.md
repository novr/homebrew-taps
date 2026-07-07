# 新規 tap ツール追加

novr org 配下の CLI repo から universal macOS リリースを出し、[homebrew-taps](https://github.com/novr/homebrew-taps) の Formula を `update-formula` dispatch で更新する手順。

## 前提

- repo に `NOVRD_BOT_APP_ID` / `NOVRD_BOT_KEY`（GitHub App、homebrew-taps への dispatch 権限）
- org の Settings → Actions → General で、呼び出し元 repo から `novr/homebrew-taps` の reusable workflow へアクセス可能
- macOS リリースは arm64 + x86_64 の universal binary（単一 `darwin.tar.gz`）

## 手順

1. release workflow に universal ビルドと release asset アップロードを用意する
2. `release-macos`（等）の job outputs に `url` と `sha256` を載せる
3. 別 job `dispatch-formula` で reusable workflow を呼ぶ（build job と分離する）
4. `v*` tag を push する
5. `brew tap novr/taps && brew install <formula>` で確認する

## Reusable workflow

```yaml
dispatch-formula:
  needs: [prepare, release-macos]
  uses: novr/homebrew-taps/.github/workflows/dispatch-formula.yml@<sha-or-tag>
  with:
    formula: mytool
    version: ${{ needs.prepare.outputs.version }}
    url: ${{ needs.release-macos.outputs.url }}
    sha256: ${{ needs.release-macos.outputs.sha256 }}
    desc: "One-line description"
    binary: mytool
    test_match: "expected --help substring"
  secrets:
    NOVRD_BOT_APP_ID: ${{ secrets.NOVRD_BOT_APP_ID }}
    NOVRD_BOT_KEY: ${{ secrets.NOVRD_BOT_KEY }}
```

`source_repo` と `homepage` は reusable 側で呼び出し元 repo から自動導出する。本番では渡さない。

ピン留めは commit SHA または tag を推奨する（`@main` は開発時のみ）。

## Inputs

| Input | 意味 |
|---|---|
| `formula` | tap 上の Formula 名（`Formula/<formula>.rb`） |
| `version` | セマンティックバージョン（`v` なし） |
| `url` | release asset の URL |
| `sha256` | asset の SHA-256 |
| `desc` | `brew info` に出る一行説明（初回 upsert 時も必須） |
| `binary` | tarball 内の実行ファイル名 |
| `test_match` | `brew test` で `--help` 出力に含める文字列 |

`formula` と `binary` が異なる例: [rinter](https://github.com/novr/homebrew-taps/blob/main/Formula/rinter.rb)（repo は Rin、binary は `rinter`）。

## アセット命名

```
<binary>_<version>_darwin.tar.gz
```

例: `br_0.0.3_darwin.tar.gz` → URL は `https://github.com/<owner>/<repo>/releases/download/v0.0.3/br_0.0.3_darwin.tar.gz`

## 既存例

- [br](https://github.com/novr/homebrew-taps/blob/main/Formula/br.rb) — [bitrise-cli release](https://github.com/novr/bitrise-cli/blob/main/.github/workflows/release.yml)
- [rinter](https://github.com/novr/homebrew-taps/blob/main/Formula/rinter.rb) — [Rin release](https://github.com/novr/Rin/blob/main/.github/workflows/release.yml)

## 緊急再実行（reusable 非経由）

App token 取得後、payload を直接送る。

```bash
gh api repos/novr/homebrew-taps/dispatches --method POST --input - <<EOF
{
  "event_type": "update-formula",
  "client_payload": {
    "formula": "mytool",
    "version": "1.0.0",
    "url": "https://github.com/novr/mytool/releases/download/v1.0.0/mytool_1.0.0_darwin.tar.gz",
    "sha256": "<sha256>",
    "desc": "One-line description",
    "homepage": "https://github.com/novr/mytool",
    "source_repo": "novr/mytool",
    "binary": "mytool",
    "test_match": "expected substring"
  }
}
EOF
```
