#!/usr/bin/env bash
# Is the setup working? Prints one line per check; changes nothing.
ok() { printf '  ok   %s\n' "$*"; }; no() { printf '  NO   %s\n' "$*"; }
command -v opencode >/dev/null && ok "opencode $(opencode --version)" || no "opencode not on PATH"
[[ -L ~/.config/opencode/opencode.jsonc ]] && ok "config linked" || no "config not linked (run ./install.sh)"
[[ -f ~/.config/opencode/keys.env ]] && ok "keys.env present" || no "no keys.env (online providers need it)"
[[ -n "${NVIDIA_API_KEY:-}" ]] && ok "NVIDIA_API_KEY set" || no "NVIDIA_API_KEY empty (online Nemotron off)"
if command -v ollama >/dev/null; then
  curl -fs http://127.0.0.1:11434/api/tags >/dev/null && ok "Ollama running" || no "Ollama not running: systemctl --user start ollama"
  ollama list 2>/dev/null | grep -q "qwen3.5-4b-coder" && ok "qwen3.5-4b-coder built" || no "model missing: ./install.sh"
else
  no "Ollama not installed (local model off; ./install.sh)"
fi
opencode models 2>/dev/null | grep -q "^ollama/qwen3.5-4b-coder" && ok "opencode sees the local model" || no "opencode doesn't list ollama/qwen3.5-4b-coder"
