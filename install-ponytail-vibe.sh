
#!/usr/bin/env bash
# install-ponytail-vibe.sh — install the Ponytail plugin for Vibe Code (Mistral).
#
# Port of https://github.com/DietrichGebert/ponytail (MIT, by Dietrich Gebert)
# to Vibe Code's plugin format (Agent Plugins 1.0 + ai.mistral.vibe extension).
# Self-contained: embeds the whole plugin, needs nothing but bash.
# Run it in bash (Git Bash on Windows works too).
#
# Files that contain Markdown fences (README.md, ponytail-help, ponytail-gain)
# ride along base64-encoded, one line per file, so the installer stays
# copy-paste safe; everything else is emitted as a readable heredoc.
#
# Usage:
#   bash install-ponytail-vibe.sh                # user-level:  ~/.vibe/plugins/ponytail
#   bash install-ponytail-vibe.sh --project      # project dir: ./.vibe/plugins/ponytail
#   bash install-ponytail-vibe.sh --dir <path>   # custom plugin dir
#   bash install-ponytail-vibe.sh --uninstall [--project]
#
# After install: run Vibe Code, then /plugins (or /reload-plugins in a running
# session) and start a new session. Exposed skills: /ponytail:ponytail,
# /ponytail:ponytail-review, -audit, -debt, -gain, -help.
#
# Hooks need `node` on PATH. Without node, skills still invoke fine; the level
# just does not persist across prompts.

set -euo pipefail

# GNU coreutils says -d, BSD/macOS says -D.
if base64 -d </dev/null >/dev/null 2>&1; then B64D="base64 -d"; else B64D="base64 -D"; fi

DEST=""
PROJECT=0
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --project)   PROJECT=1 ;;
    --user)      PROJECT=0 ;;
    --uninstall) UNINSTALL=1 ;;
    --dir)       shift; DEST="${1:?--dir needs a path}" ;;
    -h|--help)   grep '^#' "$0" | sed -n '2,24p'; exit 0 ;;
    *)           echo "unknown option: $1 (try --help)" >&2; exit 2 ;;
  esac
  shift
done

if [ -z "$DEST" ]; then
  if [ "$PROJECT" = "1" ]; then DEST="./.vibe/plugins/ponytail"; else DEST="$HOME/.vibe/plugins/ponytail"; fi
fi

if [ "$UNINSTALL" = "1" ]; then
  rm -rf "$DEST"
  echo "Removed: $DEST"
  echo "Run /reload-plugins (or restart Vibe Code) to finish."
  exit 0
fi

mkdir -p "$DEST"

mkdir -p "$(dirname "$DEST/LICENSE")"
cat > "$DEST/LICENSE" <<'PONYTAIL_FILE_EOF_a41c7'
MIT License

Copyright (c) 2026 DietrichGebert

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
PONYTAIL_FILE_EOF_a41c7
mkdir -p "$(dirname "$DEST/README.md")"
# README.md: base64, one line (contains Markdown fences)
$B64D > "$DEST/README.md" <<'PONYTAIL_FILE_EOF_a41c7'
IyBQb255dGFpbCBmb3IgVmliZSBDb2RlIChNaXN0cmFsKQoKTWFrZXMgVmliZSBDb2RlIHRoaW5rIGxpa2UgdGhlIGxhemllc3Qgc2VuaW9yIGRldiBpbiB0aGUgcm9vbTogdGhlIHNtYWxsZXN0CmNoYW5nZSB0aGF0IGZ1bGx5IHNvbHZlcyB0aGUgdGFzaywgYW5kIGEgcmVwbHkgYSBidXN5IGh1bWFuIHVuZGVyc3RhbmRzIGluIG9uZQpyZWFkLiBQb3J0IG9mIFtQb255dGFpbF0oaHR0cHM6Ly9naXRodWIuY29tL0RpZXRyaWNoR2ViZXJ0L3Bvbnl0YWlsKSAoTUlUKSB0bwpWaWJlIENvZGUncyBwbHVnaW4gZm9ybWF0LgoKIyMgSW5zdGFsbAoKUmVxdWlyZXMgYG5vZGVgIG9uIFBBVEggKHRoZSBzZXNzaW9uIGhvb2tzIGFyZSBOb2RlLmpzOyBza2lsbHMgd29yayB3aXRob3V0IGl0LApidXQgdGhlIGxldmVsIHdvdWxkIG5vdCBwZXJzaXN0IGJldHdlZW4gcHJvbXB0cykuCgpgYGBiYXNoCiMgdXNlci1sZXZlbCAoZXZlcnkgcHJvamVjdCkKbWtkaXIgLXAgfi8udmliZS9wbHVnaW5zICYmIGNwIC1yIHBvbnl0YWlsIH4vLnZpYmUvcGx1Z2lucy8KCiMgb3IgcHJvamVjdC1sZXZlbCAodGhpcyBwcm9qZWN0IG9ubHksIGluIGEgdHJ1c3RlZCBmb2xkZXIpCm1rZGlyIC1wIC4vLnZpYmUvcGx1Z2lucyAmJiBjcCAtciBwb255dGFpbCAuLy52aWJlL3BsdWdpbnMvCmBgYAoKVGhlbiBydW4gYC9wbHVnaW5zYCBpbiBWaWJlIENvZGUgKGAvcmVsb2FkLXBsdWdpbnNgIGluIGEgcnVubmluZyBzZXNzaW9uKSBhbmQKc3RhcnQgYSBuZXcgc2Vzc2lvbi4gQ2hlY2sgd2l0aCBgL3NraWxsc2A6IHRoZSBzaXggc2tpbGxzIGFwcGVhciBhcwpgL3Bvbnl0YWlsOnBvbnl0YWlsYCwgYC9wb255dGFpbDpwb255dGFpbC1yZXZpZXdgLCBgL3Bvbnl0YWlsOnBvbnl0YWlsLWF1ZGl0YCwKYC9wb255dGFpbDpwb255dGFpbC1kZWJ0YCwgYC9wb255dGFpbDpwb255dGFpbC1nYWluYCwgYC9wb255dGFpbDpwb255dGFpbC1oZWxwYC4KCiMjIEhvdyBpdCBiZWhhdmVzIGluIFZpYmUKCi0gKipTZXNzaW9uIHN0YXJ0Kio6IHRoZSBgc2Vzc2lvbl9zdGFydGAgaG9vayBpbmplY3RzIHRoZSBQb255dGFpbCBydWxlc2V0LAogIGZpbHRlcmVkIHRvIHRoZSBhY3RpdmUgbGV2ZWwsIHBsdXMgYSBtYXAgb2YgdGhlIGNvZGViYXNlJ3MgZXhpc3RpbmcgaGVscGVycwogIGFuZCBjb21wb25lbnRzIChzbyAicmV1c2UgZmlyc3QiIGNvc3RzIG5vIHNlYXJjaCkuCi0gKipMZXZlbHMqKjogYC9wb255dGFpbDpwb255dGFpbCB1bHRyYWAgKG9yIGBsaXRlYCwgYGZ1bGxgKSBzd2l0Y2hlcyB0aGUgbGV2ZWwKICBmb3IgdGhlIHNlc3Npb247IGEgYHByZV9hZ2VudGAgaG9vayB0cmFja3MgdGhlIHN3aXRjaCBhbmQgaW5qZWN0cyB0aGUgbmV3CiAgbGV2ZWwncyBydWxlc2V0LiBgL3Bvbnl0YWlsIGRlZmF1bHQgdWx0cmFgIHBlcnNpc3RzIHRoZSBkZWZhdWx0IGFjcm9zcwogIHJlc3RhcnRzIChgfi8uY29uZmlnL3Bvbnl0YWlsL2NvbmZpZy5qc29uYCwgc2hhcmVkIHdpdGggdGhlIENsYXVkZSBDb2RlIGFuZAogIENvZGV4IHBvcnRzKS4gInN0b3AgcG9ueXRhaWwiIG9yICJub3JtYWwgbW9kZSIgKHR5cGVkIGFsb25lKSB0dXJucyBpdCBvZmYuCi0gKipTdWJhZ2VudHMqKjogZWFjaCBzdWJhZ2VudCBjYXJyaWVzIHRoZSBydWxlc2V0IHRvbywgaW5qZWN0ZWQgb24gaXRzIGZpcnN0CiAgdHVybiBwZXIgc2Vzc2lvbi4KLSAqKk9uZS1zaG90IHNraWxscyoqOiByZXZpZXcsIGF1ZGl0LCBkZWJ0LCBnYWluIGFuZCBoZWxwIGNoYW5nZSBub3RoaW5nIGFuZAogIHBlcnNpc3Qgbm90aGluZy4KCiMjIyBDb21tYW5kcwoKfCBDb21tYW5kIHwgRWZmZWN0IHwKfC0tLS0tLS0tLXwtLS0tLS0tLXwKfCBgL3Bvbnl0YWlsOnBvbnl0YWlsYCB8IFJlcG9ydCB0aGUgbGV2ZWwsIG9yIHN3aXRjaCBwb255dGFpbCBvbiB8CnwgYC9wb255dGFpbDpwb255dGFpbCBsaXRlXHxmdWxsXHx1bHRyYWAgfCBTd2l0Y2ggbGV2ZWwgZm9yIHRoaXMgc2Vzc2lvbiB8CnwgYC9wb255dGFpbDpwb255dGFpbCBvZmZgIHwgUG9ueXRhaWwgb2ZmIGZvciB0aGlzIHNlc3Npb24gfAp8IGAvcG9ueXRhaWw6cG9ueXRhaWwgZGVmYXVsdCA8bGV2ZWw+YCB8IFBlcnNpc3QgdGhlIGRlZmF1bHQgKHN1cnZpdmVzIHJlc3RhcnRzKSB8CnwgYC9wb255dGFpbDpwb255dGFpbC1yZXZpZXdgIHwgUXVhbGl0eSByZXZpZXcgb2YgYSBjaGFuZ2UgfAp8IGAvcG9ueXRhaWw6cG9ueXRhaWwtYXVkaXRgIHwgUXVhbGl0eSBhdWRpdCBvZiB0aGUgd2hvbGUgcmVwbyB8CnwgYC9wb255dGFpbDpwb255dGFpbC1kZWJ0YCB8IExlZGdlciBvZiBgc2hvcnRjdXQ6YCBjb21tZW50cyB8CnwgYC9wb255dGFpbDpwb255dGFpbC1nYWluYCB8IFBvbnl0YWlsJ3MgbWVhc3VyZWQgc2F2aW5ncyB8CnwgYC9wb255dGFpbDpwb255dGFpbC1oZWxwYCB8IFF1aWNrIHJlZmVyZW5jZSB8CgojIyMgRGlmZmVyZW5jZXMgdnMgdGhlIENsYXVkZSBDb2RlIHBvcnQKCk5vIHN0YXR1c2xpbmUgYmFkZ2UgYW5kIG5vIGJhbmQgKFZpYmUgaGFzIG5vIGVxdWl2YWxlbnQgaG9vayBzdXJmYWNlKS4gVGhlCnJ1bGVzZXQsIGxldmVscywgZGVmYXVsdCBwZXJzaXN0ZW5jZSwgY29kZWJhc2UgbWFwLCBzdWJhZ2VudCBpbmplY3Rpb24gYW5kIGFsbApzaXggc2tpbGxzIGJlaGF2ZSB0aGUgc2FtZS4KCiMjIENvbmZpZ3VyYXRpb24KCi0gYFBPTllUQUlMX0RFRkFVTFRfTU9ERWAgZW52IHZhciwgb3IgYGRlZmF1bHRNb2RlYCBpbgogIGB+Ly5jb25maWcvcG9ueXRhaWwvY29uZmlnLmpzb25gOiBgb2ZmYCBkaXNhYmxlcyBwb255dGFpbCBhdCBzdGFydHVwLCBgZnVsbGAKICBpcyB0aGUgZGVmYXVsdC4KLSBgUE9OWVRBSUxfTUFQPTBgIGRpc2FibGVzIHRoZSBjb2RlYmFzZSBtYXA7IGBQT05ZVEFJTF9NQVBfQ0hBUlNgIGNhcHMgaXRzCiAgc2l6ZSAoZGVmYXVsdCAyMDAwKS4KLSBMaXZlIGxldmVsIHN0YXRlIGxpdmVzIGluIFZpYmUncyBwbHVnaW4gZGF0YSBkaXJlY3RvcnkKICAoYFBMVUdJTl9EQVRBL3N0YXRlLmpzb25gKSwgZmFsbGluZyBiYWNrIHRvIGB+Ly52aWJlL3Bvbnl0YWlsLWRhdGEvc3RhdGUuanNvbmAuCgojIyBMaWNlbnNlCgpNSVQsIFtEaWV0cmljaCBHZWJlcnRdKGh0dHBzOi8vZ2l0aHViLmNvbS9EaWV0cmljaEdlYmVydCkuIFZpYmUgQ29kZSBwb3J0IG9mCnVwc3RyZWFtIGNvbW1pdCBgZWJkODY1NGAgKHY1LjMuMykuCg==
PONYTAIL_FILE_EOF_a41c7
mkdir -p "$(dirname "$DEST/ai.mistral.vibe/hooks/ponytail-activate.js")"
cat > "$DEST/ai.mistral.vibe/hooks/ponytail-activate.js" <<'PONYTAIL_FILE_EOF_a41c7'
#!/usr/bin/env node
// ponytail — Vibe Code session_start activation hook.
//
// Runs on every session start:
//   1. Resolves the level: startup/clear restart from the configured default,
//      resume/fork keep the live level (compact-style continuity).
//   2. Emits the ponytail ruleset, filtered to that level, as
//      hook_specific_output.additional_context so the model follows it from
//      the first message.
//   3. Appends the codebase map (what already exists, so "reuse first" costs
//      no search). Fail open: a stalled map never costs the rules.
//
// Hook contract (Vibe): UTF-8 JSON on stdin (session_id, source, agent_name,
// model, cwd...), JSON object on stdout, exit 0 = passthrough. "off" levels
// emit nothing.

