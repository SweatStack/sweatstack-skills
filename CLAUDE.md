# SweatStack Skills

Agent Skill for building apps with [SweatStack](https://sweatstack.no), the sports data platform.

## Structure

```
sweatstack/
├── SKILL.md    # Entry point - triggers on SweatStack-related prompts
├── webapp.md   # Single-file HTML patterns, styling, branding, deployment
├── auth.md     # OAuth2/PKCE flows, tokens, redirect URIs
├── cli.md      # SweatStack CLI: app management and deployment
└── api.md      # Endpoints, data formats, Parquet handling
```

`SKILL.md` is lean (~20 lines) and links to guides. Claude loads guides on-demand based on the task.

## How Skills Work

Skills use progressive disclosure to manage context efficiently:

1. **Metadata** (`name` + `description`): Always loaded. Claude uses this to decide whether to activate the skill.
2. **SKILL.md body**: Loaded when the skill triggers.
3. **Reference files**: Loaded only when Claude needs them for the task.

This means the `description` field is critical - it's the trigger mechanism. Include what the skill does and keywords that should activate it.

## Size Constraints

| Component | Limit | Rationale |
|-----------|-------|-----------|
| `name` | 64 chars, lowercase + hyphens, must match directory | Consistency, URL-safe |
| `description` | 1024 chars | Always in context; be comprehensive but tight |
| SKILL.md body | <500 lines | Loaded on trigger; keep it a routing layer |
| Reference files | Add TOC if >100 lines | Helps Claude navigate large files |

## Writing Guidelines

**Be concise.** Claude is smart. Only add context Claude doesn't already have. Skip explanations of common concepts; focus on what's specific to SweatStack.

**Use imperative form.** "Create the auth flow" not "You should create the auth flow."

**Match detail to risk.** Flexible guidance for open-ended tasks; exact code for fragile operations like OAuth flows or token handling.

**Keep SKILL.md as a router.** Quick reference info and links to guides. Detailed content lives in the guides themselves.

**One topic per guide.** If a guide grows to cover multiple concerns, split it.

**Link flat, not nested.** Reference files link from `SKILL.md`, not from each other.

**No time-sensitive content.** Avoid "after August 2025, use X" - skills should remain accurate over time.

## What NOT to Include

Skills contain only what Claude needs. Don't add:
- README, CHANGELOG, or INSTALLATION docs inside the skill folder
- User-facing documentation (that's what the repo README is for)
- Setup/testing procedures for humans
- Explanations of concepts Claude already knows

## Editing the Skill

**Add to existing guides** when content fits their scope:
- HTML structure, styling, branding → `webapp.md`; OAuth/token flows → `auth.md`
- Endpoints, data models, Parquet → `api.md`

**Create a new guide** when:
- Content doesn't fit existing guides
- The topic is substantial enough to warrant its own file

When adding a new guide:
1. Create `sweatstack/new-guide.md`
2. Add a link from `SKILL.md` with clear context on when to read it

**Scripts**: For deterministic, repeatable operations. Create `sweatstack/scripts/` if needed. Scripts can be executed without loading into context, saving tokens.

**Assets**: For templates or files used in output (not loaded into context). Create `sweatstack/assets/` if needed.

## Testing

```bash
# Install locally
curl -LsSf https://sweatstack.no/install-skills | sh

# Or symlink for development
ln -s $(pwd)/sweatstack ~/.claude/skills/sweatstack
```

Test prompts that should trigger the skill:
- "Build me a SweatStack app that shows my activities"
- "Create a heart rate zone calculator with SweatStack"
- "How do I authenticate with SweatStack?"

Watch for:
- Does the skill trigger on expected prompts?
- Does Claude load the right guide for the task?
- Is Claude missing information that should be in a guide?

## Reference

- [Agent Skills Spec](https://agentskills.io/specification) - Format and frontmatter fields
- [Authoring Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) - Comprehensive writing guide
