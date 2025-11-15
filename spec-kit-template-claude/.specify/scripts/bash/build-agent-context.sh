#!/usr/bin/env bash

# Agent Context Builder
# Generates tiered, token-efficient context packages for agent invocation

set -e
set -u
set -o pipefail

#==============================================================================
# Configuration
#==============================================================================

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Input parameters
STORY_ID=""
AGENT_TYPE=""
FEATURE_DIR=""
JSON_OUTPUT=false
MAX_TOKENS=4000

#==============================================================================
# Parse Arguments
#==============================================================================

while [ $# -gt 0 ]; do
    case "$1" in
        --story-id)
            STORY_ID="$2"
            shift 2
            ;;
        --agent-type)
            AGENT_TYPE="$2"
            shift 2
            ;;
        --feature-dir)
            FEATURE_DIR="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --max-tokens)
            MAX_TOKENS="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$STORY_ID" ] || [ -z "$AGENT_TYPE" ] || [ -z "$FEATURE_DIR" ]; then
    echo "Error: Missing required parameters" >&2
    echo "Usage: $0 --story-id ID --agent-type TYPE --feature-dir DIR [--json] [--max-tokens N]" >&2
    exit 1
fi

#==============================================================================
# Context Extraction Functions
#==============================================================================

extract_feature_name() {
    local spec_file="$FEATURE_DIR/spec.md"
    if [ -f "$spec_file" ]; then
        # Extract from first markdown header
        grep -m 1 '^# ' "$spec_file" | sed 's/^# //' | sed 's/Feature Specification: //'
    else
        echo "Unknown Feature"
    fi
}

extract_user_story() {
    local spec_file="$FEATURE_DIR/spec.md"
    local story_id="$1"

    if [ ! -f "$spec_file" ]; then
        echo "{}"
        return
    fi

    # Extract the user story section
    # This is a simplified extraction - in production, would use more robust parsing
    local story_section=$(awk "/### User Story.*$story_id/,/^---$|^###/" "$spec_file" | head -30)

    if [ -z "$story_section" ]; then
        echo "{}"
        return
    fi

    # Extract title
    local title=$(echo "$story_section" | grep -m 1 "^### User Story" | sed "s/.*- //; s/ (Priority.*//" || echo "")

    # Extract acceptance criteria (simplified)
    local criteria=$(echo "$story_section" | grep "^\*\*Given\|^\*\*When\|^\*\*Then\|^1\. \*\*Given" | head -5 | sed 's/^/    /' || echo "")

    cat <<EOF
{
  "id": "$story_id",
  "title": "$title",
  "acceptance_criteria": $(echo "$criteria" | sed 's/"/\\"/g' | awk 'BEGIN{print "["} {printf "\"%s\",\n", $0} END{print "\"end\"]"}' | sed '$ s/,$//')
}
EOF
}

extract_tech_stack() {
    local plan_file="$FEATURE_DIR/plan.md"

    if [ ! -f "$plan_file" ]; then
        echo "{}"
        return
    fi

    # Extract tech stack from Technical Context section
    local lang=$(grep "^\*\*Language/Version\*\*:" "$plan_file" | sed 's/.*: //' | sed 's/ or.*//' || echo "")
    local framework=$(grep "^\*\*Primary Dependencies\*\*:" "$plan_file" | sed 's/.*: //' | sed 's/,.*//' || echo "")
    local storage=$(grep "^\*\*Storage\*\*:" "$plan_file" | sed 's/.*: //' | sed 's/,.*//' || echo "")

    cat <<EOF
{
  "language": "$lang",
  "framework": "$framework",
  "storage": "$storage"
}
EOF
}

extract_constitution_rules() {
    local constitution_file="$FEATURE_DIR/../../.specify/memory/constitution.md"

    if [ ! -f "$constitution_file" ]; then
        echo "[]"
        return
    fi

    # Extract key principles (simplified - gets headers)
    grep "^### " "$constitution_file" | sed 's/^### //' | head -5 | \
        awk 'BEGIN{print "["} {printf "\"%s\",\n", $0} END{print "\"end\"]"}' | sed '$ s/,$//'
}

extract_entities() {
    local data_model_file="$FEATURE_DIR/data-model.md"

    if [ ! -f "$data_model_file" ]; then
        echo "[]"
        return
    fi

    # Extract entity names (simplified)
    grep "^## Entity:" "$data_model_file" | sed 's/^## Entity: //' | \
        awk 'BEGIN{print "["} {printf "{\"name\": \"%s\"},\n", $0} END{print "{}]"}' | sed '$ s/,$//'
}

extract_contracts() {
    local contracts_dir="$FEATURE_DIR/contracts"

    if [ ! -d "$contracts_dir" ]; then
        echo "{}"
        return
    fi

    # List contract files (simplified)
    find "$contracts_dir" -name "*.yaml" -o -name "*.json" 2>/dev/null | \
        awk 'BEGIN{print "{"} {printf "\"%s\": \"See file\",\n", $0} END{print "\"end\": \"end\"}"}' | sed '$ s/,$//'
}

#==============================================================================
# Tier-Based Context Building
#==============================================================================

build_tier1_context() {
    # Essential context (always included, ~1000 tokens)
    local feature_name=$(extract_feature_name)
    local user_story=$(extract_user_story "$STORY_ID")
    local tech_stack=$(extract_tech_stack)
    local constitution=$(extract_constitution_rules)

    cat <<EOF
{
  "feature_name": "$feature_name",
  "user_story": $user_story,
  "tech_stack": $tech_stack,
  "constitution_rules": $constitution
}
EOF
}

build_tier2_context() {
    # Domain-specific context (~1500 tokens)
    local agent_type="$1"

    case "$agent_type" in
        database-architect|api-architect|data-engineer)
            local entities=$(extract_entities)
            local contracts=$(extract_contracts)
            cat <<EOF
{
  "entities": $entities,
  "contracts": $contracts
}
EOF
            ;;
        react-expert|python-backend|node-expert|mobile-expert)
            local contracts=$(extract_contracts)
            cat <<EOF
{
  "contracts": $contracts
}
EOF
            ;;
        *)
            echo "{}"
            ;;
    esac
}

build_tier3_context() {
    # Integration context (only for multi-agent stories, ~1000 tokens)
    # Simplified for now - would include agent handoffs, dependencies
    echo "{}"
}

#==============================================================================
# Main Context Builder
#==============================================================================

main() {
    # Build Tier 1 (essential)
    local tier1=$(build_tier1_context)
    local current_tokens=$(count_tokens "$tier1")

    # Build Tier 2 if under budget
    local tier2="{}"
    if [ $current_tokens -lt 3000 ]; then
        tier2=$(build_tier2_context "$AGENT_TYPE")
        current_tokens=$(count_tokens "$tier1$tier2")
    fi

    # Build Tier 3 if still under budget
    local tier3="{}"
    if [ $current_tokens -lt 3500 ]; then
        tier3=$(build_tier3_context)
    fi

    # Merge contexts (simplified JSON merge)
    local full_context="$tier1"

    # Add token metadata
    cat <<EOF
{
  "context_tier": "full",
  "token_count": $current_tokens,
  "tier1": $tier1,
  "tier2": $tier2,
  "tier3": $tier3,
  "feature_dir": "$FEATURE_DIR"
}
EOF
}

main