const { execFileSync } = require('child_process');
const path = require('path');
const { clearMode, getDefaultMode, readMode, setMode } = require('./ponytail-config');
const { getPonytailInstructions } = require('./ponytail-instructions');

function writeOut(text) {
  try {
    process.stdout.write(text);
  } catch (e) {
    // Silent fail — stdout closed/EPIPE at hook exit must not surface as a hook failure
  }
}

function activate(mode, cwd) {
  if (mode === 'off') {
    clearMode();
    process.exit(0); // "off" emits nothing
  }

  // Write the live-mode flag first: the pre_agent subagent path reads it to
  // hand the ruleset to subagents. Best-effort — never block the session.
  try { setMode(mode); } catch (e) { /* best-effort */ }

  let output = getPonytailInstructions(mode);

  // Codebase map: 3 s budget, well inside the 10 s hook limit, so a stalled
  // map never costs the rules.
  if (process.env.PONYTAIL_MAP !== '0') {
    try {
      const map = execFileSync(process.execPath, [path.join(__dirname, 'ponytail-map.js')], {
        encoding: 'utf8', timeout: 3000, maxBuffer: 64 * 1024,
        stdio: ['ignore', 'pipe', 'ignore'], cwd: cwd || process.cwd(),
      }).trimEnd();
      if (map) output += '\n\n' + map;
    } catch (e) { /* no map */ }
  }

  writeOut(JSON.stringify({ hook_specific_output: { additional_context: output } }));
}

let input = '';
let done = false;

function finish() {
  if (done) return;
  done = true;
  let source = '';
  let cwd = '';
  try {
    // Strip UTF-8 BOM some shells prepend when piping (breaks JSON.parse)
    const payload = JSON.parse(input.replace(/^\uFEFF/, ''));
    source = payload.source;
    cwd = payload.cwd;
  } catch (e) {
    // No payload, or an unparseable one: treat it as a fresh session
  }
  // startup/clear: configured default. resume/fork: the live level ("off"
  // stays off). Mirrors the Claude Code SessionStart behaviour.
  const mode = (source === 'resume' || source === 'fork')
    ? (readMode() || 'off')
    : getDefaultMode();
  activate(mode, cwd);
}

process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => { input += chunk; });
// Never hang the session start: recover on stdin error, or after a short
// ref'd fallback, and start at the default level.
process.stdin.on('end', () => { finish(); process.exit(0); });
process.stdin.on('error', () => { finish(); process.exit(0); });
setTimeout(() => { finish(); process.exit(0); }, 1500);
PONYTAIL_FILE_EOF_a41c7
chmod +x "$DEST/ai.mistral.vibe/hooks/ponytail-activate.js"
mkdir -p "$(dirname "$DEST/ai.mistral.vibe/hooks/ponytail-config.js")"
cat > "$DEST/ai.mistral.vibe/hooks/ponytail-config.js" <<'PONYTAIL_FILE_EOF_a41c7'
#!/usr/bin/env node
// ponytail — shared configuration and state resolver, Vibe Code port.
//
// Default mode resolution order (shared with the other ponytail ports, so one
// config.json serves every agent on the machine):
//   1. PONYTAIL_DEFAULT_MODE environment variable
//   2. defaultMode field in $XDG_CONFIG_HOME/ponytail/config.json
//      (fallback: ~/.config/ponytail/config.json)
//   3. 'full'
//
// Live state (current level, subagents already carrying the ruleset) lives in
// the plugin data directory Vibe pins for us: PLUGIN_DATA when set, else
// ~/.vibe/ponytail-data as a best-effort location.

const fs = require('fs');
const path = require('path');
const os = require('os');

const DEFAULT_MODE = 'full';
const RUNTIME_MODES = ['off', 'lite', 'full', 'ultra'];

// ponytail: keep every state read/write best-effort. A full or corrupt state
// file must never block a hook: hooks keep the session running on failure.
function getStatePath() {
  const dir = process.env.PLUGIN_DATA
    ? process.env.PLUGIN_DATA
    : path.join(os.homedir(), '.vibe', 'ponytail-data');
  return path.join(dir, 'state.json');
}

function readState() {
  try {
    // Strip UTF-8 BOM some editors prepend on Windows (breaks JSON.parse)
    const raw = fs.readFileSync(getStatePath(), 'utf8').replace(/^\uFEFF/, '');
    const state = JSON.parse(raw);
    return state && typeof state === 'object' && !Array.isArray(state) ? state : {};
  } catch (e) {
    return {};
  }
}

function writeState(state) {
  try {
    fs.mkdirSync(path.dirname(getStatePath()), { recursive: true });
    fs.writeFileSync(getStatePath(), JSON.stringify(state, null, 2), 'utf8');
    return true;
  } catch (e) {
    return false; // best-effort: mode still applies to this session's injected context
  }
}

