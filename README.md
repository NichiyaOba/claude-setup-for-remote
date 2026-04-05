# claude-setup-for-remote

ClaudeのリモートWeb/App実行環境向けセットアップスクリプト集。
`main.sh` を実行するだけで必要なツールが一括インストールされる。

## 使い方

### Claude Code 上でのセットアップ（ワンライナー）

Claude のリモート実行環境（Web / App）のプロンプトに貼り付けて実行する:

```bash
WORKDIR="$(mktemp -d /tmp/claude-setup-for-remote.XXXXXX)" && git clone https://github.com/NichiyaOba/claude-setup-for-remote.git "${WORKDIR}" && bash "${WORKDIR}/main.sh"
```

リポジトリを一時ディレクトリに clone し、`main.sh` を実行する。

### 通常の実行

```bash
git clone https://github.com/NichiyaOba/claude-setup-for-remote.git
bash claude-setup-for-remote/main.sh
```

## インストールされるツール

| ツール | バージョン | 説明 |
|--------|-----------|------|
| [pinact](https://github.com/suzuki-shunsuke/pinact) | v3.9.0 | GitHub ActionsのバージョンをSHAにピン留めするツール |
| [jq](https://github.com/jqlang/jq) | jq-1.8.1 | 軽量で柔軟なコマンドラインJSONプロセッサ |
| [gh](https://github.com/cli/cli) | v2.89.0 | GitHub公式CLI（PR・Issue・Actions操作） |
| [shellcheck](https://github.com/koalaman/shellcheck) | v0.11.0 | シェルスクリプト静的解析ツール |
| [actionlint](https://github.com/rhysd/actionlint) | v1.7.12 | GitHub Actionsワークフロー静的解析ツール |

## ツールの追加方法

`packages/<ツール名>/` ディレクトリを作成し、以下の2ファイルを置く。

```
packages/
└── <ツール名>/
    ├── install.sh   # インストールスクリプト（必須）
    └── README.md    # ツールの説明（推奨）
```

`main.sh` は `packages/*/install.sh` を自動検出して実行するため、追加作業はファイルを置くだけでよい。

## マルチエージェントエンジニアリングフレームワーク

本リポジトリには、Claude Code上でマルチエージェントによる開発ワークフローを実行する基盤が含まれている。

### クイックスタート

Claude Code のプロンプトで `/dev` コマンドにタスクの説明を渡すだけで、設計から実装までが自動実行される。

```
/dev ユーザー認証機能を追加する
```

#### 実行例

```
/dev packages/shellcheck/ に shellcheck のインストールスクリプトを追加する
```

```
/dev main.sh にドライランモード（--dry-run オプション）を実装する
```

### ワークフロー詳細

`/dev` コマンドは以下の2フェーズを順番に実行する。各フェーズはレビューで承認されるまで最大3回ループする。

```
Phase 1: 設計ループ
  ┌─────────────────────────────────────────────────┐
  │  designer (設計書作成)                            │
  │       ↓                                          │
  │  design-reviewer (レビュー)                       │
  │       ↓                                          │
  │  APPROVED → Phase 2 へ                           │
  │  NEEDS_REVISION → designer に戻る (最大3回)       │
  └─────────────────────────────────────────────────┘

Phase 2: 実装ループ
  ┌─────────────────────────────────────────────────┐
  │  implementer (コード実装)                         │
  │       ↓                                          │
  │  implementation-reviewer (レビュー)               │
  │       ↓                                          │
  │  APPROVED → 完了                                 │
  │  NEEDS_REVISION → implementer に戻る (最大3回)    │
  └─────────────────────────────────────────────────┘
```

3回のループで承認されない場合は、ユーザーに判断を委ねる（「このまま進む」/「手動で修正」/「中止」）。

### エージェント構成

| エージェント | 役割 | 定義ファイル |
|---|---|---|
| designer | 要件分析・アーキテクチャ設計・設計書の作成 | `.claude/agents/designer.md` |
| design-reviewer | 設計書のレビュー・承認/修正判定 | `.claude/agents/design-reviewer.md` |
| implementer | 設計書に基づくコード実装・テスト作成 | `.claude/agents/implementer.md` |
| implementation-reviewer | コードの品質・設計準拠性のレビュー・承認/修正判定 | `.claude/agents/implementation-reviewer.md` |

### エージェントのカスタマイズ

各エージェントの振る舞いは `.claude/agents/` 配下の Markdown ファイルで定義されている。
ファイルを編集することで、レビュー観点・出力フォーマット・判定基準などを自由にカスタマイズできる。

#### カスタマイズ例

- **レビュー観点の追加**: `design-reviewer.md` の「レビュー観点」セクションに新しい項目を追加
- **出力フォーマットの変更**: 各エージェントの「出力フォーマット」セクションを編集
- **判定基準の調整**: `*-reviewer.md` の「判定基準」セクションで APPROVED/NEEDS_REVISION の閾値を変更
- **ループ上限の変更**: `.claude/commands/dev.md` 内のループ上限値を変更
