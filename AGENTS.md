# AGENTS.md

novr org 配下ツール向け Homebrew tap の汎用基盤。エージェントが変更する前に、制約・責務・境界を把握すること。

## 責務

### この repo（homebrew-taps）

| 領域 | 内容 |
|------|------|
| 配布定義 | `Formula/`・`Casks/` の Ruby 定義を保持・更新 |
| Producer | `dispatch-formula.yml` / `dispatch-cask.yml` — 呼び出し元 repo から `workflow_call`。App token 取得後 `repository_dispatch` を送る |
| Consumer | `formula-dispatch.yml` / `cask-dispatch.yml` — dispatch を受け、検証・生成・commit・push |
| 生成ロジック | `.github/scripts/formula_dispatch.rb` / `cask_dispatch.rb` |
| テスト | `*_test.rb` / `dispatch_*_payload_test.sh` |

### 呼び出し元 repo（bitrise-cli, Rin, Nyap 等）

| 領域 | 内容 |
|------|------|
| ビルド | universal binary（Formula）または署名・公証済み ZIP（Cask） |
| Release | GitHub Release への asset アップロード、`url` / `sha256` の算出 |
| Dispatch | release job とは別 job で reusable workflow を **commit SHA ピン**で呼ぶ |
| 認証 | `NOVRD_BOT_CLIENT_ID` / `NOVRD_BOT_KEY` |

この repo はビルド・署名・公証・リリース作成を行わない。

## 境界

```
[ツール repo]                    [homebrew-taps]
  release job
    └─ dispatch-formula/cask.yml ──repository_dispatch──► formula/cask-dispatch.yml
         (producer)                                        └─ *_dispatch.rb
                                                              └─ Formula/*.rb / Casks/*.rb
```

| 境界 | この側 | 向こう側 |
|------|--------|----------|
| Formula / Cask | 定義ファイルの生成・更新 | アセットの中身・CLI 契約 |
| `homepage` | Formula / Cask とも `source_repo` から導出（payload 非送信） | `source_repo` の正確性 |
| `brew services` | 初回 add 時のみテンプレ生成 | 起動コマンド・設定ファイルの tarball 同梱 |
| 信頼 | `novr/*` の release URL のみ受理 | org 外 repo からの dispatch 不可 |
| 更新範囲 | **update**: Formula は version + url/sha256、Cask は version + sha256 のみ | `install` / `service` / cask 定義の手修正は tap 側で維持 |

### Producer / Consumer

| 種別 | Producer | Consumer | 生成 |
|------|----------|----------|------|
| CLI | `dispatch-formula.yml` | `formula-dispatch.yml` | `formula_dispatch.rb` |
| macOS アプリ | `dispatch-cask.yml` | `cask-dispatch.yml` | `cask_dispatch.rb` |

Formula と Cask の workflow・スクリプト・payload は共有しない。

### Upsert

- reusable workflow は `event_type: update-formula` / `update-cask` を送る（本番の既定）
- consumer は `add-formula` / `add-cask` も受け付ける（手動 dispatch 用）
- 定義ファイルが無い状態で `desc` + `homepage`（Formula は導出可）が揃っていれば、**update 経由でも初回作成**する

## 制約

### GitHub API（`client_payload` トップレベル最大 10）

**共通コア（6 key）** — Formula / Cask で同一:

| Key | 備考 |
|-----|------|
| `name` | tap 上の名前（旧 `formula` / `cask`） |
| `version` | セマンティックバージョン |
| `sha256` | release asset の SHA-256 |
| `desc` | 一行説明 |
| `source_repo` | `novr/<repo>` |
| `options` | 種別固有フィールド（下表） |

`homepage` は送らない（consumer が `source_repo` から導出）。

**Formula の `options`**: `binary`, `test_match`, `license`, `service_*`（任意）

release URL は送らない（既定は命名規則で導出）。非標準 asset 名だけ reusable の `url` input → `options.url` へ載せる。

**Cask の `options`**: `app`, `asset` 必須。`name`（表示名）, `minimum_macos` は任意

download URL は payload に載せず、consumer テンプレが `source_repo` + `options.asset` から組み立てる。

JSON は **`jq`** で構築する。consumer は `resolve_*_payload.sh` で正規化する。

### 検証の二重化

1. **workflow（bash）** — `formula-dispatch.yml` / `cask-dispatch.yml` の Validate ステップ
2. **Ruby** — `*_dispatch.rb`

変更時は両方を揃える。Formula の brew service 検証は **add 時または service フィールド非空時**（workflow）／**add 時のみ**（Ruby `validate_metadata!`）。**update 時の Ruby は core metadata のみ**。

### 信頼境界

- `source_repo` は `novr/<name>` のみ
- release asset URL は `https://github.com/novr/<repo>/releases/` 配下のみ（Formula）
- `homepage` は `https://github.com/<source_repo>` と一致
- 名前・パスは正規表現で検証（path traversal 防止）

### Formula 生成

- macOS universal binary 前提（`<binary>_<version>_darwin.tar.gz`）
- **add**: `desc` 必須。brew service は任意（`service_run_args` がトリガー）
- **update**: `install` / `service` は変更しない
- `service_run_args` はカンマ区切り（引数にカンマ不可）
- `service_config_source` 指定時は `service_config` 必須

### 後方互換

- `name` を優先し、旧 `formula` / `cask` も読む
- `options.*` を優先し、旧 flat key / 旧 `service.*` / `install.*` も読む
- Formula の `url` は導出を優先し、旧 `url` / `options.url` で上書き可

### 運用

- reusable workflow は **`@<commit-sha>`** でピン（`@main` は開発時のみ）
- consumer workflow は `concurrency` で直列化

## 変更時のチェックリスト

1. `bash .github/scripts/dispatch_formula_payload_test.sh`（Formula payload 変更時）
2. `bash .github/scripts/dispatch_cask_payload_test.sh`（Cask payload 変更時）
3. `ruby .github/scripts/formula_dispatch_test.rb` / `cask_dispatch_test.rb`
4. producer の `jq` 出力と consumer の `resolve_*_payload.sh` / `client_payload.*` 参照が一致しているか
5. `docs/new-tool.md` / `docs/new-cask.md` / 本ファイルを更新したか

## 参照

- [docs/new-tool.md](docs/new-tool.md) — Formula 追加手順
- [docs/new-cask.md](docs/new-cask.md) — Cask 追加手順
