{ lib, ... }:

{
  # Keep config.toml writable: Codex writes trust decisions to this file.
  # Managing it as home.file would make it an immutable /nix/store symlink.
  home.activation.codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config="$HOME/.codex/config.toml"
    if [ -L "$config" ] || [ ! -e "$config" ]; then
      rm -f "$config"
      cat > "$config" <<'EOF'
    [features]
    code_mode_host = true
    EOF
      chmod 600 "$config"
    elif grep -q '^code_mode_host = false$' "$config"; then
      sed -i 's/^code_mode_host = false$/code_mode_host = true/' "$config"
    fi
  '';
}
