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
