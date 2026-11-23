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
      const exampleLabel = line.match(/^-\s*([^:]+):\s*\"/);
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
