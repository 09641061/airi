{ lib, ... }:

let
  skills = [
    { path = "operating-systems/nixos-multi-host-architecture"; }
    { path = "software-design/design-system-patterns"; }
    { path = "software-design/frontend-design"; }
    { path = "software-design/impeccable"; }
    { path = "software-design/shadcn"; }
    { path = "software-design/tailwind-design-system"; }
    { path = "software-design/ui-design"; }
    { path = "software-design/vercel-composition-patterns"; }
    { path = "software-design/web-design-guidelines"; }
    { path = "software-engineering/domain-driven-design-ddd/angular-ddd"; }
    { path = "software-engineering/domain-driven-design-ddd/flutter-ddd"; }
    { path = "software-engineering/domain-driven-design-ddd/java-25-ddd"; }
    { path = "software-engineering/domain-driven-design-ddd/next-ddd"; }
    { path = "software-engineering/test-driven-development-tdb/java-tdb"; }
    { path = "software-engineering/test-driven-development-tdb/next-tdb"; }
    { path = "software-testing-qa/testing-by-method/mutation"; flatName = "mutation-testing"; }
  ];

  mkFiles = target: flatten: lib.listToAttrs (map (skill:
    let
      flatName = skill.flatName or (lib.last (lib.splitString "/" skill.path));
    in {
      name = if flatten then "${target}/${flatName}" else "${target}/${skill.path}";
      value.source = ./skills/${skill.path};
    }
  ) skills);
in
{
  home.file =
    (mkFiles ".claude/skills" true)
    // (mkFiles ".gemini/config/skills" true)
    // (mkFiles ".agents/skills" false)
    // (mkFiles ".pi/agent/skills" false);
}
