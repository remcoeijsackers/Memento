#!/usr/bin/env bash
# Install Memento (mto).
#
#   curl -fsSL https://raw.githubusercontent.com/remcoeijsackers/Memento/main/install.sh | bash
#   ./install.sh                 (from a clone)
#
# PREFIX (default ~/.local) chooses where bin/mto goes. Set MEMENTO_SHELL=bash|zsh
# to pick the shell instead of using $SHELL. Nothing here needs sudo.
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"
RAW="https://raw.githubusercontent.com/remcoeijsackers/Memento/main"

mkdir -p "$BIN_DIR"
here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)" || here=""
if [ -n "$here" ] && [ -f "$here/bin/mto" ]; then
  cp "$here/bin/mto" "$BIN_DIR/mto"
else
  curl -fsSL "$RAW/bin/mto" -o "$BIN_DIR/mto"
fi
chmod +x "$BIN_DIR/mto"
echo "installed $BIN_DIR/mto ($("$BIN_DIR/mto" --version))"

"$BIN_DIR/mto" install ${MEMENTO_SHELL:+"$MEMENTO_SHELL"}