// Live mode flag. Missing flag means "no explicit level yet".
function readMode() {
  const mode = readState().mode;
  if (typeof mode !== 'string') return null;
  const normalized = mode.trim().toLowerCase();
  return RUNTIME_MODES.includes(normalized) ? normalized : null;
}

function setMode(mode) {
  const state = readState();
  state.mode = mode;
  writeState(state);
}

function clearMode() {
  const state = readState();
  delete state.mode;
  writeState(state);
}

// Subagent injection bookkeeping: which (session, agent) pairs already carry
// the ruleset. One entry per session keeps this small; sessions are pruned
// past SESSION_LIMIT so the file cannot grow without bound.
const SESSION_LIMIT = 30;

function noteInjectedAgent(sessionId, agentName) {
  const state = readState();
  if (sessionId) {
    const sessions = state.sessions && typeof state.sessions === 'object' ? state.sessions : {};
    const key = String(sessionId);
    const entry = Array.isArray(sessions[key]) ? sessions[key] : [];
    if (!entry.includes(agentName)) entry.push(agentName);
    sessions[key] = entry;
    const keys = Object.keys(sessions);
    if (keys.length > SESSION_LIMIT) {
      for (const k of keys.slice(0, keys.length - SESSION_LIMIT)) delete sessions[k];
    }
    state.sessions = sessions;
    writeState(state);
  }
}

function isInjectedAgent(sessionId, agentName) {
  const sessions = readState().sessions;
  if (!sessions || typeof sessions !== 'object') return false;
  const entry = sessions[String(sessionId)];
  return Array.isArray(entry) && entry.includes(agentName);
}

function normalizeMode(mode) {
  if (typeof mode !== 'string') return null;
  const normalized = mode.trim().toLowerCase();
  return RUNTIME_MODES.includes(normalized) ? normalized : null;
}

function getConfigDir() {
  if (process.env.XDG_CONFIG_HOME) {
    return path.join(process.env.XDG_CONFIG_HOME, 'ponytail');
  }
  return path.join(os.homedir(), '.config', 'ponytail');
}

function getConfigPath() {
  return path.join(getConfigDir(), 'config.json');
}

function getDefaultMode() {
  // 1. Environment variable (highest priority): a default must be a runtime
  // level, normalized so whitespace or casing still resolves.
  const envMode = normalizeMode(process.env.PONYTAIL_DEFAULT_MODE);
  if (envMode) return envMode;

  // 2. Config file, shared with the other ponytail ports
  try {
    const config = JSON.parse(fs.readFileSync(getConfigPath(), 'utf8').replace(/^\uFEFF/, ''));
    const configMode = normalizeMode(config.defaultMode);
    if (configMode) return configMode;
  } catch (e) {
    // Config file doesn't exist or is invalid — fall through
  }

  return DEFAULT_MODE; // 3. Default
}

// `/ponytail default <mode>` persists across restarts; only runtime levels are
// valid defaults.
function writeDefaultMode(mode) {
  const normalized = normalizeMode(mode);
  if (!normalized) return null;

  const configPath = getConfigPath();
  fs.mkdirSync(path.dirname(configPath), { recursive: true });
  let config = {};
  try {
    config = JSON.parse(fs.readFileSync(getConfigPath(), 'utf8').replace(/^\uFEFF/, ''));
    if (!config || typeof config !== 'object' || Array.isArray(config)) config = {};
  } catch (e) {}
  config.defaultMode = normalized;
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2), 'utf8');
  return normalized;
}

// "stop ponytail" / "normal mode" turn ponytail off, but only as a standalone
// command. Matching the phrase anywhere in the message would turn it off
// mid-task for ordinary requests like "add a normal mode toggle".
function isDeactivationCommand(text) {
  const t = String(text || '').trim().toLowerCase().replace(/[.!?\s]+$/, '');
  return t === 'stop ponytail' || t === 'normal mode';
}

module.exports = {
  DEFAULT_MODE,
  RUNTIME_MODES,
  clearMode,
  defaultMode: getDefaultMode,
  getDefaultMode,
  getConfigPath,
  getStatePath,
  isDeactivationCommand,
  isInjectedAgent,
  normalizeMode,
  noteInjectedAgent,
  readMode,
  setMode,
  writeDefaultMode,
};
PONYTAIL_FILE_EOF_a41c7
chmod +x "$DEST/ai.mistral.vibe/hooks/ponytail-config.js"
mkdir -p "$(dirname "$DEST/ai.mistral.vibe/hooks/ponytail-instructions.js")"
cat > "$DEST/ai.mistral.vibe/hooks/ponytail-instructions.js" <<'PONYTAIL_FILE_EOF_a41c7'
#!/usr/bin/env node
// Shared Ponytail instruction builder, Vibe Code port.
// Reads the skill body (the single source of truth) from the plugin's skills
// directory and filters it to the active intensity level.

const fs = require('fs');
const path = require('path');
const { DEFAULT_MODE, normalizeMode } = require('./ponytail-config');

const INDEPENDENT_MODES = new Set(['review']);

function getSkillPath() {
  const pluginRoot = process.env.PLUGIN_ROOT || path.join(__dirname, '..', '..');
  return path.join(pluginRoot, 'skills', 'ponytail', 'SKILL.md');
}

// shortcut: the level-specific rows are filtered by mode name; a body line no
// filter rule matches is prose and must be kept verbatim.
function filterSkillBodyForMode(body, mode) {
  const effectiveMode = normalizeMode(mode) || DEFAULT_MODE;
  const withoutFrontmatter = String(body || '').replace(/^---[\s\S]*?---\s*/, '');

  return withoutFrontmatter
    .split(/\r?\n/)
    .filter((line) => {
      const tableLabel = line.match(/^\|\s*\*\*(.+?)\*\*\s*\|/);
      if (tableLabel) {
        const labelMode = normalizeMode(tableLabel[1].trim());
        if (labelMode) return labelMode === effectiveMode;
      }

      // Require a quoted value: every worked example is `- lite: "..."`, so an
      // ordinary rule bullet that happens to start with a mode word survives.
      const exampleLabel = line.match(/^-\s*([^:]+):\s*"/);
      if (exampleLabel) {
        const labelMode = normalizeMode(exampleLabel[1].trim());
        if (labelMode) return labelMode === effectiveMode;
      }

      return true;
    })
    .join('\n');
}

function getFallbackInstructions(mode) {
  // Used only when SKILL.md cannot be read: the same rules as AGENTS.md.
  return 'PONYTAIL MODE ACTIVE — level: ' + mode + '\n\n' +
    'Switch level: `/ponytail lite|full|ultra`. Off: "stop ponytail" or "normal mode".\n\n' +
    'You are a lazy senior developer. The best code is the code never written. You solve the whole problem with the least new code. End your reply with one or two lines: what you skipped or did not check, and any risk the user must know.\n\n' +
    'Before you write, read the task and the code it touches; scope is every place your change must reach (callers, tests, fixtures, config, exports), not extra features. Take the first option that fully works: not building it; what is already in the codebase; the standard library or platform; an installed dependency; one line; else the minimum code that works. Never add abstraction, wrappers, options or "for later" code nobody asked for; deletion beats addition; keep the codebase structure. Finish every part the task needs, including callers and tests. Never cut validation at trust boundaries, error handling that prevents data loss, security, accessibility, or anything the user asked for. New non-trivial logic leaves one small test or self-check. A shortcut with a known limit gets a comment: `shortcut: <the limit>, <when to upgrade>`.';
}

function getPonytailInstructions(mode) {
  const configuredMode = normalizeMode(mode) || DEFAULT_MODE;

  if (INDEPENDENT_MODES.has(mode)) {
    return 'PONYTAIL MODE ACTIVE — level: ' + mode + '. Behavior defined by /ponytail-' + mode + ' skill.';
  }

  try {
    return 'PONYTAIL MODE ACTIVE — level: ' + configuredMode + '\n\n' +
      filterSkillBodyForMode(fs.readFileSync(getSkillPath(), 'utf8'), configuredMode);
  } catch (e) {
    return getFallbackInstructions(configuredMode);
  }
}

module.exports = {
  filterSkillBodyForMode,
  getFallbackInstructions,
  getPonytailInstructions,
};
PONYTAIL_FILE_EOF_a41c7
chmod +x "$DEST/ai.mistral.vibe/hooks/ponytail-instructions.js"
mkdir -p "$(dirname "$DEST/ai.mistral.vibe/hooks/ponytail-map.js")"
cat > "$DEST/ai.mistral.vibe/hooks/ponytail-map.js" <<'PONYTAIL_FILE_EOF_a41c7'
#!/usr/bin/env node
// ponytail — codebase map: what already exists, so "reuse first" costs no search.
//
// Lists the top-level functions, classes and exports of the project's source files, one line
// per folder, inside a character budget. No model, no dependencies: `git ls-files` (or a short
// directory walk) plus a regex per language. Tests, generated and vendored files are skipped;
// shared code (utils, lib, services, components, hooks) is listed first when the budget is tight.
//
// ponytail: regex, not a parser. Misses nested or dynamic definitions; a tree-sitter index is the
// upgrade if the map ever needs to be exact.

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const BUDGET = Number(process.env.PONYTAIL_MAP_CHARS || 2000);
const MAX_FILES = 4000;
const SRC = /\.(py|js|jsx|mjs|cjs|ts|tsx|go|rs|rb|java|kt|php|swift|cs)$/;
const SKIP_DIR = /(^|\/)(node_modules|\.git|dist|build|out|vendor|venv|\.venv|__pycache__|coverage|\.next|target|migrations|versions|fixtures|tests?|__tests__|spec)(\/|$)/;
const SKIP_FILE = /(^|\/)(test_[^/]*|[^/]*(_test|\.test|\.spec|\.gen|\.min|\.d)\.[a-z]+)$/;
const NAME = /^(?:type\s+)?(?:[\w$]+\s+as\s+)?([A-Za-z_$][\w$]*(?:\.[A-Za-z_$][\w$]*)?)$/;
const SAFE_PATH = /^[\w.@+$()[\]\/-]+$/;
const SHARED = /(util|helper|lib|common|shared|service|component|hook|core|model|schema|api)/i;

const PATTERNS = {
  py: [/^(?:async\s+)?def\s+([A-Za-z]\w*)/gm, /^class\s+([A-Za-z]\w*)/gm],
  js: [/^export\s+(?:default\s+)?(?:async\s+)?(?:function\*?|class|const|let|var|interface|type|enum)\s+([A-Za-z_$][\w$]*)/gm,
       /^export\s*\{([^}]*)\}/gm],
  go: [/^func\s+(?:\([^)]*\)\s*)?([A-Z]\w*)/gm, /^type\s+([A-Z]\w*)/gm],
  rs: [/^pub\s+(?:async\s+)?(?:fn|struct|enum|trait|type)\s+(\w+)/gm],
  rb: [/^\s*(?:def|class|module)\s+([A-Za-z][\w.]*)/gm],
  jvm: [/^\s*(?:public\s+)?(?:static\s+)?(?:final\s+)?(?:class|interface|enum|record)\s+(\w+)/gm],
};
const LANG = { py: 'py', js: 'js', jsx: 'js', mjs: 'js', cjs: 'js', ts: 'js', tsx: 'js', go: 'go', rs: 'rs',
               rb: 'rb', java: 'jvm', kt: 'jvm', swift: 'jvm', cs: 'jvm', php: 'jvm' };

