#!/bin/bash
# NOTE: set -e は意図的に使用しない。フックスクリプトはjqパース失敗等で
# 異常終了せず、安全に exit 0 する必要があるため。
set -uo pipefail

# --- キーワード定義（変更・追加が容易なよう冒頭にまとめる） ---
# 対象言及語: エージェントやプロンプト関連の言及
TARGET_PATTERN='(agent|エージェント|プロンプト|prompt|指示|ルール|規約|agents/|CLAUDE\.md)'
# フィードバック語: 修正・改善の要求
FEEDBACK_PATTERN='(修正|改善|変えて|直して|追加して|変更して|削除して|更新|update|fix|improve|change|remove|add)'

# stdin から Stop フックの入力 JSON を読み取る
input="$(cat)" || exit 0

# stop_hook_active チェック（無限ループ防止）
stop_hook_active="$(echo "$input" | jq -r '.stop_hook_active // "false"' 2>/dev/null)" || exit 0
if [[ "$stop_hook_active" == "true" ]]; then
  exit 0
fi

# transcript から最後のユーザー発言を取得
last_user_message="$(echo "$input" | jq -r '
  [.transcript[]? | select(.role == "user")] | last | .content // ""
' 2>/dev/null)" || exit 0

if [[ -z "$last_user_message" ]]; then
  exit 0
fi

# 複合条件マッチング: 対象語 AND フィードバック語
has_target=false
has_feedback=false

if echo "$last_user_message" | grep -qiE "$TARGET_PATTERN"; then
  has_target=true
fi

if echo "$last_user_message" | grep -qiE "$FEEDBACK_PATTERN"; then
  has_feedback=true
fi

if [[ "$has_target" == "true" && "$has_feedback" == "true" ]]; then
  cat >&2 <<'HOOK_MSG'
ユーザーからエージェント定義へのフィードバックが検知されました。

以下の手順で .claude/agents/*.md を確認・更新してください:
1. 直前のユーザー発言を確認し、フィードバックの内容を把握する
2. 関連する .claude/agents/*.md ファイルを特定して読み込む
3. フィードバック内容を反映するよう Edit で更新する
4. 変更内容をユーザーに報告する

注意:
- CLAUDE.md は変更しないでください（agents/*.md のみが対象です）
- フィードバックの意図が不明確な場合はユーザーに確認してください
HOOK_MSG
  exit 2
fi

exit 0
