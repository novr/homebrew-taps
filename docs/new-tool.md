# 新規 tap ツール追加

novr org 配下の CLI repo から universal macOS リリースを出し、[homebrew-taps](https://github.com/novr/homebrew-taps) の Formula を `update-formula` dispatch で更新する手順。

## 前提

- repo に `NOVRD_BOT_CLIENT_ID` / `NOVRD_BOT_KEY`（GitHub App、homebrew-taps への dispatch 権限）
- org の Settings → Actions → General で、呼び出し元 repo から `novr/homebrew-taps` の reusable workflow へアクセス可能
- macOS リリースは arm64 + x86_64 の universal binary（単一 `darwin.tar.gz`）

## 運用の流れ（推奨）

**初回だけ `gh api`、2回目以降は reusable workflow を最小 `with:` で回す。** release workflow に初回専用 job を足す必要はない。

| タイミング | 方法 | 渡すもの |
|---|---|---|
| 初回リリース（1回） | `gh api` で `repository_dispatch` | `desc`, `test_match`, `service_*`, `completion_*` など Formula 定義に必要なもの |
| 2回目以降 | reusable `dispatch-formula` | `formula`, `version`, `sha256` のみ |

`install` / `service` / 補完は初回作成時だけ tap 側に書き込まれる。update では version + url/sha256 だけ更新され、既存ブロックは維持される。

### 1. 初回リリース（手動・1回）

1. ツール repo で release workflow を用意し、`v*` tag を push して macOS asset を公開する
2. release asset の `sha256` を用意する（例: `shasum -a 256 mytool_1.0.0_darwin.tar.gz`）
3. App token を取得し、`gh api` で tap に dispatch する（下記テンプレ）
4. [homebrew-taps](https://github.com/novr/homebrew-taps) の Actions で `formula-dispatch` が成功し、`Formula/<formula>.rb` ができていることを確認する
5. `brew tap novr/taps && brew install <formula>` でインストール確認
6. ツール repo の release workflow に **最小の reusable 呼び出し**を追加する（下記）。以降のリリースは tag push だけで tap が更新される

App token 取得例（ローカル or CI で一度だけ）:

```bash
gh auth token   # 手元で PAT を使う場合
# または actions/create-github-app-token で NOVRD_BOT_* から取得
```

初回 dispatch テンプレ（`service_*` / `completion_*` は不要なら `options` から削除）:

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
      "test_match": "expected --help substring",
      "license": "MIT"
    }
  }
}
EOF
```

`client_payload` のトップレベルは最大 10 key。種別固有フィールドは `options` に入れる。`homepage` と release `url` は送らない（consumer が導出）。

Cobra 補完・brew services が必要なら、初回 `options` にだけ足す:

```json
"completion_shells": "bash,zsh,fish",
"completion_format": "cobra",
"service_run_args": "run,--config",
"service_config": "mytool/config.yaml",
"service_config_source": "config.yaml.example"
```

### 2. 2回目以降（release workflow・自動）

release workflow に reusable を **commit SHA ピン**で追加する（`@main` は開発時のみ）。

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

`source_repo` は reusable 側で呼び出し元 repo から自動導出する。`desc` / `test_match` / `binary` は渡さない（既存 Formula を version + sha256 だけ更新）。

### 3. 再実行・トラブル時

初回 dispatch のやり直しや reusable が失敗したときも、同じ `gh api` テンプレで再送できる。Formula が既にあれば version + sha256 の更新になる。

## Inputs（初回 `gh api` 用）

reusable の `with:` 名と同じキーを、初回 dispatch では `client_payload.options` に載せる（`desc` だけトップレベル）。

| Input | 意味 |
|---|---|
| `formula` | tap 上の Formula 名（`Formula/<formula>.rb`）。`client_payload` では `name` |
| `version` | セマンティックバージョン（`v` なし） |
| `url` | 非標準 asset 名のときのみ（省略時は `<binary>_<version>_darwin.tar.gz` を導出） |
| `sha256` | asset の SHA-256 |
| `desc` | 一行説明（**初回 `gh api` のみ必須**。reusable では渡さない） |
| `binary` | tarball 内の実行ファイル名（`formula` と同じなら省略可）。release asset 名・`test` コマンドの基準 |
| `binaries` | `install` する実行ファイル名（カンマ区切り）。省略時は `binary` のみ |
| `aliases` | `brew install` 用エイリアス（カンマ区切り）。`Aliases/<name>` を生成し、同一 Formula を指す |
| `test_match` | `brew test` 用文字列（**初回 `gh api` のみ必須**。reusable では渡さない） |

`formula` と `binary` が異なる例: [rinter](https://github.com/novr/homebrew-taps/blob/main/Formula/rinter.rb)（repo は Rin、binary は `rinter`）。

複数バイナリ・エイリアス例: [kusabi](https://github.com/novr/homebrew-taps/blob/main/Formula/kusabi.rb)（`kusabi` / `ksb` / `git-kusabi` を同梱、`brew install ksb` も可）。

## brew services（省略可）

常駐プロセス向けの Formula だけ、次の input を追加する。いずれも独立しており、ツールの CLI 契約に合わせて組み合わせる。

| Input | 意味 |
|---|---|
| `service_run_args` | `service` ブロックの `run` 引数（カンマ区切り）。指定時のみ `brew services` ブロックを生成 |
| `service_config` | `etc/` 配下の設定ファイルパス。`service_run_args` と併用時は `run` 配列末尾に `etc/"..."` を付与 |
| `service_config_source` | tarball 内の設定テンプレパス。`service_config` と併用し、初回インストール時に `etc/` へコピー（既存ファイルは上書きしない） |

### シェル補完（省略可）

CLI が補完スクリプトを出力できる場合、初回 `gh api` 時に `install` へ `generate_completions_from_executable` を生成する。update では既存 `install` を維持する。

| Input | 意味 |
|---|---|
| `completion_shells` | 生成対象シェル（カンマ区切り: `bash`, `zsh`, `fish`, `pwsh`）。他の `completion_*` を使うときは必須 |
| `completion_args` | 実行ファイルへ渡す追加引数（カンマ区切り。`completion_format: cobra` 等を使う CLI では通常不要） |
| `completion_format` | Homebrew の `shell_parameter_format`（`cobra`, `clap`, `click`, `arg`, `flag`, `typer`, `none`） |

### 例: Cobra 形式の補完

```yaml
completion_shells: bash,zsh,fish
completion_format: cobra
```

生成される `install`:

```ruby
def install
  bin.install "mytool"
  generate_completions_from_executable(bin/"mytool", shells: [:bash, :zsh, :fish], shell_parameter_format: :cobra)
