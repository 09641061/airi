{ ... }:
{
  programs.pi.coding-agent = {
    enable = true;

    settings = {
      defaultThinkingLevel = "medium";
      enableSkillCommands = true;
      subagents = {
        projectRootResolution = "git-root";
        defaultThinking = "medium";

        agentOverrides = {
          explorer = {
            thinking = "low";
            inheritProjectContext = true;
            inheritSkills = true;
            defaultContext = "fresh";
          };

          developer = {
            thinking = "medium";
            inheritProjectContext = true;
            inheritSkills = true;
            defaultContext = "fresh";
          };

          tester = {
            thinking = "medium";
            inheritProjectContext = true;
            inheritSkills = true;
            defaultContext = "fresh";
          };

          reviewer = {
            thinking = "medium";
            inheritProjectContext = true;
            inheritSkills = true;
            defaultContext = "fresh";
          };

          researcher = {
            thinking = "medium";
            inheritProjectContext = true;
            inheritSkills = true;
            defaultContext = "fresh";
          };

          architect = {
            thinking = "medium";
            inheritProjectContext = true;
            inheritSkills = true;
            defaultContext = "fork";
          };

          designer = {
            thinking = "medium";
            inheritProjectContext = true;
            inheritSkills = true;
            defaultContext = "fresh";
          };

          coordinator = {
            thinking = "medium";
            inheritProjectContext = true;
            inheritSkills = true;
            defaultContext = "fork";
          };
        };
      };
    };
  };
}
