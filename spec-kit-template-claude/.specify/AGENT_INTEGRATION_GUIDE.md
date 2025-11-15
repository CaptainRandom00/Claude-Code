# Agent Integration Quick Reference Guide

**Version**: 1.0.0
**Status**: Production Ready
**Last Updated**: 2025-01-15

---

## Overview

The spec-kit now intelligently routes feature implementation to specialist agents based on tech stack, file types, and domain analysis. This enables:

- **Automatic agent assignment** during planning phase
- **Intelligent routing** (React files → react-expert, Python → python-backend)
- **Error resilience** (retry → fallback → escalate pattern)
- **Complete audit trail** (execution logs with timestamps)
- **User overrides** (manual agent selection when needed)

---

## Quick Start

### Basic Workflow (Agent-Powered)

```bash
# 1. Create feature specification
/speckit.specify "Add user authentication with OAuth2"

# 2. Generate plan with automatic agent assignments
/speckit.plan
# ✅ Output: plan.md now includes "Agent Assignments" section
#    Example: US1 → @react-expert, US2 → @python-backend

# 3. Generate tasks with agent hints
/speckit.tasks
# ✅ Output: tasks.md with agent markers in phase headers

# 4. Implement with specialist agents
/speckit.implement
# ✅ Agents are invoked automatically based on assignments
#    - react-expert writes .tsx files
#    - python-backend writes .py files
#    - Each agent gets tailored context

# 5. Check execution log
cat .specify/logs/agent-execution-*.log
```

---

## Agent Routing Logic

### Priority 1: File Path Matching (Highest Confidence)

| File Extension | Assigned Agent |
|----------------|----------------|
| `.tsx`, `.jsx` | `react-expert` |
| `.py` (with FastAPI/Django) | `python-backend` |
| `.ts`, `.js` (with Node/Express) | `node-expert` |
| `.swift`, `.m` | `mobile-expert` |
| `.kt`, `.java` (Android) | `mobile-expert` |
| `.sql`, `migration` | `database-architect` |
| `.php` (with WordPress) | `wordpress-expert` |

### Priority 2: Domain Keywords

| Keywords in Title/Description | Assigned Agent |
|-------------------------------|----------------|
| api, endpoint, rest, graphql | `api-architect` |
| database, schema, query | `database-architect` |
| mobile, ios, android | `mobile-expert` |
| realtime, websocket | `realtime-systems` |
| cloud, aws, azure, gcp | `cloud-architect` |
| data pipeline, etl, analytics | `data-engineer` |
| test, qa, validation | `qa-engineer` |
| security, auth, encryption | `security-auditor` |

### Priority 3: Tech Stack Fallback

If no file paths or domain keywords match, uses tech stack from plan.md

---

## Manual Override System

When automatic routing isn't right, override it:

### Create Override File

Create `.specify/agent-overrides.json` in repository root:

```json
{
  "US1": {
    "primary_agent": "mobile-expert",
    "reason": "Actually building mobile app, not web"
  },
  "US2": {
    "primary_agent": "wordpress-expert",
    "reason": "Needs WordPress-specific knowledge"
  },
  "T042": {
    "assigned_agent": "security-auditor",
    "reason": "Critical security endpoint needs expert review"
  }
}
```

### Override Levels

- **Story-level**: `"US1"` overrides entire user story
- **Task-level**: `"T042"` overrides specific task

---

## Agent Capabilities

### All 21 Available Agents

| Agent | Type | Specialization |
|-------|------|----------------|
| `api-architect` | API Specialist | REST/GraphQL API design |
| `chief-architect` | Architecture Lead | System design, tech decisions |
| `cloud-architect` | Infrastructure | AWS/Azure/GCP deployments |
| `data-engineer` | Data Specialist | ETL pipelines, analytics |
| `database-architect` | Data Specialist | SQL/NoSQL design, optimization |
| `devops-web` | General | CI/CD, deployments |
| `frontend-perf` | General | Web performance optimization |
| `mobile-expert` | Mobile Specialist | iOS/Android/React Native |
| `node-expert` | General | Node.js backend services |
| `python-backend` | Backend Specialist | FastAPI/Django/Flask |
| `qa-engineer` | Quality Assurance | Testing strategies, Playwright |
| `react-expert` | Frontend Specialist | React/TypeScript UIs |
| `realtime-systems` | Realtime Specialist | WebSockets, streaming |
| `security-auditor` | General | Security reviews, audits |
| `seo-strategist` | General | SEO optimization |
| `stuck` | Escalation | Human escalation point |
| `tech-lead` | Coordination Lead | Multi-agent orchestration |
| `technical-seo` | General | Technical SEO audits |
| `ui-designer` | General | UI/UX design |
| `ux-researcher` | General | User research |
| `wordpress-expert` | CMS Specialist | WordPress/WooCommerce |

---

## Error Handling Flow

