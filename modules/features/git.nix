{ self, inputs, ... }: {
  flake.homeManagerModules.git = { config, lib, ... }: {
    options.custom.git = {
      name = lib.mkOption {
        type = lib.types.str;
	description = "Name for git";
      };
      email = lib.mkOption {
        type = lib.types.str;
	description = "Email for git";
      };
    };

    config.programs.git = {
      enable = true;
      settings.user = {
        name = config.custom.git.name;
	email = config.custom.git.email;
      };
    };
  };
}
