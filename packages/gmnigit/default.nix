{
  lib,
  buildGoModule,
  fetchgit,
}:
buildGoModule rec {
  name = "gmnigit";

  src = fetchgit {
    url = "https://git.sr.ht/~kornellapacz/gmnigit";
    rev = "b266bf6f6d32162d83df91c35ab4f43e3da445eb";
    sha256 = "sha256-as8WpwJFX/sXsUueLIchcBj8/FWKCpEB5vdZBZe4xpU=";
  };

  vendorHash = "sha256-/UIfgwPFZxdnSywA7ysyVIFQXTRud/nlkOdzGEESEbY=";

  meta = {
    description = "Static git gemini viewer written in golang.";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
