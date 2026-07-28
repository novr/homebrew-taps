# 新規 tap ツール追加

novr org 配下の CLI repo から universal macOS リリースを出し、[homebrew-taps](https://github.com/novr/homebrew-taps) の Formula を `update-formula` dispatch で更新する手順。

## 前提

- repo に `NOVRD_BOT_CLIENT_ID` / `NOVRD_BOT_KEY`（GitHub App、homebrew-taps への dispatch 権限）
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
    sha256: ${{ needs.release-macos.outputs.sha256 }}
  secrets:
    NOVRD_BOT_CLIENT_ID: ${{ secrets.NOVRD_BOT_CLIENT_ID }}
    NOVRD_BOT_KEY: ${{ secrets.NOVRD_BOT_KEY }}
```

`source_repo` と `homepage` は reusable 側で呼び出し元 repo から自動導出する。本番では渡さない。

ピン留めは commit SHA または tag を推奨する（`@main` は開発時のみ）。

## Inputs

| Input | 意味 |
|---|---|
| `formula` | tap 上の Formula 名（`Formula/<formula>.rb`） |
| `version` | セマンティックバージョン（`v` なし） |
| `url` | 非標準 asset 名のときのみ（省略時は `<binary>_<version>_darwin.tar.gz` を導出） |
| `sha256` | asset の SHA-256 |
| `desc` | 一行説明（初回 upsert / `add-formula` 時のみ。通常の version 更新では省略可） |
| `binary` | tarball 内の実行ファイル名（`formula` と同じなら省略可） |
| `test_match` | `brew test` 用文字列（初回 upsert / `add-formula` 時のみ。通常の version 更新では省略可） |

`formula` と `binary` が異なる例: [rinter](https://github.com/novr/homebrew-taps/blob/main/Formula/rinter.rb)（repo は Rin、binary は `rinter`）。

## brew services（省略可）

常駐プロセス向けの Formula だけ、次の input を追加する。いずれも独立しており、ツールの CLI 契約に合わせて組み合わせる。

| Input | 意味 |
|---|---|
| `service_run_args` | `service` ブロックの `run` 引数（カンマ区切り）。指定時のみ `brew services` ブロックを生成 |
| `service_config` | `etc/` 配下の設定ファイルパス。`service_run_args` と併用時は `run` 配列末尾に `etc/"..."` を付与 |
| `service_config_source` | tarball 内の設定テンプレパス。`service_config` と併用し、初回インストール時に `etc/` へコピー（既存ファイルは上書きしない） |

初回作成時のみ `service` / 設定関連の `install` を生成する。update では既存ブロックを維持し、service 関連 input は検証・適用されない。

`dispatch-formula` reusable workflow の input 名はそのまま。`client_payload` へ送る際に `options` オブジェクトへネストされる（手動 dispatch 時も同構造にする）。

`service_run_args` はカンマ区切り（引数にカンマを含められない）。

### 例: 設定ファイルなしの常駐プロセス

```yaml
service_run_args: start
```

生成される `run`:

```ruby
run [opt_bin/"mytool", "start"]
```

### 例: 設定ファイル付きの常駐プロセス

```yaml
service_run_args: run,--config
service_config: mytool/config.yaml
service_config_source: config.yaml.example
```

生成される `install` / `service`:

```ruby
def install
  bin.install "mytool"
  etc.install "config.yaml.example" => "mytool/config.yaml" unless (etc/"mytool/config.yaml").exist?
end

service do
  run [opt_bin/"mytool", "run", "--config", etc/"mytool/config.yaml"]
  keep_alive true
  ...
end
```

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

`client_payload` のトップレベルは GitHub API 制限で最大 10 個。コアは `name`, `version`, `sha256`, `source_repo`, `options`（+ 初回のみ `desc`）。`homepage` と release `url` は送らない。

```bash
gh api repos/novr/homebrew-taps/dispatches --method POST --input - <<EOF
{
  "event_type": "update-formula",
  "client_payload": {
    "name": "mytool",
    "version": "1.0.0",
    "sha256": "<sha256>",
    "desc": "One-line description",
    "source_repo": "novr/mytool",
    "options": {
      "binary": "mytool",
      "test_match": "expected substring",
      "license": "MIT",
      "service_run_args": "run,--config",
      "service_config": "mytool/config.yaml",
      "service_config_source": "config.yaml.example"
    }
  }
}
EOF
```
