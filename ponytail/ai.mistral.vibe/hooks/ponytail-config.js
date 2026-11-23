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
