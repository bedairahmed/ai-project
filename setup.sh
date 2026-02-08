#!/bin/bash
#===============================================================
# TerraForge AI — Agent Team Setup & Management
#
# FIRST TIME:  chmod +x setup.sh && ./setup.sh install
# UPDATE:      ./setup.sh update
# RUN:         ./setup.sh run review
#              ./setup.sh run build "design the database schema"
#              ./setup.sh run plan "finished auth setup"
#              ./setup.sh run business "validate pricing"
# PUSH:        ./setup.sh push "commit message"
# PULL:        ./setup.sh pull
# STATUS:      ./setup.sh status
#===============================================================
set -e
GREEN='\033[0;32m';YELLOW='\033[1;33m';BLUE='\033[0;34m';NC='\033[0m'
REPO="git@github.com:bedairahmed/ai-project.git"
DIR="$HOME/terraforge-ai"
CMD="${1:-help}"

case "$CMD" in
#---------------------------------------------------------------
help)
#---------------------------------------------------------------
    echo ""
    echo -e "${BLUE}TerraForge AI — Agent Team${NC}"
    echo ""
    echo "  ./setup.sh install                    Full first-time setup"
    echo "  ./setup.sh update                     Pull latest + update deps"
    echo "  ./setup.sh run review                 All 7 agents validate product"
    echo "  ./setup.sh run build \"desc\"           CTO+Engineer+Security"
    echo "  ./setup.sh run plan \"status\"          PM+CTO plan sprint"
    echo "  ./setup.sh run business \"question\"    Sales+Marketing"
    echo "  ./setup.sh push \"message\"             Commit + push to GitHub"
    echo "  ./setup.sh pull                       Pull latest from GitHub"
    echo "  ./setup.sh status                     Show project info"
    echo ""
    ;;

#---------------------------------------------------------------
install)
#---------------------------------------------------------------
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  TerraForge AI — Full Installation       ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
    echo ""

    # 1 System deps
    echo -e "${GREEN}[1/10] System dependencies...${NC}"
    sudo apt update -qq
    sudo apt install -y -qq python3 python3-pip git curl openssh-client >/dev/null 2>&1
    echo "  ✓ Done"

    # 2 Install uv
    echo -e "${GREEN}[2/10] Installing uv package manager...${NC}"
    if ! command -v uv &>/dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
        # Add to bashrc so it persists
        grep -q 'astral' ~/.bashrc 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi
    echo "  ✓ uv $(uv --version 2>/dev/null || echo 'installed')"

    # 3 Install CrewAI CLI
    echo -e "${GREEN}[3/10] Installing CrewAI...${NC}"
    uv tool install crewai 2>/dev/null || uv tool upgrade crewai 2>/dev/null || true
    uv tool update-shell 2>/dev/null || true
    export PATH="$HOME/.local/bin:$PATH"
    echo "  ✓ CrewAI CLI installed"

    # 4 Git config
    echo -e "${GREEN}[4/10] Git config...${NC}"
    git config --global user.name "bedairahmed"
    git config --global user.email "abedair@gmail.com"
    git config --global init.defaultBranch main
    echo "  ✓ Done"

    # 5 SSH key
    echo -e "${GREEN}[5/10] SSH key for GitHub...${NC}"
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        ssh-keygen -t ed25519 -C "abedair@gmail.com" -f ~/.ssh/id_ed25519 -N ""
        eval "$(ssh-agent -s)" >/dev/null 2>&1
        ssh-add ~/.ssh/id_ed25519 2>/dev/null
        echo ""
        echo -e "${YELLOW}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║  ADD THIS SSH KEY TO GITHUB                    ║${NC}"
        echo -e "${YELLOW}║  Go to: https://github.com/settings/keys       ║${NC}"
        echo -e "${YELLOW}║  Click 'New SSH key' → Title: agenticai-lnx    ║${NC}"
        echo -e "${YELLOW}║  Paste the key below:                          ║${NC}"
        echo -e "${YELLOW}╚════════════════════════════════════════════════╝${NC}"
        echo ""
        cat ~/.ssh/id_ed25519.pub
        echo ""
        read -p "  Press ENTER after adding key to GitHub..."
        ssh -T git@github.com 2>&1 || true
    else
        eval "$(ssh-agent -s)" >/dev/null 2>&1
        ssh-add ~/.ssh/id_ed25519 2>/dev/null || true
        echo "  ✓ Key exists"
    fi

    # 6 .gitignore FIRST
    echo -e "${GREEN}[6/10] Creating .gitignore...${NC}"
    mkdir -p "$DIR"
    cat > "$DIR/.gitignore" << 'GIEOF'
