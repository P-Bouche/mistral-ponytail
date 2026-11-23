# mistral-ponytail

[Ponytail](https://github.com/DietrichGebert/ponytail) for [Vibe Code](https://docs.mistral.ai/vibe/code/cli/skills) (Mistral's open-source coding CLI). Ponytail makes your agent think like the laziest senior dev in the room: the smallest change that fully solves the task, and a reply a busy human understands in one read.

Port of upstream commit `ebd8654` (v5.3.3). MIT, (c) Dietrich Gebert — this repository only adapts the packaging for Vibe Code.

## What is here

```
ponytail/                    the plugin (Agent Plugins 1.0 + ai.mistral.vibe extension)
├── plugin.json              manifest
├── skills/                  the six upstream skills, unchanged
│   ├── ponytail/SKILL.md            (also: -review, -audit, -debt, -gain, -help)
└── ai.mistral.vibe/
    ├── hooks.toml           Vibe hook wiring
    └── hooks/               session_start + pre_agent hooks (Node.js)
install-ponytail-vibe.sh     self-contained installer (embeds the whole plugin)
tests/test-hooks.js          50 tests simulating Vibe hook payloads
```

## Install

Pick one:

```bash
# 1. git
git clone https://github.com/P-Bouche/mistral-ponytail.git /tmp/mistral-ponytail
mkdir -p ~/.vibe/plugins && cp -r /tmp/mistral-ponytail/ponytail ~/.vibe/plugins/

# 2. installer script (also: --project, --dir <path>, --uninstall)
bash install-ponytail-vibe.sh
```

Then run Vibe Code, `/plugins`, start a new session. Skills appear as
`/ponytail:ponytail` and `/ponytail:ponytail-review`, `-audit`, `-debt`, `-gain`, `-help`.

Hooks need `node` on PATH. Without it, skills still invoke fine; the level just does not persist across prompts.

## How the port maps

| Upstream (Claude Code) | Vibe Code |
|---|---|
| `skills/*/SKILL.md` | unchanged, same Agent Skills spec |
| `hooks.json` + `SessionStart` ruleset injection | `ai.mistral.vibe/hooks.toml` + `session_start` hook (`additional_context`) |
| `UserPromptSubmit` mode tracker | `pre_agent` hook (main agent) |
| `SubagentStart` subagent injection | `pre_agent` hook (once per session and agent) |
| `~/.config/ponytail/config.json` | same file, shared with Claude/Codex ports |
| statusline badge, band | not ported (no equivalent hook surface) |

Levels: `/ponytail:ponytail lite|full|ultra|off`, persistent default via
`/ponytail:ponytail default <level>` or `PONYTAIL_DEFAULT_MODE`. "stop ponytail"
typed alone turns it off for the session.

## Tested

`tests/test-hooks.js` runs 50 checks simulating the documented Vibe hook
contract (JSON on stdin, JSON on stdout): level filtering, session resume,
subagent injection, deactivation edge cases, corrupted stdin, fallback ruleset.
Run it with `node tests/test-hooks.js`. The plugin was not yet smoke-tested
inside a live Vibe CLI session; `/plugins` will confirm loading in yours.

## Upstream

This port exists to be proposed upstream: Ponytail already ships ports for ~20
agents and documents agent portability; `mistral-ponytail` follows the same
architecture.
