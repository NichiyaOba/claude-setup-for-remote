# Claude Setup for Remote — マルチエージェントエンジニアリング基盤

## プロジェクト概要

このリポジトリはClaude Codeリモート実行環境向けのセットアップスクリプト集であり、マルチエージェントによるエンジニアリングワークフロー基盤を提供します。

## マルチエージェントワークフロー

`/dev` コマンドで以下のワークフローが自動実行されます：

```
Phase 1: 設計ループ
  designer → design-reviewer → (NEEDS_REVISION → designer → ...) → APPROVED

Phase 2: 実装ループ
  implementer → implementation-reviewer → (NEEDS_REVISION → implementer → ...) → APPROVED
```

### エージェント一覧

| エージェント | 役割 | 定義ファイル |
|---|---|---|
| designer | 設計書の作成 | `.claude/agents/designer.md` |
| design-reviewer | 設計書のレビュー | `.claude/agents/design-reviewer.md` |
| implementer | コードの実装 | `.claude/agents/implementer.md` |
| implementation-reviewer | コードのレビュー | `.claude/agents/implementation-reviewer.md` |

### 使い方

```
/dev <タスクの説明>
```

例: `/dev ユーザー認証機能を追加する`

## リポジトリ構成

```
├── main.sh                    # セットアップエントリーポイント
├── packages/                  # インストールパッケージ群
│   └── pinact/               # GitHub Actions pinning tool
├── CLAUDE.md                  # このファイル（プロジェクトコンテキスト）
└── .claude/
    ├── settings.json          # 権限設定
    ├── agents/                # エージェント定義
    │   ├── designer.md
    │   ├── design-reviewer.md
    │   ├── implementer.md
    │   └── implementation-reviewer.md
    └── commands/
        └── dev.md             # /dev オーケストレーターコマンド
```

## 開発規約

- コミュニケーションは日本語で行う
- コミットメッセージは英語（Conventional Commits形式）
- コードコメントは英語
- 設計書・レビュー結果は日本語
