# Ponytail for Vibe Code (Mistral)

Makes Vibe Code think like the laziest senior dev in the room: the smallest
change that fully solves the task, and a reply a busy human understands in one
read. Port of [Ponytail](https://github.com/DietrichGebert/ponytail) (MIT) to
Vibe Code's plugin format.

## Install

Requires `node` on PATH (the session hooks are Node.js; skills work without it,
but the level would not persist between prompts).

```bash
# user-level (every project)
mkdir -p ~/.vibe/plugins && cp -r ponytail ~/.vibe/plugins/

# or project-level (this project only, in a trusted folder)
mkdir -p ./.vibe/plugins && cp -r ponytail ./.vibe/plugins/
```

Then run `/plugins` in Vibe Code (`/reload-plugins` in a running session) and
start a new session. Check with `/skills`: the six skills appear as
`/ponytail:ponytail`, `/ponytail:ponytail-review`, `/ponytail:ponytail-audit`,
`/ponytail:ponytail-debt`, `/ponytail:ponytail-gain`, `/ponytail:ponytail-help`.

## How it behaves in Vibe

- **Session start**: the `session_start` hook injects the Ponytail ruleset,
  filtered to the active level, plus a map of the codebase's existing helpers
  and components (so "reuse first" costs no search).
- **Levels**: `/ponytail:ponytail ultra` (or `lite`, `full`) switches the level
  for the session; a `pre_agent` hook tracks the switch and injects the new
  level's ruleset. `/ponytail default ultra` persists the default across
  restarts (`~/.config/ponytail/config.json`, shared with the Claude Code and
  Codex ports). "stop ponytail" or "normal mode" (typed alone) turns it off.
- **Subagents**: each subagent carries the ruleset too, injected on its first
  turn per session.
- **One-shot skills**: review, audit, debt, gain and help change nothing and
  persist nothing.

### Commands

| Command | Effect |
|---------|--------|
| `/ponytail:ponytail` | Report the level, or switch ponytail on |
| `/ponytail:ponytail lite\|full\|ultra` | Switch level for this session |
| `/ponytail:ponytail off` | Ponytail off for this session |
| `/ponytail:ponytail default <level>` | Persist the default (survives restarts) |
| `/ponytail:ponytail-review` | Quality review of a change |
| `/ponytail:ponytail-audit` | Quality audit of the whole repo |
| `/ponytail:ponytail-debt` | Ledger of `shortcut:` comments |
| `/ponytail:ponytail-gain` | Ponytail's measured savings |
| `/ponytail:ponytail-help` | Quick reference |

### Differences vs the Claude Code port

No statusline badge and no band (Vibe has no equivalent hook surface). The
ruleset, levels, default persistence, codebase map, subagent injection and all
six skills behave the same.

## Configuration

- `PONYTAIL_DEFAULT_MODE` env var, or `defaultMode` in
  `~/.config/ponytail/config.json`: `off` disables ponytail at startup, `full`
  is the default.
- `PONYTAIL_MAP=0` disables the codebase map; `PONYTAIL_MAP_CHARS` caps its
  size (default 2000).
- Live level state lives in Vibe's plugin data directory
  (`PLUGIN_DATA/state.json`), falling back to `~/.vibe/ponytail-data/state.json`.

## License

MIT, [Dietrich Gebert](https://github.com/DietrichGebert). Vibe Code port of
upstream commit `ebd8654` (v5.3.3).
