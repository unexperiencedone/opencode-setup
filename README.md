# opencode setup: local Qwen 3.5 4B plus online providers

Aakshant's opencode setup for agent-driven coding in the terminal, kept here so any laptop
gets the same thing. Local first (Qwen 3.5 4B through Ollama, free and offline), online when
a job needs a bigger model (NVIDIA's free Nemotron; Groq and OpenRouter optional).

Tested 2026-11-14 with opencode 1.19.4 on Ubuntu 26.04: `opencode models` with this config
lists `ollama/qwen3.5-4b-coder`, `ollama/qwen3.5:4b` and `nvidia/nvidia/nemotron-3-ultra-550b-a55b`.
The local model itself was not downloaded on that laptop.

## New laptop, in four commands

```bash
git clone https://github.com/unexperiencedone/opencode-setup.git ~/opencode-setup
cd ~/opencode-setup && ./install.sh          # or ./install.sh --no-model to skip Ollama and the 3.3 GB model
nano ~/.config/opencode/keys.env             # paste keys for the online providers (optional)
./verify.sh
```

Then open a new terminal, `cd` into a project and run `opencode`.

## What `install.sh` does

1. **opencode 1.19.4**, the version this config was tested with: through npm into `~/.local`
   if npm exists, otherwise opencode's own installer. Change `OPENCODE_VERSION` at the top to move on.
2. **Config**, linked rather than copied, so `git pull` here updates the laptop:
   `~/.config/opencode/opencode.jsonc`, `AGENTS.md` (global coding rules), `Modelfile`.
   Existing files are kept as `*.before-setup`.
3. **Keys**: creates `~/.config/opencode/keys.env` from the template (mode 600) and adds one
   line to `~/.bashrc` / `~/.zshrc` that loads it. The real file is never committed.
4. **Ollama, no sudo**: unpacks the official build under `~/.local/share/ollama-dist`,
   without the GPU libraries unless `nvidia-smi` exists, and runs it as a systemd *user*
   service (`systemctl --user status ollama`). Skipped if `ollama` is already installed.
5. **The model**: `ollama pull qwen3.5:4b`, then builds `qwen3.5-4b-coder` from the
   `Modelfile`: the same model with a 32k context. Ollama's default context is too short for
   an agent; the system prompt and tool definitions fill it and tool calls start failing.

## Using it

| Want | Do |
|---|---|
| Code with the local model (default) | `opencode` in the project folder |
| One run on the online model | `opencode -m nvidia/nvidia/nemotron-3-ultra-550b-a55b` |
| Switch model inside a session | `/models` |
| Non-interactive, one prompt | `opencode run "add tests for utils.py"` |
| Is everything working? | `./verify.sh` |

Permissions in `opencode.jsonc`: edits allowed; read-only and test commands allowed (git
status/diff/log, ls, rg, pytest, npm test, cargo test...); every other shell command asks
first; `rm -rf`, `sudo`, `git push --force`, `git reset --hard` are denied.

## Hardware notes

- Qwen 3.5 4B at Q4 is 3.3 GB and runs on the CPU. With the 32k context it wants about
  6–8 GB of free RAM. On a 14 GB laptop with no GPU it is usable for small, focused tasks;
  give larger jobs to the online model.
- With an NVIDIA GPU, the installer keeps Ollama's CUDA libraries and the model runs on it.
- Other sizes: `qwen3.5:9b` for a stronger local model if the laptop has 16 GB+ RAM; change
  `FROM` in `config/Modelfile`, rerun `ollama create qwen3.5-4b-coder -f ~/.config/opencode/Modelfile`
  (or pick a new name and add it under `provider.ollama.models`).

## For Claude Code on a new laptop

If the owner asks you to set up opencode from this repo:

1. Clone it, read this file, then run `./install.sh` (ask before it, because it installs software
   and downloads about 4.8 GB: 1.5 GB of Ollama, 3.3 GB of model; `--no-model` skips both).
2. Never ask for, print or commit the keys. Tell the owner to fill `~/.config/opencode/keys.env` himself.
3. Run `./verify.sh` and report each line. A `NO` line names the fix.
4. Never use `sudo`. Everything installs under the home folder.

## Files

| File | What it is |
|---|---|
| `install.sh` | The setup, safe to run twice |
| `verify.sh` | Checks, changes nothing |
| `config/opencode.jsonc` | Providers (Ollama local, NVIDIA online), default model, permissions |
| `config/AGENTS.md` | Global rules every opencode session reads |
| `config/Modelfile` | `qwen3.5-4b-coder`: Qwen 3.5 4B with a 32k context |
| `config/keys.env.example` | Template for the online keys |