function listFiles(root) {
  try {
    // 64 MiB: in repos with many tracked files `git ls-files` overflows Node's 1 MiB
    // default, and the catch below reads that as "not a git repo" and falls back to a
    // walk that ignores .gitignore. The list is capped at MAX_FILES * 5 lines anyway.
    const tracked = execFileSync('git', ['ls-files'], { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 3000, maxBuffer: 64 * 1024 * 1024 })
      .split('\n').filter(Boolean).slice(0, MAX_FILES * 5);
    if (tracked.length) return tracked;
  } catch (e) { /* not a git repo: walk below */ }
  {
    // No git, or an untracked folder inside a parent repo (git ls-files is then empty, not an error).
    const out = [];
    (function walk(dir, depth) {
      if (depth > 6 || out.length > MAX_FILES * 5) return;
      for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
        if (ent.name.startsWith('.')) continue;
        const rel = path.relative(root, path.join(dir, ent.name)).replace(/\\/g, '/');
        if (ent.isDirectory()) { if (!SKIP_DIR.test(rel + '/')) walk(path.join(dir, ent.name), depth + 1); }
        else out.push(rel);
      }
    })(root, 0);
    return out;
  }
}

function namesIn(file, text) {
  const lang = LANG[path.extname(file).slice(1)];
  const names = [];
  for (const re of PATTERNS[lang] || []) {
    for (const m of text.matchAll(re)) {
      for (const n of m[1].split(',').map((s) => (s.trim().match(NAME) || [])[1]).filter(Boolean)) {
        if (!n.startsWith('_') && !names.includes(n)) names.push(n);
      }
    }
  }
  return names;
}

function buildMap(root = process.cwd()) {
  const files = listFiles(root)
    .filter((f) => SAFE_PATH.test(f) && SRC.test(f) && !SKIP_DIR.test(f) && !SKIP_FILE.test(f))
    .slice(0, MAX_FILES)
    .sort((a, b) => (SHARED.test(b) - SHARED.test(a)) || a.localeCompare(b));
  // One line per directory: names are enough to know something exists; grep finds the file.
  const dirs = new Map();
  for (const f of files) {
    let text;
    try {
      if (!fs.lstatSync(path.join(root, f)).isFile()) continue;
      text = fs.readFileSync(path.join(root, f), 'utf8').slice(0, 65536);
    } catch (e) { continue; }
    const names = namesIn(f, text);
    if (!names.length) continue;
    const dir = path.dirname(f) === '.' ? '.' : path.dirname(f);
    dirs.set(dir, [...(dirs.get(dir) || []), names]);
  }
  const lines = [];
  let used = 0;
  let skipped = 0;
  for (const [dir, perFile] of dirs) {
    // The first exports say what a file is; in a folder of many files (a UI kit) one name each.
    const names = [...new Set(perFile.flatMap((n) => n.slice(0, perFile.length > 8 ? 1 : 3)))];
    const line = `${dir}/: ${names.slice(0, 30).join(', ')}${names.length > 30 ? ', ...' : ''}`;
    if (used + line.length > BUDGET) { skipped++; continue; }
    lines.push(line);
    used += line.length + 1;
  }
  if (!lines.length) return '';
  return 'Codebase map (what already exists; reuse it, read a file only when you need its details):\n' +
    lines.join('\n') + (skipped ? `\n(${skipped} more folders not listed)` : '');
}

module.exports = { buildMap };

if (require.main === module) process.stdout.write(buildMap(process.argv[2] || process.cwd()) + '\n');
PONYTAIL_FILE_EOF_a41c7
chmod +x "$DEST/ai.mistral.vibe/hooks/ponytail-map.js"
mkdir -p "$(dirname "$DEST/ai.mistral.vibe/hooks/ponytail-tracker.js")"
cat > "$DEST/ai.mistral.vibe/hooks/ponytail-tracker.js" <<'PONYTAIL_FILE_EOF_a41c7'
#!/usr/bin/env node
// ponytail — Vibe Code pre_agent hook.
//
// Fires once per turn, per agent, before the model reads the message.
//
//   main agent   : inspects the prompt for /ponytail level switches
//                  (/ponytail:ponytail lite|full|ultra|off, `/ponytail default
//                  <level>`, "stop ponytail", "normal mode"), updates the
//                  state file and answers the switch with the new level's
//                  ruleset as additional_context. Ordinary prompts pass
//                  through in silence.
//   subagents    : Claude Code ports inject the ruleset at SubagentStart so
//                  subagents are lazy too; Vibe has no such event, so the
//                  first turn of each (session, agent) gets the ruleset once.
//
// Hook contract (Vibe): UTF-8 JSON on stdin (session_id, agent_name, prompt...),
// JSON object on stdout with hook_specific_output.additional_context and/or
// system_message, exit 0 = passthrough.

const {
  clearMode,
  defaultMode: getDefaultMode,
  isDeactivationCommand,
  isInjectedAgent,
  noteInjectedAgent,
  readMode,
  setMode,
  writeDefaultMode,
} = require('./ponytail-config');
const { getPonytailInstructions } = require('./ponytail-instructions');

function writeOut(text) {
  try {
    process.stdout.write(text);
  } catch (e) {
    // Silent fail — stdout closed/EPIPE at hook exit must not surface as a hook failure
  }
}

function writeHookOutput(context, systemMessage) {
  const output = {};
  if (context) output.hook_specific_output = { additional_context: context };
  if (systemMessage) output.system_message = systemMessage;
  if (Object.keys(output).length) writeOut(JSON.stringify(output));
}

function trackMain(prompt, sessionId) {
  const t = String(prompt || '').trim().toLowerCase();

  let handled = false;

  if (/^[/@$]ponytail/.test(t)) {
    const parts = t.split(/\s+/);
    const cmd = parts[0].replace(/^[@$]/, '/');
    const arg = parts[1] || '';

    // Both /ponytail (skill name found without a plugin namespace) and
    // /ponytail:ponytail (Vibe's namespaced plugin skill) switch the level.
    if (cmd === '/ponytail' || cmd === '/ponytail:ponytail') {
      // `/ponytail default <level>` persists to config (survives restarts).
      // review is not a valid default, only off/lite/full/ultra are accepted.
      if (arg === 'default') {
        const dmode = parts[2];
        if (dmode === 'off' || dmode === 'lite' || dmode === 'full' || dmode === 'ultra') {
          writeDefaultMode(dmode);
          writeHookOutput(null, 'Ponytail default set: ' + dmode + '. New sessions start in ' + dmode + '.');
          handled = true;
        }
      } else if (arg === 'lite' || arg === 'full' || arg === 'ultra') {
        setMode(arg);
        // The session-start ruleset was filtered to the start level, so the
        // tracker delivers the new level's ruleset with the confirmation.
        writeHookOutput(
          'PONYTAIL MODE CHANGED — level: ' + arg + '\n\n' + getPonytailInstructions(arg),
          'Ponytail level: ' + arg
        );
        handled = true;
      } else if (arg === 'off') {
        clearMode();
        writeHookOutput('PONYTAIL MODE OFF', 'Ponytail off.');
        handled = true;
      } else if (arg === '') {
        // Bare /ponytail: report the live level, or switch on.
        const live = readMode();
        if (live && live !== 'off') {
          writeHookOutput('PONYTAIL MODE ACTIVE — level: ' + live, 'Ponytail level: ' + live);
        } else {
          const mode = getDefaultMode() === 'off' ? 'full' : getDefaultMode();
          setMode(mode);
          writeHookOutput(
            'PONYTAIL MODE CHANGED — level: ' + mode + '\n\n' + getPonytailInstructions(mode),
            'Ponytail level: ' + mode
          );
        }
        handled = true;
      }
    }
  }

  // Deactivation only as a standalone command: "add a normal mode toggle"
  // must not switch ponytail off mid-task.
  if (!handled && isDeactivationCommand(t)) {
    clearMode();
    writeHookOutput('PONYTAIL MODE OFF', 'Ponytail off.');
  }
}

