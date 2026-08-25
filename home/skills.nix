{ lib, ... }:

let
  # Every directory containing a SKILL.md is a skill. Discovered, not listed by hand:
  # a manual list silently drops any skill nobody remembers to register.
  findSkills = prefix: dir:
    lib.concatLists (lib.mapAttrsToList (name: type:
      let
        path = if prefix == "" then name else "${prefix}/${name}";
      in
        if type != "directory" then []
        else if builtins.pathExists (dir + "/${name}/SKILL.md") then [ path ]
        else findSkills path (dir + "/${name}")
    ) (builtins.readDir dir));

  skills = findSkills "" ./skills;

  mkFiles = target: flatten: lib.listToAttrs (map (path:
    let
      flatName = lib.last (lib.splitString "/" path);
    in {
      name = if flatten then "${target}/${flatName}" else "${target}/${path}";
      value.source = ./skills/${path};
    }
  ) skills);

  flatNames = map (p: lib.last (lib.splitString "/" p)) skills;
  duplicates = lib.subtractLists (lib.unique flatNames) flatNames;
in
assert lib.assertMsg (duplicates == [])
  "home/skills.nix: duplicate skill directory names would collide in the flattened agent dirs: ${toString duplicates}";
{
  home.file =
    (mkFiles ".claude/skills" true)
    // (mkFiles ".gemini/config/skills" true)
    // (mkFiles ".agents/skills" false)
    // (mkFiles ".pi/agent/skills" false);
}
