<p align="center"><img src="docs/banner.svg" alt="smartdev: spec-driven, test-first pipeline plugin for Claude Code" width="100%"></p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude_Code-plugin-d97757?style=flat-square" alt="Claude Code plugin">
  <img src="https://img.shields.io/badge/board-Backlog.md-3b82f6?style=flat-square" alt="Backlog.md">
  <img src="https://img.shields.io/badge/always--on_cost-~213_tokens-22c55e?style=flat-square" alt="~213 tokens">
  <img src="https://img.shields.io/badge/setup-2_commands-a855f7?style=flat-square" alt="2-command setup">
</p>

**A Claude Code plugin that turns AI-assisted coding into a disciplined pipeline.** Every project moves through explore → stories → spec → test-first build → review, one stage per session. State lives in files and on a Kanban board, never in chat history.

| Without it | With smartdev |
|---|---|
| Long chats that drift, and quality drops as context fills | One stage per fresh session, kept under 40% context |
| Scope creeps mid-session | Every new idea becomes a **Parked** card, never code |
| "Where was I?" after a week away | State loads automatically when a session starts |
| AI says "done" without proof | Test-first build, then an independent review session |

## Pipeline

```mermaid
flowchart LR
    E([Explore]):::explore --> S([User stories]):::stories
    S -->|next card| P
    subgraph perstory [" per story "]
        direction LR
        P([Spec]):::spec --> B([Build · TDD]):::build --> R([Review]):::review
        R -->|fixes| B
    end
    R -->|pass| D([Done]):::done
    D -.->|next card| P
    F([Fast lane · small fix]):::fast -.-> B

    classDef explore fill:#dbeafe,stroke:#3b82f6,color:#1e3a8a
    classDef stories fill:#cffafe,stroke:#06b6d4,color:#164e63
    classDef spec fill:#f3e8ff,stroke:#a855f7,color:#581c87
    classDef build fill:#dcfce7,stroke:#22c55e,color:#14532d
    classDef review fill:#fef3c7,stroke:#f59e0b,color:#78350f
    classDef done fill:#d1fae5,stroke:#10b981,color:#064e3b
    classDef fast fill:#fef9c3,stroke:#eab308,color:#713f12
```

| | Stage | Output |
|:-:|---|---|
| <img src="docs/icons/explore.svg" width="18"> | **Explore** | `docs/explore.md`: problem, users, constraints, how to test |
| <img src="docs/icons/stories.svg" width="18"> | **Stories** | One board card per story, with acceptance criteria, plus non-goals |
| <img src="docs/icons/spec.svg" width="18"> | **Spec** | A minimal plan inside the card: approach, files, test list |
| <img src="docs/icons/build.svg" width="18"> | **Build** | Red → green → refactor, one commit per green test |
| <img src="docs/icons/review.svg" width="18"> | **Review** | Fresh eyes check code against spec and criteria. Pass → Done, fail → fix list |
| <img src="docs/icons/fastlane.svg" width="18"> | **Fast lane** | Small fixes skip straight to build and review |

## Quick start

```bash
git clone git@github.com:Suman196pokhrel/smartdev.git ~/DevStuff/projects/smartdev
~/DevStuff/projects/smartdev/install.sh
```

Restart Claude Code, open any project and run **`/smartdev:start`**.

<sub>Needs <code>git</code>, <code>jq</code>, <code>npm</code>, <code>claude</code> and a <a href="https://www.nerdfonts.com">Nerd Font</a> for the status line icons. Update with <code>git pull</code> then <code>/reload-plugins</code>.</sub>

## A session

```mermaid
sequenceDiagram
    autonumber
    actor You
    participant H as Hooks
    participant C as Claude
    participant F as Files + Board
    You->>C: open session
    H->>C: inject .smartdev/STATE.md (~200 tokens)
    C->>F: load only the current card + stage playbook
    C->>F: work one stage: code, tests, commits, card updates
    You->>C: "wrap up"
    H->>C: trigger handoff
    C->>F: rewrite STATE.md · log line · commit state
    C-->>You: 4-line handoff summary
```

## Commands

| | You do | What happens |
|:-:|---|---|
| <img src="docs/icons/explore.svg" width="18"> | `/smartdev:start` | Sets up a new project (git, board, state) or continues the current stage |
| <img src="docs/icons/handoff.svg" width="18"> | `wrap up` | Updates the card, rewrites state, logs the session, commits |
| <img src="docs/icons/done.svg" width="18"> | `backlog browser` | Kanban board in the browser (`backlog board` for the terminal) |
| <img src="docs/icons/stories.svg" width="18"> | `smartdev` | Every Smart Dev project on this machine: stage, task, progress, last session |

## Status line

Line 1 is always shown. Line 2 appears only inside Smart Dev projects.

| Segment | Why it's there |
|---|---|
| **Context bar** | Turns yellow at 30% and red at 40%, telling you when to hand off |
| **Last commit age** | Turns yellow when changes have sat uncommitted for 30+ minutes |
| **Git** | Branch, ahead/behind, staged, modified and untracked counts |
| **Usage** | Your 5-hour limit, with the reset time shown when it runs high |
| **Stage + task** | Where the pipeline is and which card is active |
| **Acceptance criteria** | Ticked criteria on the active card, e.g. `1/2` |
| **Board** | Stories done out of total, plus how many are parked |
| **Blocked** | Shown in red when the state has a blocker |

## Where state lives

```mermaid
flowchart LR
    ST[".smartdev/STATE.md<br/>stage · task · next · blockers"] -->|points to| CARD["backlog/tasks/task-N.md<br/>story · criteria · spec · notes"]
    BOARD[("Backlog.md board")] -->|owns status of| CARD
    LOG[".smartdev/log.md<br/>one line per session"]
    EX["docs/explore.md<br/>problem · constraints · non-goals"]
```

<sub>Everything is plain Markdown in the repo, so it's tracked in git. The board owns task status; STATE.md owns the pipeline stage.</sub>

<details>
<summary><b>Repo layout</b></summary>

```
.claude-plugin/   plugin + marketplace manifests
skills/start/     rules, init.sh, STATE template, stages/*.md (only the current one is read)
skills/handoff/   session close
hooks/            inject state on start · catch "wrap up"
statusline.sh     two-line status line
status.sh         the `smartdev` command
install.sh        setup and update, safe to re-run
docs/             banner, icons (Lucide, ISC), Excalidraw overview
```
</details>