# Secrets
.env
.env.*

# Python
.venv/
venv/
__pycache__/
*.pyc
*.pyo
*.egg-info/
dist/
build/
.eggs/

# uv
.python-version

# IDE
.vscode/settings.json
.idea/
*.swp
*~

# OS
.DS_Store
Thumbs.db

# CrewAI
*.log
output/
logs/

# Node (future TerraForge portal)
node_modules/
.next/
GIEOF
    echo "  ✓ Done"

    # 7 Clone or init repo
    echo -e "${GREEN}[7/10] GitHub repository...${NC}"
    if [ -d "$DIR/.git" ]; then
        cd "$DIR"
        git remote set-url origin "$REPO" 2>/dev/null || true
        echo "  ✓ Repo exists"
    else
        HAS=$(git ls-remote "$REPO" HEAD 2>/dev/null | wc -l)
        if [ "$HAS" -gt 0 ]; then
            TMPD=$(mktemp -d)
            git clone "$REPO" "$TMPD/repo" 2>/dev/null
            cp -rn "$TMPD/repo/." "$DIR/" 2>/dev/null || true
            [ -d "$TMPD/repo/.git" ] && cp -r "$TMPD/repo/.git" "$DIR/.git" 2>/dev/null || true
            rm -rf "$TMPD"
            cd "$DIR"
        else
            cd "$DIR"
            git init
            git remote add origin "$REPO" 2>/dev/null || git remote set-url origin "$REPO"
        fi
        echo "  ✓ Done"
    fi

    # 8 API Keys
    echo -e "${GREEN}[8/10] API keys...${NC}"
    if [ ! -f "$DIR/.env" ]; then
        echo ""
        echo -e "${YELLOW}  Get Anthropic key: https://console.anthropic.com/settings/keys${NC}"
        read -p "  Anthropic API key: " AK
        echo -e "${YELLOW}  Get OpenAI key: https://platform.openai.com/api-keys${NC}"
        read -p "  OpenAI API key: " OK
        cat > "$DIR/.env" << EOF
ANTHROPIC_API_KEY=${AK}
OPENAI_API_KEY=${OK}
EOF
        echo "  ✓ Keys saved (.env is gitignored)"
    else
        echo "  ✓ .env exists"
    fi

    # 9 Create CrewAI project with uv
    echo -e "${GREEN}[9/10] Creating CrewAI project...${NC}"
    cd "$DIR"

    # Create project structure
    mkdir -p src/terraforge_team/config

    # pyproject.toml (uv-compatible)
    cat > pyproject.toml << 'PYEOF'
[project]
name = "terraforge-team"
version = "0.1.0"
description = "TerraForge AI - Agent Development Team"
requires-python = ">=3.10,<3.13"
dependencies = [
    "crewai[tools]>=0.100.0",
]

[build-system]
requires = ["setuptools"]
build-backend = "setuptools.build_meta"

[tool.uv]
dev-dependencies = []
PYEOF

    touch src/__init__.py
    touch src/terraforge_team/__init__.py

    # agents.yaml
    cat > src/terraforge_team/config/agents.yaml << 'AEOF'
cto:
  role: "CTO & Solution Architect"
  goal: "Make architecture and technology decisions for TerraForge AI — an AI SaaS platform (Next.js) that generates Azure landing zones with Terraform, pipelines, and documentation"
  backstory: >
    18yr exp cloud platforms, SaaS, Terraform. Stack: Next.js 14,
    TypeScript, Tailwind, PostgreSQL, Prisma, Azure OpenAI, GitHub
    Actions, custom Terraform modules. Give specific lib names+versions.
    Create Mermaid diagrams for architecture.
  llm: "anthropic/claude-sonnet-4-20250514"

engineer:
  role: "Lead Full-Stack Engineer"
  goal: "Write complete production-quality code for TerraForge AI with file paths, all imports, and clear comments"
  backstory: >
    Staff Engineer: Next.js 14 App Router, TypeScript strict, Tailwind,
    Prisma, PostgreSQL, NextAuth.js v5 Entra ID, Vercel AI SDK, GitHub
    Actions, Terraform. Write COMPLETE files never pseudocode. Rules:
    Zod validation all inputs, tenant isolation Prisma middleware,
    no secrets in client code.
  llm: "anthropic/claude-sonnet-4-20250514"

