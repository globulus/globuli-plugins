#!/bin/sh
# The driver plugin's way to `globuli` (D-593): its MCP server (`globuli.sh mcp`)
# and its SessionStart hook (`globuli.sh session-start`) run the globuli on the
# PATH. A session started from the Dock may have a PATH without the installer's
# folder or Homebrew's, so ~/.local/bin (where the installer puts it, D-624) and
# then Homebrew's two prefixes are looked in after it (D-630). GLOBULI_BIN names
# another. The project is the lookup's (D-592), from the session's folder:
# nothing here names a root. Plain sh, nothing but the exec.
bin=${GLOBULI_BIN:-}
if [ -z "$bin" ]; then
  bin=$(command -v globuli 2>/dev/null || true)
fi
if [ -z "$bin" ] && [ -n "${HOME:-}" ] && [ -x "$HOME/.local/bin/globuli" ]; then
  bin=$HOME/.local/bin/globuli
fi
if [ -z "$bin" ]; then
  for prefix in /opt/homebrew /usr/local; do
    if [ -x "$prefix/bin/globuli" ]; then
      bin=$prefix/bin/globuli
      break
    fi
  done
fi
if [ -z "$bin" ]; then
  why="globuli is not on the PATH, nor in ~/.local/bin, /opt/homebrew/bin or /usr/local/bin: install it (the installer puts it in ~/.local/bin; or brew install globulus/globuli/globuli), or name it in GLOBULI_BIN, then start a new session"
  # The hook's stdout is the session's context; the server's is the protocol.
  if [ "${1:-}" = session-start ]; then
    echo "Globuli (D-593): $why."
    exit 0
  fi
  echo "globuli plugin: $why" >&2
  exit 1
fi
exec "$bin" "$@"