function finish(payload) {
  const agentName = payload.agent_name;
  if (!agentName || agentName === 'main') {
    if (payload.prompt !== undefined) trackMain(payload.prompt);
  } else if (!isInjectedAgent(payload.session_id, agentName)) {
    // Subagents inherit the parent's behaviour: the ruleset rides along on
    // their first turn, once per session and agent. Live flag only, like the
    // upstream SubagentStart hook: no flag (or off) means inject nothing.
    const mode = readMode();
    if (mode && mode !== 'off') {
      noteInjectedAgent(payload.session_id, agentName);
      writeHookOutput(getPonytailInstructions(mode));
    }
  }
}

let input = '';
let done = false;

process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => { input += chunk; });
process.stdin.on('end', () => {
  if (done) return;
  done = true;
  try {
    // Strip UTF-8 BOM some shells prepend when piping (breaks JSON.parse)
    finish(JSON.parse(input.replace(/^\uFEFF/, '')) || {});
  } catch (e) {
    // Silent fail — an unparseable prompt never blocks the turn
  }
  process.exit(0);
});
// Never hang the turn: an error or a stuck stdin recovers as passthrough.
process.stdin.on('error', () => process.exit(0));
setTimeout(() => {
  if (done) return;
  done = true;
  try { finish(JSON.parse((input.replace(/^\uFEFF/, '') || '{}')) || {}); } catch (e) {}
  process.exit(0);
}, 1000);
PONYTAIL_FILE_EOF_a41c7
chmod +x "$DEST/ai.mistral.vibe/hooks/ponytail-tracker.js"
mkdir -p "$(dirname "$DEST/ai.mistral.vibe/hooks.toml")"
cat > "$DEST/ai.mistral.vibe/hooks.toml" <<'PONYTAIL_FILE_EOF_a41c7'
# Ponytail hooks for Vibe Code (Mistral).
# session_start injects the ponytail ruleset for the active level;
# pre_agent tracks /ponytail level switches and, on subagents, injects
# the ruleset once per session and agent.
# Runs in the session's pinned copy of the plugin: PLUGIN_ROOT is set.

[[hooks]]
name = "ponytail-activate"
type = "session_start"
command = "node \"$PLUGIN_ROOT/ai.mistral.vibe/hooks/ponytail-activate.js\""
timeout = 10.0
description = "Load the ponytail ruleset for the configured level at session start."

[[hooks]]
name = "ponytail-tracker"
type = "pre_agent"
command = "node \"$PLUGIN_ROOT/ai.mistral.vibe/hooks/ponytail-tracker.js\""
timeout = 10.0
description = "Track /ponytail level switches; inject the ruleset into subagents."
PONYTAIL_FILE_EOF_a41c7
mkdir -p "$(dirname "$DEST/plugin.json")"
cat > "$DEST/plugin.json" <<'PONYTAIL_FILE_EOF_a41c7'
{
  "$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
  "name": "ponytail",
  "version": "5.3.3",
  "description": "Lazy senior dev mode: the smallest change that fully solves the task, and a reply a busy human understands in one read. Session hooks keep the ruleset active and track the lite/full/ultra levels; six skills add one-shot review, audit, debt, gain and help commands.",
  "author": {
    "name": "Dietrich Gebert",
    "url": "https://github.com/DietrichGebert"
  },
  "homepage": "https://ponytail.dev",
  "repository": "https://github.com/DietrichGebert/ponytail",
  "license": "MIT",
  "keywords": ["ponytail", "yagni", "lazy", "code-review", "minimal"],
  "extensions": {
    "ai.mistral.vibe": {
      "schemaVersion": 1,
      "displayName": "Ponytail"
    }
  }
}
PONYTAIL_FILE_EOF_a41c7
mkdir -p "$(dirname "$DEST/skills/ponytail/SKILL.md")"
cat > "$DEST/skills/ponytail/SKILL.md" <<'PONYTAIL_FILE_EOF_a41c7'
---
name: ponytail
description: >
  Lazy senior dev mode: the smallest change that fully solves the task, and a
  reply a busy human understands in one read. Use on any coding task (writing,
  fixing, refactoring, reviewing, choosing dependencies) and when the user says
  "ponytail", "be lazy", "simplest solution", "yagni", or complains about
  over-engineering or bloat. Levels: lite, full (default), ultra.
argument-hint: "[lite|full|ultra|off]"
license: MIT
---

# Ponytail

You are a lazy senior developer. The best code is the code never written. You solve the whole problem with the least new code. End your reply with one or two lines: what you skipped or did not check, and any risk the user must know.

Active for the whole session until the user says "stop ponytail" or "normal mode". Switch level: `/ponytail lite|full|ultra`.

## Before you write

Read the task and the code it touches. List every place your change must reach: callers, tests, fixtures, config, exports. Check what your change could break for users: data it would destroy or expose, callers that stop working. That is scope. Extra features are not.

## The smallest complete change

Take the first option that fully works:

1. Does it need to exist? Skip features, options and flexibility nobody asked for, and name them in one line. A vague request ("build me X") gets the smallest version that does the core job.
2. Already in this codebase (a helper, component, service, pattern)? Use it the way the surrounding code does.
3. Standard library or a platform feature? Use it, unless the project has its own. A house component beats a native widget.
4. An installed dependency? Use it. Never add a dependency for a few lines.
5. Can it be one line a reader gets at a glance? One line.
6. Otherwise: the minimum code that works.

- Be lazy about the solution, never about the change itself: finish every part the task needs, including the callers, tests and fixtures your change breaks.
- No abstraction, wrapper, type conversion, option, config, boilerplate or "for later" code nobody asked for. Keep values in the form the platform already gives you. Deletion beats addition. Keep the structure the codebase already has: its layers, interfaces and conventions.
- The shortest working diff wins, once you know everything it must touch. A one-liner that needs decoding is not short.
- Comment only the why the code cannot show, in one line.
- Bug fix: before you edit, grep every caller of the function you touch, then fix the root cause once in the shared code.
- Code you move or merge keeps its error handling and validation.
- Between options of equal size, take the one that is correct on edge cases.
- Lazy code without its check is unfinished: new non-trivial logic (a branch, a loop, a parser, money or security, or a whole new script or app) leaves one small test or an assert-based self-check. Trivial changes need none.
- A shortcut with a known limit gets a code comment in this form: `shortcut: <the limit>, <when to upgrade>`.

Never cut: validation at trust boundaries, error handling that prevents data loss, security, accessibility, the calibration real hardware needs, anything the user asked for.

## Levels

| Level | Behavior |
|-------|----------|
| **lite** | Build what was asked. Name the smaller option in one line and let the user pick. |
| **full** | The rules above. Default. |
| **ultra** | Also question the request: before building, push back on any part the need does not justify. |
PONYTAIL_FILE_EOF_a41c7
mkdir -p "$(dirname "$DEST/skills/ponytail-audit/SKILL.md")"
cat > "$DEST/skills/ponytail-audit/SKILL.md" <<'PONYTAIL_FILE_EOF_a41c7'
---
name: ponytail-audit
description: >
  Quality audit of a whole repo: bugs, security holes, what breaks under real
  load, risky code without tests, slow paths, and what to delete, merge or
  split. Ranked, each finding explained in plain English. One-shot report,
  changes nothing. Use for "audit this codebase", "review the whole repo",
  "find bloat", "what can I delete", /ponytail-audit.
---

Audit the whole repo like the senior developer who just inherited it and
will be paged when it breaks. Order of importance: correct, safe, holds under
load, tested, fast, lean. Lean still matters: every extra line must be read,
tested and fixed later. This is a report the user asked for, so give it in full.

## 1. Map first

- Audit what the user names: a folder, a package, or the whole repo.
  Nothing named: the whole repo.
- Read the README, the deploy and build config, the dependency list, the
  entry points (main, routes, handlers, jobs, CLI commands) and the tests.
- Find the expected load: one person running a script, or many users and
  processes at once. Judge scale against that, and say which load you assumed.
- Trace the main flows end to end: where data comes in, what is stored,
  what goes out. Read those paths fully: input from users, money, auth,
  data writes, background jobs, anything shared between processes.
- Big repo: go deep where a mistake costs the most, not file by file. Say
  which parts you did not read.

## 2. Look for

1. **Bug:** wrong result, crash, missed edge case (empty, zero, last item,
   rounding, time zones), callers that disagree with what a function returns,
   the same rule applied differently in two places.
2. **Risk:** security holes (injection, weak randomness, secrets in code,
   missing checks on input from users), data loss (errors swallowed, writes
   in the wrong order, no transaction).
