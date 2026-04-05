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

### ワークフロー

`/dev <タスクの説明>` コマンドで以下のフローが自動実行される：

```
Phase 1: 設計ループ
  designer → design-reviewer → (修正が必要なら designer に戻る) → 承認

Phase 2: 実装ループ
  implementer → implementation-reviewer → (修正が必要なら implementer に戻る) → 承認
```

各フェーズは最大3回のレビューループを実行し、それでも承認されない場合はユーザーに判断を委ねる。

### エージェント構成

| エージェント | 役割 | 定義ファイル |
|---|---|---|
| designer | アーキテクチャ設計・設計書の作成 | `.claude/agents/designer.md` |
| design-reviewer | 設計書のレビュー・承認/修正判定 | `.claude/agents/design-reviewer.md` |
| implementer | 設計書に基づくコード実装 | `.claude/agents/implementer.md` |
| implementation-reviewer | 実装コードのレビュー・承認/修正判定 | `.claude/agents/implementation-reviewer.md` |

### エージェントのカスタマイズ

各エージェントの振る舞いは `.claude/agents/` 配下の Markdown ファイルで定義されている。
ファイルを編集することで、レビュー観点・出力フォーマット・判定基準などを自由にカスタマイズできる。
