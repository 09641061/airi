{ ... }:

{
  # Antigravity CLI / IDE settings configuration.
  # Use the documented settings schema so outside-workspace file access and
  # command execution do not keep prompting during agent workflows.
  home.file.".gemini/antigravity-cli/settings.json".text = builtins.toJSON {
    toolPermission = "always-proceed";
    artifactReviewPolicy = "always-proceed";
    allowNonWorkspaceAccess = true;
    permissions = {
      allow = [
        "read_file(/home/giks/.config)"
      ];
    };
  };
}
