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