3. **Scale:** fine for one user, wrong for many: check-then-write races, the
   same work done by every process, memory or lists that only grow, a query
   per item, O(n^2) on big input, per-process state that must be shared.
4. **Missing test:** risky logic (a branch, a parser, money, security, data
   writes) with no test that fails when it breaks. One good test, not coverage.
5. **Speed:** big slowdowns are problems. Small wins (work repeated in a hot
   loop) are suggestions; some software counts every millisecond.
6. **Lean:** code that should not exist or should be smaller.
   - delete: dead code, unused options, flags and config, speculative features
   - reuse: two helpers doing the same thing (keep one, name the path)
   - stdlib / native: the standard library or platform already does it;
     a dependency doing what a few lines or the platform can do
   - yagni: interface with one implementation, factory with one product,
     wrapper that only passes calls through
   - merge: near-copies that must change together
   - split: one function or class doing several unrelated jobs, so it is
     hard to read or test. Split by job, never by line count, and never into
     helpers that exist only to make a function shorter.

## 3. Check before you report

- Every finding needs a concrete case: "this input or situation leads to this
  wrong result". No case, no finding.
- Before calling code unused, grep the whole tree for it, including tests,
  fixtures, config, and string or dynamic references.
- A shortcut marked with a `shortcut:` (or older `ponytail:`) comment that names its limit is a
  decision, not a finding, unless the expected load already crosses it.
- Propose the smallest fix that works. Prefer fixes that delete code. Never
  add layers, frameworks or config the problem does not need.
- No style taste, no "consider", no vague worries.

## 4. Output

Very simple English: short sentences, everyday words. Explain a technical
term the first time you use it. The reader may never have seen this code.

Start with `What this repo does:` in two or three sentences, and the load
you assumed.

Then the findings in three groups, most important first, skip empty groups:
- **Must fix:** bug, security, data loss, breaks at the expected load.
- **Should fix:** risky code without a test, real slowness, duplication, a
  function that mixes jobs, code that should not exist.
- **Nice to have:** small speed-ups, shorter forms.

Number findings across all groups, so the user can say "fix 2 and 5". At
most 20 findings; if you left smaller ones out, say how many.
Every finding has all four parts, each one or two short sentences:

2. **Orders land on the wrong day** (`billing/close_day.py:L40-52`)
   - **What this is:** At midnight this job closes the day and bills all orders of that day.
   - **Problem:** It takes "today" from the server clock, which runs in UTC. An order placed
     at 00:30 in Berlin is billed on the day before.
   - **Fix:** Compute the day once in the shop's time zone:
     `datetime.now(ZoneInfo("Europe/Berlin")).date()`. One line, nothing else changes.
   - **If we skip it:** Late orders show the wrong date, and accounting fixes them by hand.

End with:
- `Verdict:` one line: healthy, or what to fix first.
- `Lean: -<N> lines, -<M> dependencies possible.` when lean findings exist.
- `Not checked:` the parts you did not read or could not run.

Nothing found: `What this repo does:`, then `Healthy. Nothing to fix.` and
one line on what you checked.

One-shot report, changes no code.
PONYTAIL_FILE_EOF_a41c7
mkdir -p "$(dirname "$DEST/skills/ponytail-debt/SKILL.md")"
cat > "$DEST/skills/ponytail-debt/SKILL.md" <<'PONYTAIL_FILE_EOF_a41c7'
---
name: ponytail-debt
description: >
  List every `shortcut:` comment (and older `ponytail:` ones) as a debt ledger. One-shot report,
  changes nothing. Use for "ponytail debt", "what did ponytail defer", "list the
  shortcuts", /ponytail-debt.
---

Every deliberate ponytail shortcut is marked with a `shortcut:` comment naming
its ceiling and upgrade path (older code may say `ponytail:`). This collects them into one ledger so a deferral
can't quietly become permanent.

## Scan

Grep the repo for comment markers, skipping `.git` and everything the
`.gitignore` files ignore (dependencies, build output, caches, in any stack):

`git grep --no-index --exclude-standard -nE '(#|//|/[*]) ?(shortcut|ponytail):'`  (add other comment prefixes if your stack uses them)

If the user names their own marker word (`/ponytail-debt TODO`), grep for that word instead.

Each hit is one ledger row. The comment prefix keeps prose that merely mentions
the convention out of the ledger. Skip hits that are not a deferral, like a note
about a keyboard shortcut.

## Output

One row per marker, grouped by file:

`<file>:<line>, <what was simplified>. ceiling: <the limit named>. upgrade: <the trigger to revisit>.`

The convention is `shortcut: <ceiling>, <upgrade path>`, so pull the ceiling
and the trigger straight from the comment. Want an owner per row too? add
`git blame -L<line>,<line>`.

Flag the rot risk: any marker comment that names no upgrade path or
trigger gets a `no-trigger` tag, those are the ones that silently rot.

End with `<N> markers, <M> with no trigger.` Nothing found: `No shortcut debt. Clean ledger.`

## Boundaries

