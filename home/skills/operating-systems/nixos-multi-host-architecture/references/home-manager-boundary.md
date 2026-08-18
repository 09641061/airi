# Home Manager Boundary

## 12. Home Manager boundary

Home Manager is optional and, when embedded into NixOS, is a user-configuration
layer rather than another system package layer.

Home Manager may manage:

- files under the user's home directory;
- shell and editor configuration;
- Git configuration;
- user-level services;
- user session variables;
- application preferences;
- GTK, Qt, cursor, and theme settings as configuration.

Home Manager must not:

- use `home.packages`;
- define user package lists;
- install or download applications;
- duplicate NixOS application profiles;
- become a second system package manager.

All packages must be declared in NixOS modules. Home Manager may configure an
application that is already provided by the system, but it does not own that
application's package or installation lifecycle.
