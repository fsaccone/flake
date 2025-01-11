{
  lib,
  options,
  config,
  pkgs,
  ...
}:
let
  luaFileToVim = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
in
{
  options.modules = {
    neovim.enable = lib.mkEnableOption "enables neovim";
  };

  config = lib.mkIf config.modules.neovim.enable {
    programs.neovim = {
      enable = true;
      package = pkgs.neovim-unwrapped;

      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      plugins = with pkgs.vimPlugins; [
        {
          plugin = nerdtree;
          config = builtins.readFile ./plugins/nerdtree.vim;
        }
        {
          plugin = tokyonight-nvim;
          config = builtins.readFile ./plugins/tokyonight.vim;
        }
        {
          plugin = twilight-nvim;
          config = luaFileToVim ./plugins/twilight.lua;
        }
        editorconfig-vim
      ];

      coc = {
        enable = true;
        package = pkgs.vimPlugins.coc-nvim;
        pluginConfig = builtins.readFile ./plugins/coc.vim;
      };

      extraConfig = builtins.readFile ./configuration/init.vim;
    };
  };
}