cloud_architect:
  role: "Principal Azure Cloud Architect"
  goal: "Design Terraform modules, Azure landing zone patterns, networking, identity, and governance"
  backstory: >
    15yr Azure, 50+ CAF landing zones. Expert hub-spoke networking,
    Entra ID RBAC, managed identities, mgmt groups, Azure Policy,
    CIS/ASB benchmarks. Write complete Terraform modules (main.tf,
    variables.tf, outputs.tf). Microsoft CAF naming. Checkov-compliant.
  llm: "anthropic/claude-sonnet-4-20250514"

security_lead:
  role: "Security Lead"
  goal: "Secure TerraForge AI platform and generated code. Provide fix code for every finding."
  backstory: >
    Expert OWASP Top10, Azure CIS/ASB, Checkov, tfsec, supply chain,
    multi-tenant SaaS security. Classify CRITICAL/HIGH/MEDIUM/LOW with
    CWE refs. Always provide fix code. Cover: auth, CSRF, XSS, CSP,
    OIDC, least-privilege RBAC, state encryption, PostgreSQL RLS.
  llm: "anthropic/claude-sonnet-4-20250514"

pm:
  role: "Technical Program Manager"
  goal: "Plan sprints, prioritize tasks, manage risks, keep the solo founder shipping"
  backstory: >
    Senior TPM 0-to-1 SaaS. Founder 20hrs/wk part-time. Break work
    into 1-4hr tasks with done criteria. Guard scope creep. Roadmap:
    1-Foundation 2-Security+Docs 3-MultiAgent 4-Lifecycle+Launch
    5-MultiCloud. Max 20hrs/sprint. One visible deliverable per sprint.
  llm: "anthropic/claude-sonnet-4-20250514"

sales_business:
  role: "VP Sales & Strategy"
  goal: "Validate market, refine pricing, analyze competitors, model financials for TerraForge AI"
  backstory: >
    15yr B2B SaaS dev tools. Free tier, Paid $99-299/mo, Business
    $499-999/mo, Enterprise custom. Targets: freelance consultants,
    architects, platform teams. Competitors: Terraform Cloud, Spacelift,
    Env0, Brainboard, Big4. Back claims with data.
  llm: "openai/gpt-4o"

marketing:
  role: "Head of Product Marketing"
  goal: "Create positioning, messaging, content, launch strategy for technical audiences"
  backstory: >
    Dev tool marketing. Write ACTUAL copy not descriptions. Devs hate
    hype. Differentiator: only product combining AI discovery + Terraform
    gen + full docs (SOW HLD LLD PPTX Runbooks) + scanning + lifecycle.
    Replaces 150K+ consultancy. Zero budget organic only.
  llm: "openai/gpt-4o"
AEOF

    # tasks.yaml
    cat > src/terraforge_team/config/tasks.yaml << 'TEOF'
architecture_review:
  description: >
    Review TerraForge AI architecture. Provide: 1) Mermaid diagram
    2) Tech recommendations with versions 3) Top 3 risks 4) Missing
    components. Context: {context}
  expected_output: "Architecture assessment with diagram, tech recs, risks, gaps"
  agent: cto

write_code:
  description: >
    Write production code for TerraForge AI. Complete files with paths,
    all imports, comments. Requirement: {context}
  expected_output: "Complete code files with paths, deps, env vars, next steps"
  agent: engineer

design_module:
  description: >
    Design Terraform module for: {context}
    Include main.tf, variables.tf, outputs.tf, usage example.
    Checkov-compliant. Microsoft CAF naming.
  expected_output: "Complete Terraform module with all files and usage example"
  agent: cloud_architect

security_review:
  description: >
    Security review: {context}
    Classify CRITICAL/HIGH/MEDIUM/LOW with CWE refs. Fix code for all.
  expected_output: "Classified findings with CWE references and fix code"
  agent: security_lead

sprint_planning:
  description: >
    Plan next sprint. Status: {context}
    Max 20hrs. Tasks 1-4hrs. Clear done criteria. One visible deliverable.
  expected_output: "Sprint plan with tasks, estimates, deps, done criteria"
  agent: pm

market_analysis:
  description: >
    Analyze market viability: {context}
    TAM/SAM/SOM, competitors, pricing, revenue projections.
  expected_output: "Market analysis with sizing, competitors, pricing, projections"
  agent: sales_business

create_content:
  description: >
    Create marketing content: {context}
    ACTUAL content ready to publish. Target: cloud architects, DevOps.
  expected_output: "Complete publish-ready content piece"
  agent: marketing
TEOF

    # crew.py
    cat > src/terraforge_team/crew.py << 'CEOF'
from crewai import Agent, Crew, Process, Task
from crewai.project import CrewBase, agent, crew, task

