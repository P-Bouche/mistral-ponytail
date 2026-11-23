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
