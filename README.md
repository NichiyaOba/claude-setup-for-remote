# claude-setup-for-remote

A collection of setup scripts for Claude's remote Web/App execution environments.
Simply run `main.sh` to install all required tools at once.

> **[日本語版ドキュメント](docs/README.ja.md)**

## Usage

### Setup on Claude Code (One-liner)

Paste and execute the following in a Claude remote execution environment (Web / App):

```bash
WORKDIR="$(mktemp -d /tmp/claude-setup-for-remote.XXXXXX)" && git clone https://github.com/NichiyaOba/claude-setup-for-remote.git "${WORKDIR}" && bash "${WORKDIR}/main.sh"
```

This clones the repository into a temporary directory and runs `main.sh`.

### Standard Execution

```bash
git clone https://github.com/NichiyaOba/claude-setup-for-remote.git
bash claude-setup-for-remote/main.sh
```

## Installed Tools

| Tool | Version | Description |
|------|---------|-------------|
| [pinact](https://github.com/suzuki-shunsuke/pinact) | v3.9.0 | Pin GitHub Actions versions to SHAs |
| [jq](https://github.com/jqlang/jq) | jq-1.8.1 | Lightweight and flexible command-line JSON processor |
| [gh](https://github.com/cli/cli) | v2.89.0 | GitHub official CLI (PRs, Issues, Actions) |
| [shellcheck](https://github.com/koalaman/shellcheck) | v0.11.0 | Static analysis tool for shell scripts |
| [actionlint](https://github.com/rhysd/actionlint) | v1.7.12 | Static analysis tool for GitHub Actions workflows |

## Adding Tools

Create a `packages/<tool-name>/` directory and place the following two files:

```
packages/
└── <tool-name>/
    ├── install.sh   # Installation script (required)
    └── README.md    # Tool description (recommended)
```

`main.sh` automatically detects and runs `packages/*/install.sh`, so all you need to do is add the files.

## Multi-Agent Engineering Framework

This repository includes a framework for running multi-agent development workflows on Claude Code.

### Quick Start

Simply pass a task description to the `/dev` command in a Claude Code prompt to automatically execute from design to implementation:

```
/dev Add user authentication feature
```

#### Examples

```
/dev Add a shellcheck installation script to packages/shellcheck/
```

```
/dev Implement dry-run mode (--dry-run option) in main.sh
```

### Workflow Details

The `/dev` command executes the following 3 phases sequentially. The design and implementation phases loop up to 3 times until approved by review.

```
Phase 0: Investigation
  ┌─────────────────────────────────────────────────┐
  │  investigator (Codebase investigation & report)  │
  └─────────────────────────────────────────────────┘
       ↓
Phase 1: Design Loop
  ┌─────────────────────────────────────────────────┐
  │  architect (Design document & commit plan)        │
  │       ↓                                          │
  │  design-reviewer (Review)                        │
  │       ↓                                          │
  │  APPROVED → Proceed to Phase 2                   │
  │  NEEDS_REVISION → Back to architect (max 3x)      │
  └─────────────────────────────────────────────────┘
       ↓
Phase 2: Implementation Loop
  ┌─────────────────────────────────────────────────┐
  │  implementer (Code implementation)               │
  │       ↓                                          │
  │  implementation-reviewer (Review)                │
  │       ↓                                          │
  │  APPROVED → Done                                 │
  │  NEEDS_REVISION → Back to implementer (max 3x)   │
  └─────────────────────────────────────────────────┘
```

If not approved after 3 loops, the decision is deferred to the user ("proceed as-is" / "fix manually" / "abort").

### Agent Configuration

Agents used in the `/dev` workflow:

| Agent | Role | Model | Definition |
|-------|------|-------|------------|
| investigator | Codebase investigation & report | Sonnet | `.claude/agents/investigator.md` |
| architect | Requirements analysis, architecture design & document creation | Sonnet | `.claude/agents/architect.md` |
| design-reviewer | Design document review & approval/revision decisions | Opus | `.claude/agents/design-reviewer.md` |
| implementer | Code implementation based on design documents | Sonnet | `.claude/agents/implementer.md` |
| implementation-reviewer | Code quality & design compliance review | Opus | `.claude/agents/implementation-reviewer.md` |

Utility agents (available outside `/dev` as well):

| Agent | Role | Model | Definition |
|-------|------|-------|------------|
| code-reviewer | Post-change quality, security & maintainability review | Sonnet | `.claude/agents/code-reviewer.md` |
| commit-planner | Optimal commit splitting based on diff analysis | Opus | `.claude/agents/commit-planner.md` |

Implementation agents use Sonnet (fast, low-cost), while review/decision agents serving as quality gates use Opus (high-accuracy).

### Customizing Agents

Each agent's behavior is defined in Markdown files under `.claude/agents/`.
Edit these files to customize review criteria, output formats, and decision thresholds.

#### Customization Examples

- **Add review criteria**: Add new items to the "Review Criteria" section in `design-reviewer.md`
- **Change output format**: Edit the "Output Format" section of each agent
- **Adjust decision thresholds**: Modify APPROVED/NEEDS_REVISION thresholds in `*-reviewer.md`
- **Change loop limits**: Modify the loop limit values in `.claude/commands/dev.md`
