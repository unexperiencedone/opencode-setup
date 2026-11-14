#!/usr/bin/env bash
# Sets up opencode for local + online coding on a new Linux laptop. Run from this repo:
#   ./install.sh            everything: opencode, Ollama, Qwen 3.5 4B, config, keys file
#   ./install.sh --no-model config and opencode only (no Ollama, no 3 GB download)
# Safe to run twice. Nothing here needs sudo; Ollama is installed under ~/.local.
set -euo pipefail

OPENCODE_VERSION="1.19.4"     # the version this config was tested with (2026-11-14)
MODEL="qwen3.5:4b"            # Ollama tag; 3.3 GB at Q4
HERE="$(cd "$(dirname "$0")" && pwd)"
CONF="$HOME/.config/opencode"
WITH_MODEL=1
[[ "${1:-}" == "--no-model" ]] && WITH_MODEL=0

say() { printf '\n==> %s\n' "$*"; }

# 1. opencode itself
if command -v opencode >/dev/null && [[ "$(opencode --version 2>/dev/null)" == "$OPENCODE_VERSION" ]]; then
  say "opencode $OPENCODE_VERSION already installed"
elif command -v npm >/dev/null; then
  say "Installing opencode $OPENCODE_VERSION with npm (user prefix ~/.local)"
  npm config get prefix | grep -q "$HOME" || npm config set prefix "$HOME/.local"
  npm install -g "opencode-ai@$OPENCODE_VERSION"
else
  say "Installing opencode with its official installer (no npm found)"
  curl -fsSL https://opencode.ai/install | bash
fi

# 2. config: linked, so `git pull` in this repo updates every laptop
say "Linking config into $CONF"
mkdir -p "$CONF"
for f in opencode.jsonc AGENTS.md Modelfile; do
  if [[ -e "$CONF/$f" && ! -L "$CONF/$f" ]]; then mv "$CONF/$f" "$CONF/$f.before-setup"; fi
  ln -sfn "$HERE/config/$f" "$CONF/$f"
done

# 3. keys file (empty template; fill it in by hand)
if [[ ! -f "$CONF/keys.env" ]]; then
  cp "$HERE/config/keys.env.example" "$CONF/keys.env"
  chmod 600 "$CONF/keys.env"
  say "Created $CONF/keys.env: put your keys in it"
fi
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [[ -f "$rc" ]] || continue
  grep -q "opencode/keys.env" "$rc" || echo '[ -f "$HOME/.config/opencode/keys.env" ] && . "$HOME/.config/opencode/keys.env"' >> "$rc"
done

# 4. Ollama and the local model
if [[ $WITH_MODEL -eq 1 ]]; then
  if ! command -v ollama >/dev/null; then
    say "Installing Ollama under ~/.local (CPU build unless an NVIDIA GPU is present)"
    dist="$HOME/.local/share/ollama-dist"; mkdir -p "$dist" "$HOME/.local/bin"
    excludes=(--exclude='lib/ollama/rocm*' --exclude='lib/ollama/vulkan*')
    command -v nvidia-smi >/dev/null || excludes+=(--exclude='lib/ollama/cuda_*')
    curl -fsSL https://ollama.com/download/ollama-linux-amd64.tar.zst | zstd -dc | tar -x -C "$dist" "${excludes[@]}"
    ln -sfn "$dist/bin/ollama" "$HOME/.local/bin/ollama"
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$HOME/.config/systemd/user/ollama.service" <<UNIT
[Unit]
Description=Ollama (local models for opencode)
[Service]
ExecStart=$HOME/.local/bin/ollama serve
Restart=on-failure
[Install]
WantedBy=default.target
UNIT
    systemctl --user daemon-reload
    systemctl --user enable --now ollama.service
    sleep 3
  fi
  export PATH="$HOME/.local/bin:$PATH"
  say "Pulling $MODEL and building qwen3.5-4b-coder (32k context)"
  ollama pull "$MODEL"
  ollama create qwen3.5-4b-coder -f "$CONF/Modelfile"
fi

say "Done. Open a new terminal, cd into a project, run: opencode"
say "Check: ./verify.sh"
