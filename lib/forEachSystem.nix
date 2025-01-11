{ nixpkgs, systems }: f: nixpkgs.lib.genAttrs systems (system: f system)