@CrewBase
class TerraforgeTeam:
    agents_config = "config/agents.yaml"
    tasks_config = "config/tasks.yaml"

    @agent
    def cto(self) -> Agent:
        return Agent(config=self.agents_config["cto"], verbose=True)
    @agent
    def engineer(self) -> Agent:
        return Agent(config=self.agents_config["engineer"], verbose=True)
    @agent
    def cloud_architect(self) -> Agent:
        return Agent(config=self.agents_config["cloud_architect"], verbose=True)
    @agent
    def security_lead(self) -> Agent:
        return Agent(config=self.agents_config["security_lead"], verbose=True)
    @agent
    def pm(self) -> Agent:
        return Agent(config=self.agents_config["pm"], verbose=True)
    @agent
    def sales_business(self) -> Agent:
        return Agent(config=self.agents_config["sales_business"], verbose=True)
    @agent
    def marketing(self) -> Agent:
        return Agent(config=self.agents_config["marketing"], verbose=True)

    @task
    def architecture_review(self) -> Task:
        return Task(config=self.tasks_config["architecture_review"])
    @task
    def write_code(self) -> Task:
        return Task(config=self.tasks_config["write_code"])
    @task
    def design_module(self) -> Task:
        return Task(config=self.tasks_config["design_module"])
    @task
    def security_review(self) -> Task:
        return Task(config=self.tasks_config["security_review"])
    @task
    def sprint_planning(self) -> Task:
        return Task(config=self.tasks_config["sprint_planning"])
    @task
    def market_analysis(self) -> Task:
        return Task(config=self.tasks_config["market_analysis"])
    @task
    def create_content(self) -> Task:
        return Task(config=self.tasks_config["create_content"])

    @crew
    def full_review(self) -> Crew:
        return Crew(
            agents=[self.cto(), self.engineer(), self.cloud_architect(),
                    self.security_lead(), self.pm(), self.sales_business(), self.marketing()],
            tasks=[self.architecture_review(), self.market_analysis(), self.sprint_planning()],
            process=Process.sequential, verbose=True)
    @crew
    def build(self) -> Crew:
        return Crew(
            agents=[self.cto(), self.engineer(), self.security_lead()],
            tasks=[self.architecture_review(), self.write_code(), self.security_review()],
            process=Process.sequential, verbose=True)
    @crew
    def plan(self) -> Crew:
        return Crew(
            agents=[self.pm(), self.cto()],
            tasks=[self.sprint_planning()],
            process=Process.sequential, verbose=True)
    @crew
    def business(self) -> Crew:
        return Crew(
            agents=[self.sales_business(), self.marketing()],
            tasks=[self.market_analysis(), self.create_content()],
            process=Process.sequential, verbose=True)
CEOF

    # main.py
    cat > src/terraforge_team/main.py << 'MEOF'
#!/usr/bin/env python
import sys
from terraforge_team.crew import TerraforgeTeam

def run():
    mode = sys.argv[1] if len(sys.argv) > 1 else "review"
    context = " ".join(sys.argv[2:]) if len(sys.argv) > 2 else \
        "TerraForge AI: AI-Powered Infrastructure Lifecycle Platform. "\
        "SaaS Next.js portal generating Azure landing zones with Terraform, "\
        "GitHub Actions, and docs (SOW,HLD,LLD,PPTX,Runbooks). "\
        "Checkov scanning, Infracost. Free+Paid+Enterprise. "\
        "Solo founder 20hrs/wk. Validate and plan first sprint."

    inputs = {"context": context}
    team = TerraforgeTeam()
    crews = {
        "review": ("FULL TEAM REVIEW (all 7 agents)", team.full_review),
        "build": ("BUILD CREW (CTO+Engineer+Security)", team.build),
        "plan": ("PLANNING (PM+CTO)", team.plan),
        "business": ("BUSINESS (Sales+Marketing)", team.business),
    }
    if mode not in crews:
        print("Usage: ./setup.sh run [review|build|plan|business] [context]")
        return
    name, fn = crews[mode]
    print(f"\n{'='*60}\n  {name}\n{'='*60}\n")
    result = fn().kickoff(inputs=inputs)
    print(f"\n{'='*60}\n  RESULT\n{'='*60}\n{result}")

if __name__ == "__main__":
    run()
MEOF

    # Install deps with uv
    echo "  Installing dependencies with uv..."
    cd "$DIR"
    uv sync 2>/dev/null || uv pip install -r pyproject.toml 2>/dev/null || pip install crewai[tools] 2>/dev/null
    echo "  ✓ All project files created and dependencies installed"

    # 10 README + Push
    echo -e "${GREEN}[10/10] README + push to GitHub...${NC}"

    cat > "$DIR/README.md" << 'REOF'