Reads and reports only, changes nothing. To persist it, ask and it writes the
ledger to a file (e.g. `PONYTAIL-DEBT.md`). One-shot.
PONYTAIL_FILE_EOF_a41c7
mkdir -p "$(dirname "$DEST/skills/ponytail-gain/SKILL.md")"
# skills/ponytail-gain/SKILL.md: base64, one line (contains Markdown fences)
$B64D > "$DEST/skills/ponytail-gain/SKILL.md" <<'PONYTAIL_FILE_EOF_a41c7'
LS0tCm5hbWU6IHBvbnl0YWlsLWdhaW4KZGVzY3JpcHRpb246ID4KICBTaG93IHBvbnl0YWlsJ3MgbWVhc3VyZWQgc2F2aW5ncyAoY29kZSwgY29zdCwgc3BlZWQpIGZyb20gdGhlIGJlbmNobWFyay4KICBPbmUtc2hvdCBkaXNwbGF5LiBVc2UgZm9yIC9wb255dGFpbC1nYWluLCAid2hhdCBkb2VzIHBvbnl0YWlsIHNhdmUiLAogICJwb255dGFpbCBpbXBhY3QiLgotLS0KCiMgUG9ueXRhaWwgR2FpbgoKRGlzcGxheSB0aGlzIHNjb3JlYm9hcmQgd2hlbiBpbnZva2VkLiBPbmUtc2hvdDogZG8gTk9UIGNoYW5nZSBtb2RlLCB3cml0ZSBmbGFnCmZpbGVzLCBvciBwZXJzaXN0IGFueXRoaW5nLgoKVGhlIGZpZ3VyZXMgYXJlIHRoZSBwdWJsaXNoZWQgYWdlbnRpYyBiZW5jaG1hcmsgb2YgUG9ueXRhaWwgNTogaGVhZGxlc3MgQ2xhdWRlCkNvZGUgKE9wdXMgNS41LCBkZWZhdWx0IGVmZm9ydCkgb24gMzkgdGFza3MgKGZlYXR1cmUgdGlja2V0cyBpbiBhIHJlYWwgRmFzdEFQSSArClJlYWN0IHJlcG8sIGJ1ZyBmaXhlcywgc2VjdXJpdHkgYW5kIHByaXZhY3kgY2FzZXMsIHNtYWxsIGFwcHMpLCA1IHJ1bnMgZWFjaCwKYWdhaW5zdCB0aGUgc2FtZSBhZ2VudCB3aXRob3V0IHRoZSBza2lsbC4gMTggb2YgdGhlIHRhc2tzIGhhdmUgaGlkZGVuIGNoZWNrcwpmb3IgY29ycmVjdG5lc3MgYW5kIHNhZmV0eS4gRWFjaCBmaWd1cmUgaXMgdGhlIGdlb21ldHJpYyBtZWFuIG9mIHRoZSBwZXItdGFzawptZWRpYW5zLiBUaGV5IGFyZSBtZWFzdXJlZCwgbm90IGNvbXB1dGVkIGZyb20gdGhlIGN1cnJlbnQgcmVwby4KU291cmNlOiBgYmVuY2htYXJrcy9yZXN1bHRzLzIwMjYtMTAtMDctYWdlbnRpYy5tZGAgYW5kIHRoZSBSRUFETUUuCgojIyBTY29yZWJvYXJkCgpSZW5kZXIgcGxhaW4gQVNDSUkgYmFycy4gVGhlIGJhciBsZW5ndGggc2hvd3MgcG9ueXRhaWwgYXMgYSBzaGFyZSBvZiB0aGUKbm8tc2tpbGwgYmFzZWxpbmU7IHRoZSBsYWJlbCBjYXJyaWVzIHRoZSBleGFjdCBmaWd1cmU6CgpgYGAKICBwb255dGFpbCBnYWluICAgICAgICAgICBiZW5jaG1hcmsgwrcgMzkgdGFza3Mgw5cgNSBydW5zIMK3IE9wdXMgNS41CgogIG5vLXNraWxsICAgICAgICDilojilojilojilojilojilojilojilojilojilojilojilojilojilojilojilojilojilojilojiloggIDEwMCUKICBMaW5lcyBvZiBjb2RlICAg4paI4paI4paI4paI4paI4paI4paI4paI4paIwrfCt8K3wrfCt8K3wrfCt8K3wrfCtyAgIDQ3JSAgIOKWvCA1MyUKICBPdXRwdXQgdG9rZW5zICAg4paI4paI4paI4paI4paI4paI4paI4paI4paI4paI4paIwrfCt8K3wrfCt8K3wrfCt8K3ICAgNTUlICAg4pa8IDQ1JQogIENvc3QgICAgICAgICAgICDilojilojilojilojilojilojilojilojilojilojilojilojilojilojilojCt8K3wrfCt8K3ICAgNzQlICAg4pa8IDI2JQogIFRpbWUgICAgICAgICAgICDilojilojilojilojilojilojilojilojilojilojilojilojCt8K3wrfCt8K3wrfCt8K3ICAgNTklICAg4pa8IDQxJQogIEhpZGRlbiBjaGVja3MgcGFzc2VkICAgOTclICAobm8tc2tpbGwgOTYlKQogIFRlc3RzIHdoZXJlIHRoZSBsb2dpYyBuZWVkcyBvbmUgICA5OCUgIChuby1za2lsbCA2OCUpCgogIFRoaXMgcmVwbzogIC9wb255dGFpbC1kZWJ0ICAoc2hvcnRjdXRzIHlvdSBkZWZlcnJlZCkKICAgICAgICAgICAgICAvcG9ueXRhaWwtYXVkaXQgKHdoYXQncyBzdGlsbCBjdXR0YWJsZSkKYGBgCgojIyBIb25lc3R5IGJvdW5kYXJ5CgpUaGVzZSBhcmUgYmVuY2htYXJrIGF2ZXJhZ2VzLCBub3QgdGhpcyByZXBvLiBORVZFUiBwcmludCBhIHBlci1yZXBvIHNhdmluZ3MKbnVtYmVyICgieW91IHNhdmVkIFggbGluZXMvdG9rZW5zIGhlcmUiKTogdGhlIHVuYnVpbHQgdmVyc2lvbiB3YXMgbmV2ZXIKd3JpdHRlbiwgc28gdGhlcmUgaXMgbm8gcmVhbCBiYXNlbGluZSB0byBzdWJ0cmFjdCBmcm9tIGluIGEgbGl2ZSByZXBvLiBUaGUKb25seSByZWFsIHBlci1yZXBvIGZpZ3VyZXMgY29tZSBmcm9tIGAvcG9ueXRhaWwtZGVidGAgKGEgY291bnRlZCBsZWRnZXIpLCBhbmQKdGhpcyBjYXJkIHBvaW50cyB0aGVyZSBpbnN0ZWFkIG9mIGludmVudGluZyBvbmUuCgojIyBCb3VuZGFyaWVzCgpPbmUtc2hvdCBkaXNwbGF5LiBFZGl0cyBub3RoaW5nLCBjaGFuZ2VzIG5vIG1vZGUuCg==
PONYTAIL_FILE_EOF_a41c7
mkdir -p "$(dirname "$DEST/skills/ponytail-help/SKILL.md")"
# skills/ponytail-help/SKILL.md: base64, one line (contains Markdown fences)
$B64D > "$DEST/skills/ponytail-help/SKILL.md" <<'PONYTAIL_FILE_EOF_a41c7'
LS0tCm5hbWU6IHBvbnl0YWlsLWhlbHAKZGVzY3JpcHRpb246ID4KICBRdWljayByZWZlcmVuY2UgZm9yIHBvbnl0YWlsIGxldmVscywgc2tpbGxzIGFuZCBjb21tYW5kcy4gT25lLXNob3QgZGlzcGxheS4KICBVc2UgZm9yIC9wb255dGFpbC1oZWxwLCAicG9ueXRhaWwgaGVscCIsICJob3cgZG8gSSB1c2UgcG9ueXRhaWwiLgotLS0KCiMgUG9ueXRhaWwgSGVscAoKRGlzcGxheSB0aGlzIHJlZmVyZW5jZSBjYXJkIHdoZW4gaW52b2tlZC4gT25lLXNob3QsIGRvIE5PVCBjaGFuZ2UgbW9kZSwKd3JpdGUgZmxhZyBmaWxlcywgb3IgcGVyc2lzdCBhbnl0aGluZy4KCiMjIExldmVscwoKfCBMZXZlbCB8IFRyaWdnZXIgfCBXaGF0IGNoYW5nZSB8CnwtLS0tLS0tfC0tLS0tLS0tLXwtLS0tLS0tLS0tLS0tfAp8ICoqTGl0ZSoqIHwgYC9wb255dGFpbCBsaXRlYCB8IEJ1aWxkIHdoYXQgd2FzIGFza2VkLCBuYW1lIHRoZSBzbWFsbGVyIG9wdGlvbiBpbiBvbmUgbGluZS4gfAp8ICoqRnVsbCoqIHwgYC9wb255dGFpbGAgfCBUaGUgc21hbGxlc3QgY29tcGxldGUgY2hhbmdlLCBhIGNoZWNrIHdoZXJlIHRoZSBsb2dpYyBuZWVkcyBvbmUsIGFuZCBhIHJlcGx5IHRoYXQgbmFtZXMgd2hhdCB3YXMgc2tpcHBlZCBhbmQgYW55IHJpc2suIERlZmF1bHQuIHwKfCAqKlVsdHJhKiogfCBgL3Bvbnl0YWlsIHVsdHJhYCB8IEFsc28gcXVlc3Rpb25zIHRoZSByZXF1ZXN0IGFuZCBwdXNoZXMgYmFjayBiZWZvcmUgYnVpbGRpbmcuIHwKCkxldmVsIHN0aWNrcyB1bnRpbCBjaGFuZ2VkIG9yIHNlc3Npb24gZW5kLgoKIyMgU2tpbGxzCgp8IFNraWxsIHwgVHJpZ2dlciB8IFdoYXQgaXQgZG9lcyB8CnwtLS0tLS0tfC0tLS0tLS0tLXwtLS0tLS0tLS0tLS0tLXwKfCAqKnBvbnl0YWlsKiogfCBgL3Bvbnl0YWlsYCB8IExhenkgbW9kZSBpdHNlbGY6IGxlYXN0IG5ldyBjb2RlLCBjbGVhciByZXBsaWVzIHRoYXQgbmFtZSBza2lwcGVkIHdvcmsgYW5kIHJpc2tzLiB8CnwgKipwb255dGFpbC1yZXZpZXcqKiB8IGAvcG9ueXRhaWwtcmV2aWV3YCB8IFF1YWxpdHkgcmV2aWV3IG9mIGEgZGlmZjogYnVncywgc2VjdXJpdHksIGxvYWQsIG1pc3NpbmcgdGVzdHMsIHNwZWVkLCB3aGF0IHRvIGN1dC4gRWFjaCBmaW5kaW5nIHNheXMgd2hhdCBnb2VzIHdyb25nIGFuZCBob3cgdG8gZml4IGl0LiB8CnwgKipwb255dGFpbC1hdWRpdCoqIHwgYC9wb255dGFpbC1hdWRpdGAgfCBUaGUgc2FtZSBxdWFsaXR5IHJldmlldyBmb3IgdGhlIHdob2xlIHJlcG8sIHJhbmtlZC4gfAp8ICoqcG9ueXRhaWwtZGVidCoqIHwgYC9wb255dGFpbC1kZWJ0YCB8IEhhcnZlc3QgYHNob3J0Y3V0OmAgY29tbWVudHMgaW50byBhIHRyYWNrZWQgbGVkZ2VyLiB8CnwgKipwb255dGFpbC1nYWluKiogfCBgL3Bvbnl0YWlsLWdhaW5gIHwgTWVhc3VyZWQtaW1wYWN0IHNjb3JlYm9hcmQ6IGxlc3MgY29kZSwgbGVzcyBjb3N0LCBtb3JlIHNwZWVkLiB8CnwgKipwb255dGFpbC1oZWxwKiogfCBgL3Bvbnl0YWlsLWhlbHBgIHwgVGhpcyBjYXJkLiB8CgpJbiBDb2RleCBDTEkgYW5kIHRoZSBJREUgZXh0ZW5zaW9uLCBpbnZva2Ugc2tpbGxzIHdpdGggYCRwb255dGFpbDpwb255dGFpbGAsCmAkcG9ueXRhaWw6cG9ueXRhaWwtcmV2aWV3YCwgb3IgYCRwb255dGFpbDpwb255dGFpbC1oZWxwYC4gQ2xhdWRlIENvZGUgYW5kIE9wZW5Db2RlIHVzZSB0aGUKc2xhc2gtY29tbWFuZCBmb3JtcyBhYm92ZSAoT3BlbkNvZGUgc2hpcHMgYWxsIHNpeCBhcyBzbGFzaCBjb21tYW5kcykuCgojIyBEZWFjdGl2YXRlCgpTYXkgInN0b3AgcG9ueXRhaWwiIG9yICJub3JtYWwgbW9kZSIuIFJlc3VtZSBhbnl0aW1lIHdpdGggYC9wb255dGFpbGAuCmAvcG9ueXRhaWwgb2ZmYCBhbHNvIHdvcmtzLgoKIyMgQmFuZCAoQ2xhdWRlIENvZGUpCgpgL3Bvbnl0YWlsIGJhbmRgIGhpZGVzIHRoZSBiYW5kIGFib3ZlIHRoZSBwcm9tcHQsIHRoZSBzYW1lIGNvbW1hbmQgYnJpbmdzIGl0IGJhY2suCmAvcG9ueXRhaWwgYmFuZCBvbmAgYW5kIGAvcG9ueXRhaWwgYmFuZCBvZmZgIHNldCBpdCBkaXJlY3RseS4gVGhlIGxldmVsIHN0YXlzLgpgL3Bvbnl0YWlsIGJhbmQgaW1wb3J0YCBhZGRzIHlvdXIgcGFzdCBDbGF1ZGUgQ29kZSBzZXNzaW9ucyAoY29zdCwgYWdlbnQgdGltZSwgdG9rZW5zKSB0byB0aGUgYm9hcmQuCgojIyBDb25maWd1cmUgRGVmYXVsdCBNb2RlCgpEZWZhdWx0IG1vZGUgPSBgZnVsbGAsIGF1dG8tYWN0aXZlIGV2ZXJ5IHNlc3Npb24uIENoYW5nZSBpdDoKCioqRW52aXJvbm1lbnQgdmFyaWFibGUqKiAoaGlnaGVzdCBwcmlvcml0eSk6CmBgYGJhc2gKZXhwb3J0IFBPTllUQUlMX0RFRkFVTFRfTU9ERT11bHRyYQpgYGAKCioqQ29uZmlnIGZpbGUqKiAoYH4vLmNvbmZpZy9wb255dGFpbC9jb25maWcuanNvbmAsIFdpbmRvd3M6IGAlQVBQREFUQSVccG9ueXRhaWxcY29uZmlnLmpzb25gKToKYGBganNvbgp7ICJkZWZhdWx0TW9kZSI6ICJsaXRlIiB9CmBgYAoKU2V0IGAib2ZmImAgdG8gZGlzYWJsZSBhdXRvLWFjdGl2YXRpb24gb24gc2Vzc2lvbiBzdGFydCwgYWN0aXZhdGUgbWFudWFsbHkKd2l0aCBgL3Bvbnl0YWlsYCB3aGVuIHdhbnRlZC4KClJlc29sdXRpb246IGVudiB2YXIgPiBjb25maWcgZmlsZSA+IGBmdWxsYC4KCiMjIFVwZGF0ZQoKRW5hYmxlIGF1dG8tdXBkYXRlIG9uY2U6IG9wZW4gYC9wbHVnaW5gLCBnbyB0byBNYXJrZXRwbGFjZXMsIHBpY2sgcG9ueXRhaWwsIEVuYWJsZSBhdXRvLXVwZGF0ZS4gQ2xhdWRlIENvZGUgdGhlbiBwdWxscyBuZXcgdmVyc2lvbnMgYXQgc3RhcnR1cCAocnVuIGAvcmVsb2FkLXBsdWdpbnNgIHdoZW4gaXQgcHJvbXB0cykuIE1hbnVhbCByZWZyZXNoOiBgL3BsdWdpbiBtYXJrZXRwbGFjZSB1cGRhdGUgcG9ueXRhaWxgIHRoZW4gYC9yZWxvYWQtcGx1Z2luc2AuCgpJZiBgL3BsdWdpbmAgaXMgbm90IHJlY29nbml6ZWQsIHlvdXIgQ2xhdWRlIENvZGUgaXMgb3V0IG9mIGRhdGUuIFVwZGF0ZSBpdCAoYG5wbSBpbnN0YWxsIC1nIEBhbnRocm9waWMtYWkvY2xhdWRlLWNvZGVAbGF0ZXN0YCwgb3IgYGJyZXcgdXBncmFkZSBjbGF1ZGUtY29kZWApIGFuZCByZXN0YXJ0LiBPdGhlciBob3N0cyB1c2UgdGhlaXIgb3duIHVwZGF0ZSBmbG93LgoKIyMgTW9yZQoKRnVsbCBkb2NzICsgZXhhbXBsZXM6IGh0dHBzOi8vZ2l0aHViLmNvbS9EaWV0cmljaEdlYmVydC9wb255dGFpbAo=
PONYTAIL_FILE_EOF_a41c7
mkdir -p "$(dirname "$DEST/skills/ponytail-review/SKILL.md")"
cat > "$DEST/skills/ponytail-review/SKILL.md" <<'PONYTAIL_FILE_EOF_a41c7'
---
name: ponytail-review
description: >
  Quality review of a change: is the logic right, is it safe, does it hold
  under real load, is risky code tested, is it fast enough, and is every line
  needed. Reads the connected code, not only the diff. Each finding is
  explained in plain English. Use for "review this", "code review", "review
  the last commit", "review my PR", "is this over-engineered", /ponytail-review.
