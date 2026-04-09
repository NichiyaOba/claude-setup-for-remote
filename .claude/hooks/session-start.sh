#!/bin/bash
set -euo pipefail

# SessionStart hook: MCP ツール初期化に関するコンテキストを注入する
#
# 問題:
#   MCP ツール（mcp__github__* 等）は "deferred" として登録され、
#   セッションの1ターン目では system-reminder にツール一覧が載らない。
#   ToolSearch も対象が存在しないため失敗する。
#   2ターン目以降のラウンドトリップで初めて deferred tools が利用可能になる。
#
# 対策:
#   このフックの stdout が Claude のコンテキストに注入されるため、
#   1ターン目での MCP ツール利用制限を Claude に認識させる。

cat <<'CONTEXT'
## MCP Tool Initialization Notice

MCP tools (e.g. mcp__github__*) are registered as "deferred" and may NOT be
available on the first turn of a session. The deferred tool list only appears
in system-reminder after the first round-trip (your first response -> user's
next message).

### Rules for the first turn:

1. **Do NOT attempt to use MCP tools** (mcp__github__*, etc.) on the first turn.
   They will not be found by ToolSearch and direct calls will fail.
2. **Use alternative tools** when possible:
   - For GitHub operations: use `gh` CLI via Bash tool instead of mcp__github__*
   - For web content: describe what you would fetch and offer to do it on the next turn
3. **If MCP tools are essential** for the user's request and no alternative exists:
   - Inform the user that MCP tools will be available after one round-trip
   - Ask the user to send a follow-up message so tools can initialize
   - Then proceed with MCP tools on the second turn

### After the first turn:

Once deferred tools appear in system-reminder, use ToolSearch to load their
schemas before calling them. MCP tools work normally from the second turn onward.
CONTEXT
