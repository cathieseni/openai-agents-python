# Issue Triage Skill

Automatically triages new GitHub issues by analyzing content, applying labels, assigning priority, and routing to appropriate team members.

## Overview

This skill monitors incoming issues and performs initial triage to keep the issue tracker organized and ensure issues reach the right people quickly.

## Capabilities

- Analyzes issue title and body to determine category (bug, feature request, question, documentation)
- Applies appropriate labels based on content analysis
- Assigns priority labels (P0-critical, P1-high, P2-medium, P3-low)
- Identifies affected components (agents, tools, tracing, streaming, etc.)
- Checks for duplicate issues and links them
- Requests missing information (reproduction steps, version, OS) via comment
- Assigns issues to relevant maintainers based on component ownership

## Trigger

Runs automatically when:
- A new issue is opened
- An issue is reopened
- Manually triggered via workflow dispatch

## Labels Applied

### Type Labels
- `bug` — Something isn't working
- `enhancement` — New feature or request
- `question` — Further information is requested
- `documentation` — Improvements or additions to documentation
- `performance` — Performance related issues

### Priority Labels
- `P0-critical` — Production breaking, security issue
- `P1-high` — Major functionality broken
- `P2-medium` — Important but has workaround
- `P3-low` — Nice to have

### Component Labels
- `component:agents` — Core agent functionality
- `component:tools` — Tool definitions and execution
- `component:tracing` — Tracing and observability
- `component:streaming` — Streaming responses
- `component:handoffs` — Agent handoff logic
- `component:guardrails` — Input/output guardrails

## Configuration

The skill uses an AI model to analyze issue content and make triage decisions. Configuration is in `agents/openai.yaml`.

## Outputs

- Labels applied to the issue
- Comment posted if information is missing
- Issue assigned to component owner (if deterministic match found)
- Duplicate issue linked in comment (if found)
