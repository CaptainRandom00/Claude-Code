#!/usr/bin/env bash

# Agent Discovery Script
# Scans agent directory and builds a JSON registry of available agents
# with their metadata (name, description, type, model)

set -e
set -u
set -o pipefail

#==============================================================================
# Configuration
#==============================================================================

# Determine Claude config directory
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
AGENTS_DIR="$CLAUDE_DIR/agents"

# Output mode
JSON_OUTPUT=false
if [ "${1:-}" = "--json" ]; then
    JSON_OUTPUT=true
fi

#==============================================================================
# Dependency Checks
#==============================================================================

check_dependencies() {
    local missing_deps=()

    # Check for required commands
    for cmd in awk sed grep; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}" >&2
        echo "Please install the missing tools and try again" >&2
        exit 1
    fi
}

#==============================================================================
# Agent Parsing Functions
#==============================================================================

parse_agent_frontmatter() {
    local agent_file="$1"
    local agent_name=$(basename "$agent_file" .md)

    # Extract frontmatter between --- markers
    local frontmatter=$(awk '/^---$/{flag=!flag; next} flag' "$agent_file" | head -20)

    # Extract required fields
    local name=$(echo "$frontmatter" | grep '^name:' | sed 's/name:[[:space:]]*//' | tr -d '"')
    local description=$(echo "$frontmatter" | grep '^description:' | sed 's/description:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
    local type=$(echo "$frontmatter" | grep '^type:' | sed 's/type:[[:space:]]*//' | tr -d '"')
    local model=$(echo "$frontmatter" | grep '^model:' | sed 's/model:[[:space:]]*//' | tr -d '"')

    # Validate required fields
    if [ -z "$name" ]; then
        echo "Warning: Agent file $agent_file missing 'name' field in frontmatter" >&2
        return 1
    fi

    if [ -z "$description" ]; then
        echo "Warning: Agent $name missing 'description' field in frontmatter" >&2
        return 1
    fi

    # Use defaults for optional fields
    type="${type:-general}"
    model="${model:-sonnet}"

    # Output JSON object
    cat <<EOF
{
  "name": "$name",
  "description": "$description",
  "type": "$type",
  "model": "$model",
  "file_path": "$agent_file"
}
EOF
    return 0
}

#==============================================================================
# Main Registry Builder
#==============================================================================

build_agent_registry() {
    # Check if agents directory exists
    if [ ! -d "$AGENTS_DIR" ]; then
        echo "Error: Agents directory not found: $AGENTS_DIR" >&2
        exit 1
    fi

    # Find all agent markdown files
    local agent_files=()
    while IFS= read -r -d '' file; do
        agent_files+=("$file")
    done < <(find "$AGENTS_DIR" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)

    if [ ${#agent_files[@]} -eq 0 ]; then
        echo "Warning: No agent files found in $AGENTS_DIR" >&2
        echo '{"agents": {}, "agent_count": 0, "types": {}}'
        return 0
    fi

    # Build agents object and type groupings
    local agents_json=""
    local type_groups=""
    local valid_count=0

    # Arrays to track types and their agents (bash 3 compatible)
    local -a seen_types=()
    local -a type_agents=()

    for agent_file in "${agent_files[@]}"; do
        # Parse agent frontmatter
        if agent_json=$(parse_agent_frontmatter "$agent_file" 2>/dev/null); then
            agent_name=$(echo "$agent_json" | grep '"name"' | sed 's/.*"name": "\([^"]*\)".*/\1/')
            agent_type=$(echo "$agent_json" | grep '"type"' | sed 's/.*"type": "\([^"]*\)".*/\1/')

            # Add to agents object
            if [ -n "$agents_json" ]; then
                agents_json="$agents_json,"
            fi
            agents_json="$agents_json\"$agent_name\": $agent_json"

            # Track types for grouping (bash 3 compatible approach)
            local found=0
            local idx=0
            for t in "${seen_types[@]:-}"; do
                if [ "$t" = "$agent_type" ]; then
                    type_agents[$idx]="${type_agents[$idx]}, \"$agent_name\""
                    found=1
                    break
                fi
                ((idx++))
            done

            if [ $found -eq 0 ]; then
                seen_types+=("$agent_type")
                type_agents+=("\"$agent_name\"")
            fi

            ((valid_count++))
        fi
    done

    # Build type groupings JSON
    local idx=0
    for type in "${seen_types[@]:-}"; do
        if [ -n "$type_groups" ]; then
            type_groups="$type_groups,"
        fi
        type_groups="$type_groups\"$type\": [${type_agents[$idx]}]"
        ((idx++))
    done

    # Output complete registry
    cat <<EOF
{
  "agents": {
    $agents_json
  },
  "agent_count": $valid_count,
  "types": {
    $type_groups
  }
}
EOF
}

#==============================================================================
# Main Execution
#==============================================================================

check_dependencies

if [ "$JSON_OUTPUT" = true ]; then
    build_agent_registry
else
    # Human-readable output
    echo "Agent Registry"
    echo "=============="
    echo ""
    echo "Scanning: $AGENTS_DIR"
    echo ""

    registry=$(build_agent_registry)
    agent_count=$(echo "$registry" | grep '"agent_count"' | sed 's/.*: \([0-9]*\).*/\1/')

    echo "Found $agent_count agents:"
    echo ""

    # Extract and display agent names with types
    echo "$registry" | grep '"name":' | while read -r line; do
        name=$(echo "$line" | sed 's/.*"name": "\([^"]*\)".*/\1/')
        type=$(echo "$registry" | grep -A3 "\"$name\"" | grep '"type"' | sed 's/.*"type": "\([^"]*\)".*/\1/' | head -1)
        printf "  %-25s [%s]\n" "$name" "$type"
    done

    echo ""
    echo "Use --json flag for machine-readable output"
fi
