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

# Always ensure uv is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Activate .venv if it exists
activate_venv() {
    if [ -f "$DIR/.venv/bin/activate" ]; then
        source "$DIR/.venv/bin/activate"
    fi
}

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
    echo "  ./setup.sh activate                   Print venv activation command"
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
    fi
    # Persist uv in PATH
    grep -q '.local/bin' ~/.bashrc 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo "  ✓ uv $(uv --version 2>/dev/null || echo 'installed')"

    # 3 Git config
    echo -e "${GREEN}[3/10] Git config...${NC}"
    git config --global user.name "bedairahmed"
    git config --global user.email "abedair@gmail.com"
    git config --global init.defaultBranch main
    echo "  ✓ Done"

    # 4 SSH key
    echo -e "${GREEN}[4/10] SSH key for GitHub...${NC}"
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

    # 5 .gitignore
    echo -e "${GREEN}[5/10] Creating .gitignore...${NC}"
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

    # 6 Clone or init repo
    echo -e "${GREEN}[6/10] GitHub repository...${NC}"
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

    # 7 API Keys
    echo -e "${GREEN}[7/10] API keys...${NC}"
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

    # 8 Create venv + install CrewAI with all providers
    echo -e "${GREEN}[8/10] Python environment + CrewAI...${NC}"
    cd "$DIR"

    # pyproject.toml
    cat > pyproject.toml << 'PYEOF'
[project]
name = "terraforge-team"
version = "0.1.0"
description = "TerraForge AI - Agent Development Team"
requires-python = ">=3.10,<3.13"
dependencies = [
    "crewai[tools,anthropic]>=1.0.0",
]

[build-system]
requires = ["setuptools"]
build-backend = "setuptools.build_meta"

[dependency-groups]
dev = []
PYEOF

    # Create venv and install
    uv venv --quiet 2>/dev/null || uv venv
    source .venv/bin/activate
    uv pip install "crewai[tools,anthropic]" --quiet
    echo "  ✓ CrewAI + Anthropic provider installed in .venv"

    # 9 Project files
    echo -e "${GREEN}[9/10] Creating project files...${NC}"
    mkdir -p src/terraforge_team/config
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
from dotenv import load_dotenv
load_dotenv()

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

    echo "  ✓ All project files created"

    # 10 README + Push
    echo -e "${GREEN}[10/10] README + push to GitHub...${NC}"

    cat > "$DIR/README.md" << 'REOF'
# TerraForge AI — Agent Development Team

AI-powered team of 7 specialist agents that help validate, design, build, and launch TerraForge AI.

## What is TerraForge AI?

AI-Powered Infrastructure Lifecycle Platform — generates Azure landing zones through conversational AI, producing Terraform code, CI/CD pipelines, and professional documentation (SOW, HLD, LLD, Presentations, Runbooks).

## Prerequisites

