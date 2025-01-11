{
  config,
  ...
}:
{
  system.stateVersion = "23.11";

  users = {
    mutableUsers = false;
    users."root".hashedPassword = "!";
  };

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
    };
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 1d";
    };
  };
}
