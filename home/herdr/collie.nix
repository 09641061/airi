{ collie, ... }:
{
  # Collie is a Herdr-facing application, not a Pi npm package.
  # The binary is installed declaratively; plugin registration remains an
  # explicit operation via `nix run .#install-collie-plugin`.
  home.packages = [ collie ];
}
