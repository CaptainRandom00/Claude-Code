---
description: Execute the implementation plan by processing and executing all tasks defined in tasks.md
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - For each checklist, count:
     - Total items: All lines matching `- [ ]` or `- [X]` or `- [x]`
     - Completed items: Lines matching `- [X]` or `- [x]`
     - Incomplete items: Lines matching `- [ ]`
   - Create a status table:

     ```text
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```

   - Calculate overall status:
     - **PASS**: All checklists have 0 incomplete items
     - **FAIL**: One or more checklists have incomplete items

   - **If any checklist is incomplete**:
     - Display the table with incomplete item counts
     - **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     - Wait for user response before continuing
     - If user says "no" or "wait" or "stop", halt execution
     - If user says "yes" or "proceed" or "continue", proceed to step 3

   - **If all checklists are complete**:
     - Display the table showing all checklists passed
     - Automatically proceed to step 3

3. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read research.md for technical decisions and constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios

4. **Project Setup Verification**:
   - **REQUIRED**: Create/verify ignore files based on actual project setup:

   **Detection & Creation Logic**:
   - Check if the following command succeeds to determine if the repository is a git repo (create/verify .gitignore if so):

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - Check if Dockerfile* exists or Docker in plan.md → create/verify .dockerignore
   - Check if .eslintrc* exists → create/verify .eslintignore
   - Check if eslint.config.* exists → ensure the config's `ignores` entries cover required patterns
   - Check if .prettierrc* exists → create/verify .prettierignore
   - Check if .npmrc or package.json exists → create/verify .npmignore (if publishing)
   - Check if terraform files (*.tf) exist → create/verify .terraformignore
   - Check if .helmignore needed (helm charts present) → create/verify .helmignore

   **If ignore file already exists**: Verify it contains essential patterns, append missing critical patterns only
   **If ignore file missing**: Create with full pattern set for detected technology

   **Common Patterns by Technology** (from plan.md tech stack):
   - **Node.js/JavaScript/TypeScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
   - **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
   - **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
   - **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
   - **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
   - **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
   - **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
   - **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
   - **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
   - **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
   - **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `Makefile`, `config.log`, `.idea/`, `*.log`, `.env*`
   - **Swift**: `.build/`, `DerivedData/`, `*.swiftpm/`, `Packages/`
   - **R**: `.Rproj.user/`, `.Rhistory`, `.RData`, `.Ruserdata`, `*.Rproj`, `packrat/`, `renv/`
   - **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

   **Tool-Specific Patterns**:
   - **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
   - **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
   - **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
   - **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`
   - **Kubernetes/k8s**: `*.secret.yaml`, `secrets/`, `.kube/`, `kubeconfig*`, `*.key`, `*.crt`

5. **Agent-Aware Implementation Setup** (NEW):

   a. **Load agent registry**:
      ```bash
      AGENT_REGISTRY=$(.specify/scripts/bash/get-available-agents.sh --json)
      AGENT_COUNT=$(echo "$AGENT_REGISTRY" | grep "agent_count" | sed 's/.*: \([0-9]*\).*/\1/')
      echo "Loaded $AGENT_COUNT available agents"
      ```

   b. **Initialize execution log**:
      ```bash
      mkdir -p .specify/logs
      LOG_FILE=".specify/logs/agent-execution-$(date +%Y%m%d-%H%M%S).log"
      echo "Agent Execution Log - $(date)" > "$LOG_FILE"
      echo "Feature: $(basename $FEATURE_DIR)" >> "$LOG_FILE"
      echo "==========================================" >> "$LOG_FILE"
      ```

   c. **Check for user overrides**:
      ```bash
      if [ -f ".specify/agent-overrides.json" ]; then
        echo "INFO: Loading agent overrides from .specify/agent-overrides.json"
        # Parse and apply overrides
      fi
      ```

6. **Parse tasks.md for agent-aware execution**:

   Extract from tasks.md:
   - **User story phases**: Identified by `## Phase N: User Story X`
   - **Agent assignments**: Extract `**Assigned Agent**: @agent-name` from each phase
   - **Supporting agents**: Extract `**Supporting Agents**: @agent1, @agent2`
   - **Tasks per phase**: All tasks with [USX] marker belong to that phase
   - **Phase order**: Sequential execution (Phase 1 → Phase 2 → Phase 3...)

   Build phase execution plan:
   ```
   Phase 1 (Setup): No agent, execute with general-purpose
   Phase 2 (Foundational): No agent, execute with general-purpose
   Phase 3 (US1): @react-expert, supporting: [@api-architect, @qa-engineer]
   Phase 4 (US2): @python-backend, supporting: [@database-architect]
   ...
   ```