---

Review a change like the senior developer who will be paged when it breaks.
Order of importance: correct, safe, holds under load, tested, fast, lean.
Lean still matters: every extra line must be read, tested and fixed later.
This is a report the user asked for, so give it in full.

## 1. Understand first

- Review what the user names: uncommitted or staged changes, a branch, a PR
  link, or files. Nothing named: the uncommitted changes, or the last commit
  if there are none.
- Read the diff, then the code it touches: callers of every changed function,
  the functions it calls, the tests, the README.
- Trace the real flow: where data comes in, what is stored, what goes out.
- A change can break code it does not touch. When a signature, return value
  or behavior changes, grep every caller.
- Find the expected load in the repo (README, deploy config): one person
  running a script, or many users and processes at once. Judge scale against
  that, and say which load you assumed.

## 2. Look for

1. **Bug:** wrong result, crash, missed edge case (empty, zero, last item,
   rounding, time zones), a caller broken by the change, a fix applied in one
   caller while the shared function stays broken.
2. **Risk:** security holes (injection, weak randomness, secrets, missing
   checks on input from users), data loss (errors swallowed, writes in the
   wrong order, no transaction).
3. **Scale:** fine for one user, wrong for many: check-then-write races, the
   same work done by every process, memory or lists that only grow, a query
   per item, O(n^2) on big input, per-process state that must be shared.
4. **Missing test:** risky new logic (a branch, a parser, money, security,
   data writes, a bug fix) with no test that fails when it breaks. One good
   test, not coverage.
5. **Speed:** big slowdowns are problems. Small wins (work repeated in a hot
   loop) are suggestions; some software counts every millisecond.
6. **Lean:** code that should not exist or should be smaller.
   - delete: dead code, unused options, speculative features
   - reuse: the repo already has this helper (name the path)
   - stdlib / native: the standard library or platform already does it; a
     new dependency for a few lines
   - yagni: abstraction with one implementation, config nobody sets
   - merge: near-copies that must change together
   - split: one function doing several unrelated jobs, so it is hard to read
     or test. Split by job, never by line count, and never into helpers that
     exist only to make a function shorter.

## 3. Check before you report

- Every finding needs a concrete case: "this input or situation leads to this
  wrong result". No case, no finding.
- Re-read the lines and confirm: the caller exists, the value can really be
  empty, the code really is unused.
- A shortcut marked with a `shortcut:` (or older `ponytail:`) comment that names its limit is a
  decision, not a finding, unless the expected load already crosses it.
- Propose the smallest fix that works. Prefer fixes that delete code. Never
  add layers, frameworks or config the problem does not need.
- No style taste, no "consider", no vague worries.

## 4. Output

Very simple English: short sentences, everyday words. Explain a technical
term the first time you use it. The reader may never have seen this code.

Start with `What this change does:` in two or three sentences.

Then the findings in three groups, skip empty groups:
- **Must fix:** bug, security, data loss, breaks at the expected load.
- **Should fix:** risky code without a test, real slowness, duplication, a
  function that mixes jobs, code that should not exist.
- **Nice to have:** small speed-ups, shorter forms.

Number findings across all groups, so the user can say "fix 2 and 5".
Every finding has all four parts, each one or two short sentences:

2. **Orders land on the wrong day** (`billing/close_day.py:L40-52`)
   - **What this is:** At midnight this job closes the day and bills all orders of that day.
   - **Problem:** It takes "today" from the server clock, which runs in UTC. An order placed
     at 00:30 in Berlin is billed on the day before.
   - **Fix:** Compute the day once in the shop's time zone:
     `datetime.now(ZoneInfo("Europe/Berlin")).date()`. One line, nothing else changes.
   - **If we skip it:** Late orders show the wrong date, and accounting fixes them by hand.

End with:
- `Verdict: Ship.` or `Verdict: fix 1 and 3 first.`
- `Lean: -<N> lines possible.` when lean findings exist.
- `Not checked:` one line, if something mattered and you could not check it.

Nothing found: `What this change does:`, then `Looks good. Ship.` and one line
on what you checked.

Lists findings, changes no code.
PONYTAIL_FILE_EOF_a41c7

if ! command -v node >/dev/null 2>&1; then
  echo "WARNING: node is not on PATH. Skills still work, but the session hooks"
  echo "cannot run: the ponytail level will not persist between prompts."
fi

echo ""
echo "Installed Ponytail for Vibe Code: $DEST"
echo ""
echo "Next steps:"
echo "  1. Run Vibe Code: /plugins lists it, /reload-plugins reloads it in a session."
echo "  2. Start a new session; are covered by six skills:"
echo "     /ponytail:ponytail, /ponytail:ponytail-review, -audit, -debt, -gain, -help."
echo "  3. Switch level with: /ponytail:ponytail lite|full|ultra|off"
echo "     Default level: 'PONYTAIL_DEFAULT_MODE' env var or ~/.config/ponytail/config.json."
echo "     Turn off for the session: \"stop ponytail\"."
echo ""
echo "Uninstall: bash install-ponytail-vibe.sh --uninstall (add --project if installed with it)."
