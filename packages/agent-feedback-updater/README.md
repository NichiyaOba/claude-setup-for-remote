# agent-feedback-updater

Claude Code の Stop フックでユーザーフィードバックを自動検知し、エージェント定義ファイル（`.claude/agents/*.md`）の更新を促すツール。

## 用途

- ユーザーのフィードバック発言を Stop フックで自動検知
- Claude Code に追加ターンを要求し、agents/*.md の自動更新をトリガー
- キーワードベースの複合条件（対象語 AND フィードバック語）で誤検知を抑制

## 前提条件

- jq（`packages/jq` で自動インストール）
- Claude Code の Stop フック機能

## 動作の仕組み

1. Claude Code のターン完了時に Stop フックが起動
2. トランスクリプトの最終ユーザー発言をキーワード解析
3. エージェント関連のフィードバックを検知した場合、exit 2 で追加ターンを要求
4. Claude Code が agents/*.md を自動更新

## リンク

- https://docs.anthropic.com/en/docs/claude-code/hooks
