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
