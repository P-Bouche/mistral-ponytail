#!/usr/bin/env node
// Test harness: simulates Vibe Code hook payloads for the ponytail port.
// Isolates HOME so state/config writes land in a temp dir.

const { execFileSync, spawnSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const PLUGIN = path.join(__dirname, '..', 'ponytail');
const HOOKS = path.join(PLUGIN, 'ai.mistral.vibe', 'hooks');
const HOME = fs.mkdtempSync(path.join(os.tmpdir(), 'pt-test-'));
const statePath = path.join(HOME, '.vibe', 'ponytail-data', 'state.json');
const configPath = path.join(HOME, '.config', 'ponytail', 'config.json');

process.env = Object.assign({}, process.env, {
  HOME, // POSIX
  USERPROFILE: HOME, // Windows
  XDG_CONFIG_HOME: path.join(HOME, '.config'),
  PLUGIN_ROOT: PLUGIN,
  PLUGIN_DATA: path.join(HOME, '.vibe', 'ponytail-data'),
  PONYTAIL_MAP: '0',
});

let passed = 0, failed = 0;
function check(name, cond, extra) {
  if (cond) { passed++; console.log('  ok', name); }
  else { failed++; console.log('FAIL', name, extra !== undefined ? JSON.stringify(extra) : ''); }
}

function runHook(script, payload, extraEnv) {
  const env = Object.assign({}, process.env, extraEnv || {});
  const r = spawnSync(process.execPath, [path.join(HOOKS, script)], {
    input: JSON.stringify(payload), encoding: 'utf8', env, timeout: 15000,
  });
  return { code: r.status, stdout: (r.stdout || '').trim(), stderr: r.stderr };
}

function stdoutJson(res) {
  try { return JSON.parse(res.stdout); } catch (e) { return null; }
}

// --- session_start -----------------------------------------------------------
console.log('session_start');
let res = runHook('ponytail-activate.js', { hook_event_name: 'session_start', source: 'startup', session_id: 's1', cwd: PLUGIN });
let out = stdoutJson(res);
check('exit 0 on startup', res.code === 0);
check('valid JSON on stdout', out !== null, res.stdout);
check('level: full by default', /level: full/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));
check('ruleset injected', /lazy senior developer/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));
check('frontmatter stripped', !/---\nname: ponytail/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));

res = runHook('ponytail-activate.js', { source: 'startup', session_id: 's1' }, { PONYTAIL_DEFAULT_MODE: 'ultra' });
out = stdoutJson(res);
check('ultra default honored', /level: ultra/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));
check('ultra table row kept', /\*\*ultra\*\*/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));
check('lite/full table rows filtered', !/\*\*(lite|full)\*\*/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));

res = runHook('ponytail-activate.js', { source: 'startup', session_id: 's1' }, { PONYTAIL_DEFAULT_MODE: 'off' });
check('off: no stdout', res.stdout === '', res.stdout);
check('off: exit 0', res.code === 0);

const fixtureSrc = path.join(HOME, 'fixture', 'src');
fs.mkdirSync(fixtureSrc, { recursive: true });
fs.writeFileSync(path.join(fixtureSrc, 'util.js'), 'export function add(a, b) { return a + b; }\nexport const NAME = "fixture";\n');
res = runHook('ponytail-activate.js', { source: 'startup', session_id: 's1', cwd: path.join(HOME, 'fixture') }, { PONYTAIL_MAP: '1' });
out = stdoutJson(res);
check('codebase map appended when on', /Codebase map/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || '') && /src\/: add/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''), res.stdout);

res = runHook('ponytail-activate.js', { source: 'startup', session_id: 's1' });
out = stdoutJson(res);
check('worked examples filtered away from full level', !/^- lite: \"/m.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));

// --- pre_agent: level switching (main) --------------------------------------
console.log('pre_agent (main)');
res = runHook('ponytail-tracker.js', { hook_event_name: 'pre_agent', agent_name: 'main', session_id: 's1', prompt: '/ponytail ultra' });
out = stdoutJson(res);
check('/ponytail ultra: exit 0', res.code === 0);
check('/ponytail ultra: mode changed context', /PONYTAIL MODE CHANGED — level: ultra/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));
check('/ponytail ultra: system_message', out && out.system_message === 'Ponytail level: ultra');
check('state mode persisted', JSON.parse(fs.readFileSync(statePath, 'utf8')).mode === 'ultra');

// survive it: resume keeps the live level
res = runHook('ponytail-activate.js', { source: 'resume', session_id: 's2' });
out = stdoutJson(res);
check('resume keeps live level', /level: ultra/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));

// namespaced form (Vibe plugin skills)
res = runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's1', prompt: '/ponytail:ponytail lite' });
out = stdoutJson(res);
check('namespaced /ponytail:ponytail lite', /level: lite/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));

// bare /ponytail reports the level
res = runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's1', prompt: '/ponytail' });
out = stdoutJson(res);
check('bare /ponytail reports level', out && out.system_message === 'Ponytail level: lite');

// default persistence
res = runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's1', prompt: '/ponytail default ultra' });
out = stdoutJson(res);
check('/ponytail default ultra: config written', JSON.parse(fs.readFileSync(configPath, 'utf8')).defaultMode === 'ultra');
check('/ponytail default ultra: notice', /default set/.test(out && out.system_message || ''));
res = runHook('ponytail-activate.js', { source: 'startup', session_id: 's3' });
out = stdoutJson(res);
check('new session starts at persisted default', /level: ultra/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));
res = runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's3', prompt: '/ponytail default review' });
check('review rejected as default', runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's3', prompt: '/ponytail default review' }).stdout === '');