- Linux (Ubuntu 22.04+)
- [Anthropic API key](https://console.anthropic.com/settings/keys)
- [OpenAI API key](https://platform.openai.com/api-keys)

Everything else (uv, CrewAI, Python venv) is installed automatically by `setup.sh`.

## First Time Setup

```bash
git clone git@github.com:bedairahmed/ai-project.git ~/terraforge-ai
cd ~/terraforge-ai
chmod +x setup.sh
./setup.sh install
```

The install script does everything:
1. Installs system dependencies
2. Installs [uv](https://docs.astral.sh/uv/) package manager
3. Configures Git + generates SSH key for GitHub
4. Creates `.gitignore` (keeps secrets out of git)
5. Clones/initializes the GitHub repo
6. Asks for API keys → saves to `.env` (gitignored)
7. Creates Python `.venv` with uv
8. Installs CrewAI + Anthropic provider
9. Creates all agent/task/crew files
10. Pushes to GitHub

## Run Your AI Team

```bash
# All 7 agents validate the product
./setup.sh run review

# CTO + Engineer + Security write code
./setup.sh run build "write the auth middleware"

# PM + CTO plan sprint
./setup.sh run plan "just finished project setup"

# Sales + Marketing analyze market
./setup.sh run business "validate $199 pricing"
```

## Git Operations

```bash
./setup.sh push "added new feature"    # Commit + push
./setup.sh pull                        # Pull latest
./setup.sh update                      # Pull + upgrade deps
./setup.sh status                      # Project info
```

## Manual Activation (if needed)

If you open a new terminal and need to work manually:

```bash
# 1. Add uv to PATH (needed once per terminal session)
export PATH="$HOME/.local/bin:$PATH"

# 2. Activate the Python virtual environment
cd ~/terraforge-ai
source .venv/bin/activate

# 3. Run agents manually
PYTHONPATH=src python -m terraforge_team.main review
PYTHONPATH=src python -m terraforge_team.main build "your task here"
```

Or add this to your `~/.bashrc` so it's always ready:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
echo 'alias tf="cd ~/terraforge-ai && source .venv/bin/activate"' >> ~/.bashrc
source ~/.bashrc
```

Then just type `tf` to activate everything, then `./setup.sh run review`.

## Environment Variables

API keys are stored in `~/terraforge-ai/.env` — this file is **gitignored**.

```bash
# View current keys
cat .env

# Edit keys
nano .env
```

Get your keys:
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

## Crews

| Command | Agents | Purpose |
|---|---|---|
| `run review` | All 7 | Full product validation |
| `run build` | CTO + Engineer + Security | Design, code, security review |
| `run plan` | PM + CTO | Sprint planning |
| `run business` | Sales + Marketing | Market + content |

## Project Structure

```
~/terraforge-ai/
├── setup.sh                       ← Setup/run/push/pull (this script)
├── .env                           ← API keys (NOT in git)
├── .gitignore                     ← Keeps secrets out of git
├── .venv/                         ← Python virtual env (NOT in git)
├── pyproject.toml                 ← Python/uv config
├── uv.lock                        ← Dependency lock file
├── README.md                      ← This file
└── src/terraforge_team/
    ├── config/
    │   ├── agents.yaml            ← 7 agent definitions
    │   └── tasks.yaml             ← 7 task templates
    ├── crew.py                    ← 4 crew configurations
    └── main.py                    ← Entry point
```

## Troubleshooting

**`uv: command not found`**
```bash
export PATH="$HOME/.local/bin:$PATH"
```

**`ModuleNotFoundError: No module named 'crewai'`**
```bash
cd ~/terraforge-ai
source .venv/bin/activate
uv pip install "crewai[tools,anthropic]"
```

**`Permission denied (publickey)` on git push**
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh -T git@github.com    # Should say "Hi bedairahmed!"
```

**API key errors**
```bash
nano ~/terraforge-ai/.env    # Check keys are correct
```

## Cost Per Run

| Crew | Agents | Est. Cost |
|---|---|---|
| review | 7 | $2-5 |
| build | 3 | $1-3 |
| plan | 2 | $0.50-1 |
| business | 2 | $0.50-1 |

## Tech Stack

- **Package Manager:** [uv](https://docs.astral.sh/uv/) by Astral
- **AI Framework:** [CrewAI](https://docs.crewai.com/) v1.9+
- **LLMs:** Claude Sonnet 4 (Anthropic) + GPT-4o (OpenAI)
- **Hosting:** Azure Linux VM
- **Repo:** [github.com/bedairahmed/ai-project](https://github.com/bedairahmed/ai-project)
REOF

    cd "$DIR"
    git add .
    git commit -m "Setup with uv, CrewAI, all fixes applied" 2>/dev/null || echo "  (nothing new)"
    git branch -M main
    git push -u origin main 2>/dev/null && echo "  ✓ Pushed to GitHub" \
        || echo -e "${YELLOW}  ⚠ Push failed — run: ./setup.sh push \"initial\"${NC}"

    # Add bash aliases
    grep -q 'alias tf=' ~/.bashrc 2>/dev/null || {
        echo '' >> ~/.bashrc
        echo '# TerraForge AI shortcuts' >> ~/.bashrc
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        echo 'alias tf="cd ~/terraforge-ai && source .venv/bin/activate"' >> ~/.bashrc
    }

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Installation Complete!                ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo "  Run your team:    ./setup.sh run review"
    echo "  Quick activate:   source ~/.bashrc && tf"
    echo ""
    ;;

#---------------------------------------------------------------
update)
#---------------------------------------------------------------
    echo -e "${GREEN}Updating TerraForge AI...${NC}"
    cd "$DIR"
    export PATH="$HOME/.local/bin:$PATH"
    git pull origin main 2>/dev/null || true
    source .venv/bin/activate
    uv pip install --upgrade "crewai[tools,anthropic]" --quiet
    echo -e "${GREEN}✓ Updated${NC}"
    ;;

#---------------------------------------------------------------
run)
#---------------------------------------------------------------
    cd "$DIR"
    export PATH="$HOME/.local/bin:$PATH"
    source .venv/bin/activate
    shift
    PYTHONPATH="$DIR/src" python -m terraforge_team.main "$@"
    ;;

#---------------------------------------------------------------
push)
#---------------------------------------------------------------
    cd "$DIR"
    shift
    MSG="${*:-update}"
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    ssh-add ~/.ssh/id_ed25519 2>/dev/null || true
    git add .
    git commit -m "$MSG"
    git push origin main
    echo -e "${GREEN}✓ Pushed: $MSG${NC}"
    ;;

#---------------------------------------------------------------
pull)
#---------------------------------------------------------------
    cd "$DIR"
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    ssh-add ~/.ssh/id_ed25519 2>/dev/null || true
    git pull origin main
    echo -e "${GREEN}✓ Pulled latest${NC}"
    ;;

#---------------------------------------------------------------
status)
#---------------------------------------------------------------
    cd "$DIR"
    export PATH="$HOME/.local/bin:$PATH"
    echo ""
    echo -e "${BLUE}Project:${NC}  $DIR"
    echo -e "${BLUE}Remote:${NC}   $(git remote get-url origin 2>/dev/null || echo 'not set')"
    echo -e "${BLUE}Branch:${NC}   $(git branch --show-current 2>/dev/null || echo 'unknown')"
    echo ""
    echo -e "${BLUE}Files:${NC}"
    find src -type f \( -name "*.py" -o -name "*.yaml" \) 2>/dev/null | sort
    echo ""
    echo -e "${BLUE}Git:${NC}"
    git status --short
    echo ""
    echo -e "${BLUE}uv:${NC}       $(uv --version 2>/dev/null || echo 'not found — run: export PATH=\$HOME/.local/bin:\$PATH')"
    echo -e "${BLUE}Python:${NC}   $(python3 --version 2>/dev/null)"
    echo -e "${BLUE}.venv:${NC}    $([ -d .venv ] && echo 'exists' || echo 'missing — run: ./setup.sh install')"
    echo -e "${BLUE}.env:${NC}     $([ -f .env ] && echo 'exists' || echo 'missing — run: ./setup.sh install')"
    echo ""
    ;;

#---------------------------------------------------------------
activate)
#---------------------------------------------------------------
    echo ""
    echo "Run these commands to activate manually:"
    echo ""
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo "  cd ~/terraforge-ai"
    echo "  source .venv/bin/activate"
    echo ""
    echo "Or add shortcut to bashrc (one time):"
    echo "  echo 'alias tf=\"cd ~/terraforge-ai && source .venv/bin/activate\"' >> ~/.bashrc"
    echo "  source ~/.bashrc"
    echo "  tf"
    echo ""
    ;;

*)
    echo "Unknown: $CMD — run ./setup.sh help"
    ;;
esac