```
Agent Invocation
│
├─ Attempt 1: Primary Agent (e.g., react-expert)
│   ├─ ✅ Success → Continue
│   └─ ❌ Failure → Log error, retry
│
├─ Attempt 2: Retry with Error Context
│   ├─ ✅ Success → Continue
│   └─ ❌ Failure → Fallback
│
├─ Fallback: General-Purpose Agent
│   ├─ ✅ Success → Continue (log warning)
│   └─ ❌ Failure → Escalate
│
└─ Escalation: stuck Agent
    - Present options to user
    - User decides: Skip / Retry / Stop
```

---

## Execution Logs

### Log Location

`.specify/logs/agent-execution-YYYYMMDD-HHMMSS.log`

### Log Format

```
Agent Execution Log - 2025-01-15 14:32:10
Feature: 005-user-auth
==========================================

[14:32:10] US1 @react-expert SUCCESS (1 attempt, 45s)
  Tasks: 5/5 completed
  Files Created: LoginForm.tsx, AuthContext.tsx
  Files Modified: App.tsx

[14:33:00] US2 @python-backend SUCCESS (2 attempts, 60s)
  Tasks: 4/4 completed
  Files Created: auth.py, jwt_utils.py
  Files Modified: main.py

[14:34:00] US3 @database-architect SUCCESS (1 attempt, 30s)
  Tasks: 2/2 completed
  Files Created: 001_create_users_table.sql
```

---

## Troubleshooting

### Agent Not Found

**Error**: `WARNING: Agent react-expert not found`

**Fix**:
1. Check agent exists: `ls ~/.claude/agents/react-expert.md`
2. Run discovery: `.specify/scripts/bash/get-available-agents.sh`
3. If missing, create agent file with proper frontmatter

### Agent Assignment Seems Wrong

**Symptom**: Backend story assigned to frontend agent

**Fix**:
1. Create override file (see Manual Override System above)
2. Specify correct agent for that story
3. Re-run `/speckit.tasks` to update hints

### Execution Log Not Created

**Cause**: `.specify/logs/` directory missing

**Fix**:
```bash
mkdir -p .specify/logs
```

### Context Too Large (Token Limit)

**Cause**: Complex feature exceeds 4000 token context budget

**Fix**: Context builder automatically summarizes Tier 3
- No action needed, it's handled automatically
- Check context output: `.specify/scripts/bash/build-agent-context.sh --story-id US1 --agent-type react-expert --feature-dir ./specs/001-feature`

---

## Advanced Usage

### Test Agent Routing

```bash
# Test routing for specific scenario
.specify/scripts/bash/route-to-agent.sh \
  --tech-stack "React,TypeScript,FastAPI" \
  --domain "frontend" \
  --story-title "User login with OAuth" \
  --file-paths "src/components/LoginForm.tsx" \
  --json
```

### View Agent Registry

```bash
# Human-readable
.specify/scripts/bash/get-available-agents.sh

# JSON output
.specify/scripts/bash/get-available-agents.sh --json
```

### Build Context Manually

```bash
# Generate context for specific story/agent combo
.specify/scripts/bash/build-agent-context.sh \
  --story-id "US1" \
  --agent-type "react-expert" \
  --feature-dir "./specs/005-user-auth" \
  --json
```

---

## Best Practices

### 1. Trust the Routing

Automatic routing is correct 90%+ of the time. Only override when:
- Domain changed mid-project (web → mobile)
- Special expertise needed (critical security endpoint)
- Agent consistently fails for specific story type

### 2. Review Execution Logs

After implementation:
- Check `.specify/logs/` for any FALLBACK or RETRY entries
- Investigate why specialist failed
- Update agent assignments if pattern emerges

### 3. Keep Agents Updated

When adding new capabilities to agents:
- Update `description` field in frontmatter
- Routing logic uses description for keyword matching

### 4. One Story = One Agent

Each user story should map to single primary agent:
- ✅ Good: US1 (Login UI) → react-expert
- ❌ Bad: US1 (Full Stack Login) → react-expert + python-backend
- **Fix**: Split into US1 (UI) and US2 (API)

---

## Architecture Summary

```
Workflow:    /specify → /plan → /tasks → /implement
                          ↓        ↓         ↓
Agent Layer:          Routing   Hints    Execution
                          ↓        ↓         ↓
Agents:            react-expert, python-backend, etc.
                          ↓        ↓         ↓
Output:               Code written directly to files
```

**Key Innovation**: Agents write code directly using Write/Edit tools, not just guidance.

---

## Support

### Documentation
- Full status: `.specify/AGENT_INTEGRATION_STATUS.md`
- This guide: `.specify/AGENT_INTEGRATION_GUIDE.md`

### Scripts
- Agent discovery: `.specify/scripts/bash/get-available-agents.sh`
- Routing logic: `.specify/scripts/bash/route-to-agent.sh`
- Context builder: `.specify/scripts/bash/build-agent-context.sh`

### Commands
- Plan generation: `.claude/commands/speckit.plan.md`
- Task generation: `.claude/commands/speckit.tasks.md`
- Implementation: `.claude/commands/speckit.implement.md`

**Ready to build! 🚀**