// off + deactivation
res = runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's3', prompt: '/ponytail off' });
out = stdoutJson(res);
check('/ponytail off', /PONYTAIL MODE OFF/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));
check('/ponytail off: state cleared', !JSON.parse(fs.readFileSync(statePath, 'utf8')).mode);
res = runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's3', prompt: '/ponytail' });
out = stdoutJson(res);
check('bare /ponytail switches back on', /level: full|level: ultra/.test(out && out.system_message || '') || /MODE CHANGED/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));
runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's3', prompt: '/ponytail off' });
res = runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's3', prompt: 'stop ponytail' });
check('stop ponytail when already off: confirmation (upstream behaviour)', /PONYTAIL MODE OFF/.test(stdoutJson(res) && stdoutJson(res).hook_specific_output && stdoutJson(res).hook_specific_output.additional_context || ''));
runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's3', prompt: '/ponytail' });
res = runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's3', prompt: 'Stop Ponytail!' });
out = stdoutJson(res);
check('deactivation: case and punctuation tolerated', /PONYTAIL MODE OFF/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));

// no false deactivation
runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's4', prompt: '/ponytail lite' });
res = runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's4', prompt: 'add a normal mode toggle to settings' });
check('mid-task "normal mode" ignored', res.stdout === '', res.stdout);
res = runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's4', prompt: 'fix the login bug please' });
check('ordinary prompt: passthrough', res.stdout === '', res.stdout);
res = runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's4', prompt: '/ponytail-review src/app.tsx' });
check('one-shot skill prompt: no level change', res.stdout === '', res.stdout);

// bad input
res = spawnSync(process.execPath, [path.join(HOOKS, 'ponytail-tracker.js')], { input: 'not json', encoding: 'utf8', env: process.env, timeout: 15000 });
check('garbage stdin: exit 0, no output', res.status === 0 && (res.stdout || '').trim() === '');
res = spawnSync(process.execPath, [path.join(HOOKS, 'ponytail-tracker.js')], { input: '', encoding: 'utf8', env: process.env, timeout: 15000 });
check('empty stdin: exit 0, no output', res.status === 0 && (res.stdout || '').trim() === '');

// --- pre_agent: subagents ---------------------------------------------------
console.log('pre_agent (subagents)');
// A fresh session_start must write the live flag: subagents read it.
res = runHook('ponytail-activate.js', { source: 'startup', session_id: 's7' });
res = runHook('ponytail-tracker.js', { agent_name: 'reviewer', session_id: 's7', prompt: 'check the diff' });
check('flag written by session_start reaches subagents', /lazy senior developer/.test(stdoutJson(res) && stdoutJson(res).hook_specific_output && stdoutJson(res).hook_specific_output.additional_context || ''), res.stdout);
runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's5', prompt: '/ponytail full' });
res = runHook('ponytail-tracker.js', { agent_name: 'reviewer', session_id: 's5', prompt: 'check the diff' });
out = stdoutJson(res);
check('subagent gets ruleset on first turn', /lazy senior developer/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));
res = runHook('ponytail-tracker.js', { agent_name: 'reviewer', session_id: 's5', prompt: 'still checking' });
check('subagent second turn: no duplicate injection', res.stdout === '', res.stdout);
res = runHook('ponytail-tracker.js', { agent_name: 'writer', session_id: 's5', prompt: 'write docs' });
out = stdoutJson(res);
check('second subagent also injected', /lazy senior developer/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));
runHook('ponytail-tracker.js', { agent_name: 'main', session_id: 's5', prompt: '/ponytail off' });
res = runHook('ponytail-tracker.js', { agent_name: 'planner', session_id: 's5', prompt: 'plan it' });
check('subagent while off: nothing', res.stdout === '', res.stdout);

// --- fallback ruleset (missing SKILL.md) ------------------------------------
res = runHook('ponytail-activate.js', { source: 'startup', session_id: 's6' }, { PLUGIN_ROOT: '/nonexistent', PLUGIN_DATA: path.join(HOME, '.vibe', 'ponytail-data') });
out = stdoutJson(res);
check('missing SKILL.md: fallback ruleset', /lazy senior developer/.test(out && out.hook_specific_output && out.hook_specific_output.additional_context || ''));

// --- static validation ------------------------------------------------------
console.log('static');
const manifest = JSON.parse(fs.readFileSync(path.join(PLUGIN, 'plugin.json'), 'utf8'));
check('manifest: name', manifest.name === 'ponytail');
check('manifest: schema', manifest.$schema === 'https://agent-plugins.org/schemas/1.0.0/plugin.schema.json');
check('manifest: vibe extension declared', manifest.extensions && manifest.extensions['ai.mistral.vibe'] && manifest.extensions['ai.mistral.vibe'].schemaVersion === 1);
check('manifest: license + author', manifest.license === 'MIT' && !!(manifest.author && manifest.author.name));

const skills = fs.readdirSync(path.join(PLUGIN, 'skills')).filter((d) => fs.existsSync(path.join(PLUGIN, 'skills', d, 'SKILL.md')));
check('six skills present', skills.length === 6, skills);
for (const s of skills) {
  const body = fs.readFileSync(path.join(PLUGIN, 'skills', s, 'SKILL.md'), 'utf8');
  const m = body.match(/^---\n([\s\S]*?)\n---/);
  check('skill ' + s + ': frontmatter name matches dir', m && m[1].includes('name: ' + s));
}

console.log('\n' + passed + ' passed, ' + failed + ' failed' + (failed ? ' (HOME: ' + HOME + ')' : ''));
process.exit(failed ? 1 : 0);
