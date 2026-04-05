---
name: dependabot
description: |
  dependabotのPRを自動処理するワークフローを起動する。デフォルトブランチのマージ→ライブラリ調査→コメント投稿→Approveまでを自動実行する。
  使い方: /dependabot [PR URL | ブランチ名 | リポジトリURL | 引数なし]
user-invocable: true
allowed-tools:
  - Agent
  - Read
  - Glob
  - Grep
  - Bash
  - TodoWrite
  - AskUserQuestion
---

# /dependabot — dependabot PR 自動処理ワークフロー

あなたはオーケストレーターです。dependabot が作成した PR を順次処理し、最終サマリーを出力してください。

## 引数

`$ARGUMENTS`

---

## Step 1: 対象PR一覧の取得

引数を解析し、処理対象の dependabot PR 一覧を取得してください。

### 引数パターン

**PR URL が指定された場合** (例: `https://github.com/owner/repo/pull/123`):
- URLから owner/repo と PR番号を抽出する
- `gh pr view <PR番号> --repo <owner/repo> --json number,title,url,headRefName,state,author` で詳細を取得する
- そのPRのみを対象とする

**ブランチ名が指定された場合** (例: `dependabot/npm_and_yarn/lodash-4.17.21`):
- カレントリポジトリの対応するPRを対象とする
- `gh pr list --head <ブランチ名> --json number,title,url,state,author` で取得

**リポジトリURLが指定された場合** (例: `https://github.com/owner/repo`):
- そのリポジトリのdependabot PRを対象とする
- `gh pr list --repo <owner/repo> --author app/dependabot --state open --json number,title,url,headRefName` で取得

**引数なし**:
- カレントリポジトリのdependabot PRを対象とする
- `gh pr list --author app/dependabot --state open --json number,title,url,headRefName` で取得

### 対象外の除外

取得した一覧から以下を除外する:
- state が `MERGED` または `CLOSED` のPR

---

## Step 2: デフォルトブランチの取得

以下のコマンドでリポジトリのデフォルトブランチ名を動的に取得する:

```bash
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

---

## Step 3: 各PRのサブエージェント処理

対象PRが0件の場合は「処理対象のdependabot PRが見つかりませんでした。」と出力して終了する。

対象PRが1件以上の場合、**順次**（並列ではなく1件ずつ）以下のサブエージェントを起動する。

```
Agent(model="claude-sonnet-4-5", tools=["Bash", "WebSearch", "WebFetch", "Read", "Glob", "Grep", "mcp__github__create_pull_request_review", "mcp__github__add_pull_request_review_comment", "mcp__github__get_pull_request", "mcp__github__list_pull_request_files"], prompt="
あなたはdependabot PRの処理エージェントです。以下のPRを処理してください。

## 処理対象PR
- PR URL: {PR_URL}
- PR番号: {PR_NUMBER}
- タイトル: {PR_TITLE}
- ブランチ名: {HEAD_BRANCH}

## デフォルトブランチ
{DEFAULT_BRANCH}

## リポジトリ
{REPO} (owner/repo 形式)

---

## Step A: PRの状態確認

処理を開始する前に `gh pr view {PR_NUMBER} --repo {REPO} --json state,mergeable` でPRの状態を確認する。
- state が MERGED または CLOSED の場合: 「PR #{PR_NUMBER} はすでにマージ/クローズ済みのためスキップします。」と出力して処理を終了する。
- mergeable が CONFLICTING の場合: 「PR #{PR_NUMBER} はコンフリクトが発生しているためスキップします。」とコメントを投稿して処理を終了する。

---

## Step B: デフォルトブランチのマージ

1. `gh pr checkout {PR_NUMBER} --repo {REPO}` でPRのブランチをチェックアウトする
2. `git fetch origin {DEFAULT_BRANCH}` でデフォルトブランチの最新を取得する
3. `git merge origin/{DEFAULT_BRANCH}` でデフォルトブランチをマージする
   - マージコンフリクトが発生した場合:
     a. `git merge --abort` でマージを中止する
     b. `gh pr comment {PR_NUMBER} --repo {REPO} --body 'マージコンフリクトが発生したため、自動処理をスキップしました。手動での対応が必要です。'` でコメントを投稿する
     c. 「PR #{PR_NUMBER} でマージコンフリクトが発生しました。」と出力して処理を終了する
4. `git push` でプッシュする
   - 失敗した場合: エラーを記録して次のステップに進む（致命的エラーとはしない）

---

## Step C: ライブラリ変更の調査

1. `gh pr view {PR_NUMBER} --repo {REPO} --json title,body,files` でPRの詳細（タイトル・本文・変更ファイル）を取得する
2. PRのタイトルと本文からアップデート対象のライブラリ名とバージョン（旧→新）を特定する
3. 以下の情報をWebSearch/WebFetchで調査する（各1回リトライ、失敗時は「取得不可」と記載）:
   - **チェンジログ**: `{ライブラリ名} {新バージョン} changelog` で検索し、旧バージョンから新バージョンの変更内容を取得する
   - **破壊的変更**: チェンジログに breaking changes が含まれるか確認する
   - **セキュリティ修正**: CVE番号やセキュリティフィックスの記載があるか確認する

---

## Step D: サマリーコメントの投稿

調査結果をもとに以下のフォーマットでPRにコメントを投稿する。

MCPツール（mcp__github__add_pull_request_review_comment など）が利用可能な場合はそれを使用し、利用不可の場合は `gh pr comment` コマンドにフォールバックする。

コメント本文フォーマット:
\`\`\`
## dependabot PR 自動調査レポート

**ライブラリ**: {ライブラリ名}
**バージョン**: {旧バージョン} → {新バージョン}

### 変更内容サマリー
{チェンジログの要約。取得不可の場合は「チェンジログを取得できませんでした。」}

### 破壊的変更
{あり/なし/確認不可} {内容があれば記載}

### セキュリティ修正
{あり/なし/確認不可} {CVE番号などがあれば記載}

---
*このコメントは Claude によって自動生成されました。*
\`\`\`

---

## Step E: 影響判定とApprove

以下の基準で影響を判定し、問題がなければPRをApproveする。

**Approve条件（すべて満たす場合）:**
- 破壊的変更がない（または「確認不可」）
- セキュリティ上の重大な問題が含まれていない

**Approveしない条件（いずれかに該当する場合）:**
- 明確な破壊的変更が確認された

Approve条件を満たす場合:
- MCPツール（mcp__github__create_pull_request_review）が利用可能な場合はそれを使用してApproveする
- 利用不可の場合は `gh pr review {PR_NUMBER} --repo {REPO} --approve --body '自動調査の結果、問題なしと判断しApproveしました。'` でApproveする

Approveしない場合:
- 「PR #{PR_NUMBER} は破壊的変更が含まれるためApproveをスキップしました。」と出力する

---

## Step F: CI監視

1. `gh pr checks {PR_NUMBER} --repo {REPO} --watch --timeout 600` でCIの完了を待機する（最大10分）
   - **レート制限エラー** (HTTP 403/429) が発生した場合: 60秒待機して1回リトライする
   - **タイムアウト** (10分経過) した場合: `gh pr comment {PR_NUMBER} --repo {REPO} --body 'CIの完了を待機しましたが、タイムアウトしました（10分）。手動での確認をお願いします。'` でコメントを投稿して完了扱いにする
2. CIが失敗した場合:
   - `gh run list --branch {HEAD_BRANCH} --repo {REPO} --limit 5 --json databaseId,name,status,conclusion` で失敗したrunを特定する
   - `gh run view <run_id> --repo {REPO} --log-failed` で失敗ログを取得する（最初の失敗runのみ）
   - `gh pr comment {PR_NUMBER} --repo {REPO} --body '## CI失敗レポート\n\n{失敗ログのサマリー}'` で結果をコメントする

---

## 処理完了報告

以下のフォーマットで処理結果を出力する:

\`\`\`
## PR #{PR_NUMBER} 処理完了

- デフォルトブランチマージ: {成功/失敗/スキップ}
- ライブラリ調査: {完了/取得不可}
- サマリーコメント: {投稿済み/失敗}
- Approve: {承認済み/スキップ（破壊的変更）/失敗}
- CI: {成功/失敗/タイムアウト/スキップ}
\`\`\`
")
```

---

## Step 4: 最終サマリー出力

全PRの処理が完了したら、以下のフォーマットで最終サマリーを出力する。

```markdown
# /dependabot 処理完了サマリー

## 処理結果一覧

| PR | タイトル | マージ | 調査 | Approve | CI |
|----|----------|--------|------|---------|-----|
| #{番号} | {タイトル} | {結果} | {結果} | {結果} | {結果} |

## 統計
- 処理対象: {N}件
- Approve済み: {N}件
- スキップ: {N}件（マージ済み/コンフリクト/破壊的変更）
- CI成功: {N}件
- 要確認: {N}件
```
