{
  config,
  ...
}:
{
  home.file.".mkshrc".text = ''
    PS1="[\${"$"}{PWD}]$ "
  '';
}
