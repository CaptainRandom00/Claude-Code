#!/usr/bin/env bash

# Agent Routing Script
# Matches tasks/stories to appropriate specialist agents based on:
# - File paths (.tsx → react-expert, .py → python-backend)
# - Domain keywords (API, database, mobile)
# - Tech stack (React, FastAPI, PostgreSQL)

set -e
set -u
set -o pipefail

#==============================================================================
# Configuration
#==============================================================================

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Input parameters
TECH_STACK=""
DOMAIN=""
STORY_TITLE=""
FILE_PATHS=""
JSON_OUTPUT=false

#==============================================================================
# Parse Arguments
#==============================================================================

while [ $# -gt 0 ]; do
    case "$1" in
        --tech-stack)
            TECH_STACK="$2"
            shift 2
            ;;
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --story-title)
            STORY_TITLE="$2"
            shift 2
            ;;
        --file-paths)
            FILE_PATHS="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 --tech-stack STACK --domain DOMAIN [--story-title TITLE] [--file-paths PATHS] [--json]" >&2
            exit 1
            ;;
    esac
done

#==============================================================================
# Routing Logic
#==============================================================================

route_by_file_paths() {
    local paths="$1"
    local agent=""
    local confidence="high"

    # Priority 1: File extensions
    if echo "$paths" | grep -qE '\.(tsx|jsx)'; then
        agent="react-expert"
    elif echo "$paths" | grep -qE '\.py' && echo "$TECH_STACK" | grep -qi "fastapi\|django\|flask"; then
        agent="python-backend"
    elif echo "$paths" | grep -qE '\.py'; then
        agent="python-backend"
    elif echo "$paths" | grep -qE '\.(ts|js)' && echo "$TECH_STACK" | grep -qi "node\|express\|fastify"; then
        agent="node-expert"
    elif echo "$paths" | grep -qE '\.(swift|m)'; then
        agent="mobile-expert"
    elif echo "$paths" | grep -qE '\.(kt|java)' && echo "$DOMAIN" | grep -qi "android\|mobile"; then
        agent="mobile-expert"
    elif echo "$paths" | grep -qE '\.sql|migration'; then
        agent="database-architect"
    elif echo "$paths" | grep -qE '\.php' && echo "$TECH_STACK" | grep -qi "wordpress"; then
        agent="wordpress-expert"
    fi

    echo "$agent"
}

route_by_domain() {
    local domain="$1"
    local title="$2"
    local combined="${domain,,} ${title,,}"  # Lowercase for matching
    local agent=""

    # Domain keyword matching
    if echo "$combined" | grep -qE 'api|endpoint|contract|rest|graphql'; then
        agent="api-architect"
    elif echo "$combined" | grep -qE 'database|schema|query|table|migration'; then
        agent="database-architect"
    elif echo "$combined" | grep -qE 'mobile|ios|android|app store'; then
        agent="mobile-expert"
    elif echo "$combined" | grep -qE 'ui|ux|design|component|layout'; then
        agent="react-expert"  # Default to React for UI work
    elif echo "$combined" | grep -qE 'realtime|websocket|socket\.io|sse|streaming'; then
        agent="realtime-systems"
    elif echo "$combined" | grep -qE 'cloud|aws|azure|gcp|infrastructure|deployment'; then
        agent="cloud-architect"
    elif echo "$combined" | grep -qE 'data pipeline|etl|analytics|bi|warehouse'; then
        agent="data-engineer"
    elif echo "$combined" | grep -qE 'test|qa|quality|validation'; then
        agent="qa-engineer"
    elif echo "$combined" | grep -qE 'security|auth|encryption|vulnerability'; then
        agent="security-auditor"
    elif echo "$combined" | grep -qE 'wordpress|woocommerce|cms'; then
        agent="wordpress-expert"
    elif echo "$combined" | grep -qE 'seo|search optimization'; then
        agent="seo-strategist"
    elif echo "$combined" | grep -qE 'devops|ci/cd|pipeline|deployment'; then
        agent="devops-web"
    fi

    echo "$agent"
}