# TerraForge AI — Agent Development Team

AI-powered team of 7 specialist agents that help validate, design, build, and launch TerraForge AI.

## What is TerraForge AI?

AI-Powered Infrastructure Lifecycle Platform — generates Azure landing zones through conversational AI, producing Terraform code, CI/CD pipelines, and professional documentation (SOW, HLD, LLD, Presentations, Runbooks).

## Prerequisites

- Linux (Ubuntu 22.04+ recommended)
- [uv](https://docs.astral.sh/uv/) package manager
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
| `run review` | All 7 | Full product validation |
| `run build` | CTO + Engineer + Security | Design, code, review |
| `run plan` | PM + CTO | Sprint planning |
| `run business` | Sales + Marketing | Market analysis + content |

## Project Structure

```
terraforge-ai/
├── setup.sh                       ← Setup + run script
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

## Cost Per Run

| Crew | Agents | Est. Cost |
|---|---|---|
| review | 7 | $2-5 |
| build | 3 | $1-3 |
| plan | 2 | $0.50-1 |
| business | 2 | $0.50-1 |

## Updating

```bash
./setup.sh update    # Pulls latest code + upgrades CrewAI
```

## Tech Stack

- **Package Manager:** [uv](https://docs.astral.sh/uv/) (by Astral)
- **AI Framework:** [CrewAI](https://docs.crewai.com/)
- **LLMs:** Claude Sonnet 4 (Anthropic) + GPT-4o (OpenAI)
- **Hosting:** Azure Linux VM
REOF

    cd "$DIR"
    git add .
    git commit -m "Initial TerraForge AI agent team (uv + CrewAI)" 2>/dev/null || echo "  (nothing new to commit)"
    git branch -M main
    git push -u origin main 2>/dev/null && echo "  ✓ Pushed to GitHub" \
        || echo -e "${YELLOW}  ⚠ Push failed — run: ./setup.sh push \"initial\"${NC}"

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Installation Complete!                ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo "  Run your team:  ./setup.sh run review"
    echo ""
    ;;

#---------------------------------------------------------------
update)
#---------------------------------------------------------------
    echo -e "${GREEN}Updating TerraForge AI...${NC}"
    cd "$DIR"
    git pull origin main 2>/dev/null || true
    export PATH="$HOME/.local/bin:$PATH"
    uv tool upgrade crewai 2>/dev/null || true
    uv sync 2>/dev/null || true
    echo -e "${GREEN}✓ Updated${NC}"
    ;;

#---------------------------------------------------------------
run)
#---------------------------------------------------------------
    cd "$DIR"
    export PATH="$HOME/.local/bin:$PATH"
    shift
    source "$DIR/.venv/bin/activate" && PYTHONPATH="$DIR/src" python -m terraforge_team.main "$@" 2>/dev/null \
        || PYTHONPATH="$DIR/src" python3 -m terraforge_team.main "$@"
    ;;

#---------------------------------------------------------------
push)
#---------------------------------------------------------------
    cd "$DIR"
    shift
    MSG="${*:-update}"
    git add .
    git commit -m "$MSG"
    git push origin main
    echo -e "${GREEN}✓ Pushed: $MSG${NC}"
    ;;

#---------------------------------------------------------------
pull)
#---------------------------------------------------------------
    cd "$DIR"
    git pull origin main
    echo -e "${GREEN}✓ Pulled latest${NC}"
    ;;

#---------------------------------------------------------------
status)
#---------------------------------------------------------------
    cd "$DIR"
    echo ""
    echo -e "${BLUE}Project:${NC}  $DIR"
    echo -e "${BLUE}Remote:${NC}   $(git remote get-url origin 2>/dev/null || echo 'not set')"
    echo -e "${BLUE}Branch:${NC}   $(git branch --show-current 2>/dev/null || echo 'unknown')"
    echo ""
    echo -e "${BLUE}Files:${NC}"
    find src -type f \( -name "*.py" -o -name "*.yaml" \) | sort
    echo ""
    echo -e "${BLUE}Git:${NC}"
    git status --short
    echo ""
    echo -e "${BLUE}uv:${NC}       $(uv --version 2>/dev/null || echo 'not installed')"
    echo -e "${BLUE}CrewAI:${NC}   $(crewai version 2>/dev/null || echo 'not found')"
    echo -e "${BLUE}Python:${NC}   $(python3 --version 2>/dev/null)"
    echo ""
    ;;

*)
    echo "Unknown: $CMD — run ./setup.sh help"
    ;;
esac