7. **Agent-Aware Phase Execution Loop** (REPLACES old execution):

   **For each user story phase** (skip Setup/Foundational phases for now, execute normally):

   ### Step 1: Parse Phase Metadata
   ```markdown
   - story_id (e.g., "US1")
   - story_title (e.g., "User Login Flow")
   - assigned_agent (e.g., "react-expert")
   - supporting_agents (e.g., ["api-architect", "qa-engineer"])
   - tasks (list of task objects: ID, description, file_path)
   ```

   ### Step 2: Build Agent Context
   ```bash
   CONTEXT=$(.specify/scripts/bash/build-agent-context.sh \
     --story-id "$story_id" \
     --agent-type "$assigned_agent" \
     --feature-dir "$FEATURE_DIR" \
     --json)

   # Verify context generated successfully
   if [ -z "$CONTEXT" ]; then
     echo "ERROR: Failed to build context for $story_id"
     # Fall back to general-purpose
   fi
   ```

   ### Step 3: Invoke Primary Agent via Task Tool

   **Agent Prompt Structure**:
   ```
   You are implementing User Story: {story_id} - {story_title}

   **Your Role**: {assigned_agent}

   **Feature Context**:
   {context_from_build-agent-context.sh}

   **Tasks to Complete**:
   {tasks_for_this_phase}

   **Your Responsibilities**:
   1. Review the context above to understand:
      - Feature requirements and user story goals
      - Tech stack and architecture decisions
      - Data models and API contracts
      - Constitutional rules you must follow

   2. Complete each task in order:
      - Use the Write tool to create new files
      - Use the Edit tool to modify existing files
      - Use the Read tool to understand existing code before editing
      - Follow file paths exactly as specified in task descriptions

   3. Follow constitutional rules strictly:
      - Test-First: Write tests before implementation (if test tasks included)
      - Security: Validate all inputs, sanitize outputs
      - Simplicity: Use standard patterns, avoid over-engineering

   4. Implementation guidelines:
      - Write clean, well-documented code
      - Follow the tech stack conventions ({language}, {framework})
      - Create directory structure as needed
      - Ensure all imports and dependencies are correct

   5. Progress reporting:
      - After completing each task, briefly note what was done
      - If you encounter errors, explain the issue clearly
      - Mark tasks complete by updating tasks.md

   **Output Format**:
   After completing all tasks for this user story, provide:
   - Summary of files created
   - Summary of files modified
   - Any issues encountered
   - Status of task completion
   ```

   **Invoke agent**:
   ```
   Use Task tool:
     subagent_type: {assigned_agent}
     prompt: {formatted_prompt_above}
     description: "Implement {story_id} - {story_title}"
   ```

   ### Step 4: Error Handling (Retry-Fallback-Escalate)

   **Attempt 1**: Primary agent execution
   - **Success**:
     - Log: `[timestamp] {story_id} @{agent} SUCCESS (1 attempt, {duration}s)`
     - Mark phase complete
     - Continue to next phase

   - **Failure**:
     - Log: `[timestamp] {story_id} @{agent} RETRY (error: {error_summary})`
     - Capture error details
     - Proceed to Attempt 2

   **Attempt 2**: Retry with error context
   - Add to agent prompt: "Previous attempt failed with error: {error}. Please analyze and fix."
   - Invoke same agent again
   - **Success**:
     - Log: `[timestamp] {story_id} @{agent} SUCCESS (2 attempts, {duration}s)`
     - Mark phase complete
     - Continue

   - **Failure**:
     - Log: `[timestamp] {story_id} @{agent} FALLBACK (failed after 2 attempts)`
     - Proceed to Fallback

   **Fallback**: General-purpose agent
   - Log: `[timestamp] {story_id} Specialist {agent} failed, using general-purpose`
   - Invoke general-purpose agent with same context and tasks
   - **Success**:
     - Log: `[timestamp] {story_id} @general-purpose SUCCESS (fallback)`
     - Mark phase complete with warning
     - Continue

   - **Failure**:
     - Log: `[timestamp] {story_id} ESCALATION (all attempts failed)`
     - Proceed to Escalation

   **Escalation**: Invoke stuck agent
   ```
   Use Task tool:
     subagent_type: "stuck"
     prompt: """
       Story: {story_id} - {story_title}
       Assigned Agent: {agent_name} (failed after 2 attempts)
       Fallback Agent: general-purpose (also failed)
       Error Details: {error_summary}

       Context Summary:
       - Feature: {feature_name}
       - Tech Stack: {tech_stack}
       - Tasks Attempted: {task_count}

       User Options:
       A) Skip this user story and continue with next
       B) Assign different specialist agent (specify which)
       C) Stop implementation for manual debugging
       D) Retry with general-purpose agent one more time

       What would you like to do?
     """
   ```
   - stuck agent presents options to user
   - Wait for user decision
   - Execute based on user choice:
     - Option A: Mark phase as SKIPPED, continue
     - Option B: Invoke specified agent
     - Option C: Halt implementation, save state
     - Option D: Retry general-purpose once more

   **Agent Not Found**:
   - If assigned agent doesn't exist in registry:
     - Log: `[timestamp] {story_id} Agent {agent} not found, using general-purpose`
     - Skip directly to fallback (no retry needed)

   ### Step 5: Logging & Progress Tracking

   **Log each phase execution**:
   ```bash
   # Detailed log entry format
   cat >> "$LOG_FILE" <<EOF
   [{timestamp}] {story_id} @{assigned_agent} {status} ({attempt_count} attempts, {duration}s)
     Tasks: {completed}/{total}
     Files Created: {file_list}
     Files Modified: {file_list}
   EOF
   ```

   **Update tasks.md after phase completion**:
   - Read tasks.md
   - For each completed task in this phase:
     - Replace `- [ ]` with `- [X]`
   - Save tasks.md

8. **Non-Agent Phases** (Setup, Foundational, Polish):

   Execute these phases with current implementation logic:
   - **Setup Phase**: Project initialization, dependencies
   - **Foundational Phase**: Blocking prerequisites
   - **Polish Phase**: Cross-cutting concerns, documentation

   These phases don't have agent assignments, so use existing execution flow.

9. **Post-Implementation Report**:

   Generate summary:
   ```markdown
   ## Implementation Complete

   **Phases Executed**: {completed_count}/{total_count}
   **Total Tasks**: {completed_tasks} completed, {skipped_tasks} skipped

   **Agent Performance**:
   - react-expert: {task_count} tasks (100% success)
   - python-backend: {task_count} tasks (1 retry, 1 fallback)
   - database-architect: {task_count} tasks (100% success)
   - general-purpose: {task_count} tasks (fallback mode)

   **Execution Log**: {log_file_path}

   **Files Modified**:
   - Created: {created_count} files
   - Modified: {modified_count} files

   **Next Steps**:
   - Run tests: {test_command}
   - Review changes: git diff
   - Commit: git add . && git commit -m "Implement {feature_name}"
   ```

Note: This agent-aware implementation orchestrates specialist agents for each user story while maintaining fallback to general-purpose execution for robustness.
