{
  config,
  pkgs,
  ...
}:
{
  home.file.".mkshrc".text = ''
    PS1="${"$"}{USER}@$(${pkgs.sbase}/bin/hostname):\${"$"}{PWD} $ "
  '';
}