route_by_tech_stack() {
    local stack="$1"
    local stack_lower="${stack,,}"
    local agent=""

    # Tech stack matching (fallback)
    if echo "$stack_lower" | grep -qE 'react|next\.js|gatsby'; then
        agent="react-expert"
    elif echo "$stack_lower" | grep -qE 'fastapi|django|flask|python'; then
        agent="python-backend"
    elif echo "$stack_lower" | grep -qE 'node|express|fastify|nestjs'; then
        agent="node-expert"
    elif echo "$stack_lower" | grep -qE 'postgresql|mysql|mongodb|redis'; then
        agent="database-architect"
    elif echo "$stack_lower" | grep -qE 'aws|azure|gcp|cloud'; then
        agent="cloud-architect"
    elif echo "$stack_lower" | grep -qE 'react native|flutter|swift|kotlin'; then
        agent="mobile-expert"
    elif echo "$stack_lower" | grep -qE 'wordpress'; then
        agent="wordpress-expert"
    fi

    echo "$agent"
}

determine_supporting_agents() {
    local primary="$1"
    local supporting=""

    # Add supporting agents based on primary agent
    case "$primary" in
        react-expert)
            supporting="api-architect,qa-engineer"
            ;;
        python-backend|node-expert)
            supporting="api-architect,database-architect,qa-engineer"
            ;;
        api-architect)
            supporting="security-auditor,qa-engineer"
            ;;
        mobile-expert)
            supporting="api-architect,ui-designer,qa-engineer"
            ;;
        database-architect)
            supporting="data-engineer"
            ;;
        *)
            supporting="qa-engineer"
            ;;
    esac

    echo "$supporting"
}

#==============================================================================
# Main Routing
#==============================================================================

main() {
    local primary_agent=""
    local confidence="medium"
    local rationale=""

    # Priority 1: File paths (most specific)
    if [ -n "$FILE_PATHS" ]; then
        primary_agent=$(route_by_file_paths "$FILE_PATHS")
        if [ -n "$primary_agent" ]; then
            confidence="high"
            rationale="File path analysis: $FILE_PATHS matches $primary_agent specialization"
        fi
    fi

    # Priority 2: Domain keywords
    if [ -z "$primary_agent" ] && [ -n "$DOMAIN$STORY_TITLE" ]; then
        primary_agent=$(route_by_domain "$DOMAIN" "$STORY_TITLE")
        if [ -n "$primary_agent" ]; then
            confidence="high"
            rationale="Domain analysis: Keywords match $primary_agent specialization"
        fi
    fi

    # Priority 3: Tech stack (fallback)
    if [ -z "$primary_agent" ] && [ -n "$TECH_STACK" ]; then
        primary_agent=$(route_by_tech_stack "$TECH_STACK")
        if [ -n "$primary_agent" ]; then
            confidence="medium"
            rationale="Tech stack match: $TECH_STACK suggests $primary_agent"
        fi
    fi

    # Final fallback: general-purpose
    if [ -z "$primary_agent" ]; then
        primary_agent="general-purpose"
        confidence="low"
        rationale="No specific match found, using general-purpose agent"
    fi

    # Determine supporting agents
    local supporting_agents=$(determine_supporting_agents "$primary_agent")

    # Output
    if [ "$JSON_OUTPUT" = true ]; then
        cat <<EOF
{
  "primary_agent": "$primary_agent",
  "supporting_agents": ["${supporting_agents//,/\", \"}"],
  "confidence": "$confidence",
  "rationale": "$rationale"
}
EOF
    else
        echo "Primary Agent: $primary_agent"
        echo "Supporting Agents: $supporting_agents"
        echo "Confidence: $confidence"
        echo "Rationale: $rationale"
    fi
}

main
