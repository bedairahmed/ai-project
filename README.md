# TerraForge AI — Agent Development Team

AI-powered team of 7 specialist agents that help validate, design, build, and launch TerraForge AI.

## What is TerraForge AI?

AI-Powered Infrastructure Lifecycle Platform — generates Azure landing zones through conversational AI, producing Terraform code, CI/CD pipelines, and professional documentation (SOW, HLD, LLD, Presentations, Runbooks).

## Prerequisites

- Linux (Ubuntu 22.04+ recommended)
- [uv](https://docs.astral.sh/uv/) package manager (installed by setup.sh)
- [Anthropic API key](https://console.anthropic.com/settings/keys)
- [OpenAI API key](https://platform.openai.com/api-keys)

## Quick Start

```bash
# Clone the repo
git clone git@github.com:bedairahmed/ai-project.git ~/terraforge-ai
cd ~/terraforge-ai

# Run full setup (installs uv, CrewAI, SSH key, API keys, everything)
chmod +x setup.sh
./setup.sh install

# Run your AI team
./setup.sh run review                              # All 7 agents validate product
./setup.sh run build "write the auth middleware"    # CTO + Engineer + Security
./setup.sh run plan "just finished project setup"   # PM + CTO plan sprint
./setup.sh run business "validate $199 pricing"     # Sales + Marketing

# Git operations
./setup.sh push "added new feature"                 # Commit + push
./setup.sh pull                                     # Pull latest
./setup.sh update                                   # Pull + update deps
./setup.sh status                                   # Project info
```

## Environment Variables

API keys are stored in `~/terraforge-ai/.env` (created during `./setup.sh install`).

This file is **gitignored** and will never be pushed to GitHub.

```bash
# ~/terraforge-ai/.env
ANTHROPIC_API_KEY=sk-ant-your-key-here
OPENAI_API_KEY=sk-your-key-here
```

To edit your keys later:
```bash
nano ~/terraforge-ai/.env
```

To get your keys:
- **Anthropic:** https://console.anthropic.com/settings/keys
- **OpenAI:** https://platform.openai.com/api-keys

## Your AI Team

| Agent | Role | LLM |
|---|---|---|
| **CTO** | Architecture, tech decisions, system design | Claude Sonnet 4 |
| **Engineer** | Write production code, debug, implement | Claude Sonnet 4 |
| **Cloud Architect** | Terraform modules, Azure, landing zones | Claude Sonnet 4 |
| **Security Lead** | Vulnerability review, compliance, fixes | Claude Sonnet 4 |
| **PM** | Sprint planning, risk mgmt, prioritization | Claude Sonnet 4 |
| **Sales/Business** | Market analysis, pricing, competitors | GPT-4o |
| **Marketing** | Positioning, content, launch strategy | GPT-4o |

## Crews (Agent Combinations)

| Command | Agents | Purpose |
|---|---|---|
| `./setup.sh run review` | All 7 | Full product validation from every perspective |
| `./setup.sh run build "desc"` | CTO + Engineer + Security | Design architecture, write code, security review |
| `./setup.sh run plan "status"` | PM + CTO | Sprint planning and technical validation |
| `./setup.sh run business "q"` | Sales + Marketing | Market analysis, pricing, content creation |

## Project Structure

```
~/terraforge-ai/
├── setup.sh                       ← Setup + run + push/pull script
├── .env                           ← API keys (NOT in git)
├── .gitignore                     ← Keeps secrets out of git
├── pyproject.toml                 ← Python/uv project config
├── README.md                      ← This file
└── src/terraforge_team/
    ├── config/
    │   ├── agents.yaml            ← 7 agent definitions
    │   └── tasks.yaml             ← 7 task templates
    ├── crew.py                    ← 4 crew configurations
    └── main.py                    ← Entry point
```

## All Commands

```bash
./setup.sh install                 # First-time full setup
./setup.sh update                  # Pull latest + upgrade deps
./setup.sh run review              # All 7 agents validate product
./setup.sh run build "description" # CTO + Engineer + Security write code
./setup.sh run plan "status"       # PM + CTO plan next sprint
./setup.sh run business "question" # Sales + Marketing analyze market
./setup.sh push "commit message"   # Git add + commit + push
./setup.sh pull                    # Git pull latest
./setup.sh status                  # Show project info
./setup.sh help                    # Show all commands
```

## Cost Per Run

| Crew | Agents | Est. Cost |
|---|---|---|
| review | 7 | $2-5 |
| build | 3 | $1-3 |
| plan | 2 | $0.50-1 |
| business | 2 | $0.50-1 |

Monthly estimate (active development): **$50-150/month**

## Updating

```bash
./setup.sh update    # Pulls latest code + upgrades CrewAI via uv
```

## Tech Stack

- **Package Manager:** [uv](https://docs.astral.sh/uv/) by Astral (replaces pip/venv)
- **AI Framework:** [CrewAI](https://docs.crewai.com/)
- **LLMs:** Claude Sonnet 4 (Anthropic) + GPT-4o (OpenAI)
- **Hosting:** Azure Linux VM (agenticai-lnx)
- **Repo:** [github.com/bedairahmed/ai-project](https://github.com/bedairahmed/ai-project)