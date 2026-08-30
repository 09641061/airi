{ ... }:

{
  # Antigravity CLI / IDE settings configuration
  # Sets execution policies to allow automated subagent execution without
  # repetitive manual approval prompts for standard file and command operations.
  home.file.".gemini/antigravity-cli/settings.json".text = builtins.toJSON {
    toolExecutionPolicy = "always-proceed";
    fileAccessPolicy = "allow";
    internetAccessPolicy = "allow";
    commandAllowlist = [ "*" ];
    artifactReviewMode = "always-proceed";
  };
}