end
```

初回 `gh api` の `options` にだけ指定する。reusable では渡さない。update では既存ブロックを維持する。

### 例: 複数バイナリとエイリアス

tarball に短縮名や `git-*` コマンドが同梱される場合:

```json
"binaries": "kusabi,ksb,git-kusabi",
"aliases": "ksb,git-kusabi"
```

生成される `install`:

```ruby
def install
  bin.install "kusabi", "ksb", "git-kusabi"
  generate_completions_from_executable(bin/"kusabi", shells: [:bash, :zsh, :fish], shell_parameter_format: :cobra)
end
```

`Aliases/ksb` と `Aliases/git-kusabi` も作成され、`brew install ksb` / `brew install git-kusabi` で同一 Formula が入る。補完は主バイナリ（`binary`）基準。

制約:

- `binaries` 指定時は主 `binary` を必ず含める
- `aliases` の各名前は `binaries` に含まれること（`brew install <alias>` 後に同名コマンドが PATH にあること）
- 既存 Formula 名や他 Formula 向けエイリアスとは衝突不可

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
- [rinter](https://github.com/novr/homebrew-taps/blob/main/Formula/rinter.rb) — [Rin release](https://github.com/novr/Rin/blob/main/.github/workflows/release.yml)（2回目以降は reusable 最小）
