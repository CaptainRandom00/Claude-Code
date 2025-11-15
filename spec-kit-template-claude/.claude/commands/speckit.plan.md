---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
handoffs: 
  - label: Create Tasks
    agent: speckit.tasks
    prompt: Break the plan into tasks
    send: true
  - label: Create Checklist
    agent: speckit.checklist
    prompt: Create a checklist for the following domain...
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `.specify/scripts/bash/setup-plan.sh --json` from repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load context**: Read FEATURE_SPEC and `.specify/memory/constitution.md`. Load IMPL_PLAN template (already copied).

3. **Execute plan workflow**: Follow the structure in IMPL_PLAN template to:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section from constitution
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION)
   - Phase 1: Generate data-model.md, contracts/, quickstart.md
   - Phase 1: Update agent context by running the agent script
   - Re-evaluate Constitution Check post-design

4. **Stop and report**: Command ends after Phase 2 planning. Report branch, IMPL_PLAN path, and generated artifacts.

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Agent context update**:
   - Run `.specify/scripts/bash/update-agent-context.sh claude`
   - These scripts detect which AI agent is in use
   - Update the appropriate agent-specific context file
   - Add only new technology from current plan
   - Preserve manual additions between markers

**Output**: data-model.md, /contracts/*, quickstart.md, agent-specific file

### Phase 1.5: Agent Assignment (NEW)

**After Phase 1 completes and plan.md is written**:

1. **Extract technical context**:
   ```bash
   # Get tech stack from plan.md
   TECH_STACK=$(grep "^\*\*Language/Version\*\*:" "$IMPL_PLAN" | sed 's/.*: //')
   FRAMEWORK=$(grep "^\*\*Primary Dependencies\*\*:" "$IMPL_PLAN" | sed 's/.*: //')
   PROJECT_TYPE=$(grep "^\*\*Project Type\*\*:" "$IMPL_PLAN" | sed 's/.*: //')
   ```

2. **Load agent registry**:
   ```bash
   AGENT_REGISTRY=$(.specify/scripts/bash/get-available-agents.sh --json)
   ```

3. **Extract user stories from spec.md**:
   - Parse all "### User Story" sections
   - Extract: story ID (US1, US2...), title, priority
   - Identify file paths mentioned in acceptance criteria

4. **Route each user story to agents**:
   ```bash
   for each user_story in spec.md:
     # Determine domain from story title
     DOMAIN=$(echo "$story_title" | grep -o -E "frontend|backend|api|database|mobile" || echo "general")

     # Run routing
     ROUTE_RESULT=$(.specify/scripts/bash/route-to-agent.sh \
       --tech-stack "$TECH_STACK,$FRAMEWORK" \
       --domain "$DOMAIN" \
       --story-title "$story_title" \
       --json)

     # Extract recommendations
     PRIMARY=$(echo "$ROUTE_RESULT" | grep "primary_agent" | sed 's/.*: "\([^"]*\)".*/\1/')
     SUPPORTING=$(echo "$ROUTE_RESULT" | grep "supporting_agents" | sed 's/.*\[\(.*\)\].*/\1/')
     RATIONALE=$(echo "$ROUTE_RESULT" | grep "rationale" | sed 's/.*: "\([^"]*\)".*/\1/')

     # Store assignments
     story_assignments["$story_id"]="$PRIMARY|$SUPPORTING|$RATIONALE"
   done
   ```

5. **Check for user overrides**:
   ```bash
   if [ -f ".specify/agent-overrides.json" ]; then
     # Parse overrides and apply to story_assignments
     for override in overrides:
       story_assignments["$story_id"]="$override_agent|...|User override: $reason"
   fi
   ```

6. **Generate Agent Assignments section**:
   Using template from plan-template.md, create:
   ```markdown
   ## Agent Assignments

   > Auto-generated based on tech stack and user story analysis.

   ### User Story 1 - [Title] (Priority: P1)

   **Recommended Primary Agent**: `@react-expert`
   **Supporting Agents**: `@api-architect`, `@qa-engineer`

   **Rationale**: Frontend domain with .tsx files and React in tech stack

   **Task Distribution**:
   - `@react-expert`: UI components, state management, forms
   - `@api-architect`: API contract validation
   - `@qa-engineer`: Component tests, integration scenarios

   **Coordination Notes**: api-architect defines contracts → react-expert implements → qa-engineer validates

   ---

   [Repeat for each user story...]

   ## Agent Override Mechanism

   To override assignments, create `.specify/agent-overrides.json`:
   ```json
   {
     "US1": {"primary_agent": "mobile-expert", "reason": "..."}
   }
   ```
   ```

7. **Append to plan.md**:
   - Read existing plan.md content
   - Append Agent Assignments section after Project Structure
   - Preserve all existing content
   - Write back to plan.md

8. **Validate agent assignments**:
   ```bash
   for agent in all_assigned_agents:
     if ! .specify/scripts/bash/get-available-agents.sh | grep -q "$agent"; then
       echo "WARNING: Agent $agent not found in registry"
       echo "  Available agents: [list]"
       echo "  Falling back to general-purpose for this story"
   fi
   ```

**Output**: Updated plan.md with Agent Assignments section

## Key rules

- Use absolute paths
- ERROR on gate failures or unresolved clarifications
