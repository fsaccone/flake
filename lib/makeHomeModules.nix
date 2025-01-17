{ home-manager, inputs }:
user: [
  home-manager.nixosModules.home-manager
  {
    imports = [
      ../homes/${user}/user
      (../homes + "/${user}/user")
    ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bkp";

      extraSpecialArgs = {
        inherit inputs;
        getSecretFile = secret: ../homes + "/${user}/secrets/${secret}.asc";
      };

      users.${user} =
        { ... }:
        {
          imports = [
            (../homes + "/${user}/home")
            ../homes/common
            ../modules/home
          ];

          home.stateVersion = "25.05";
        };
    };
  }
]
