{
  lib,
  buildGoModule,
  fetchgit,
}:
buildGoModule rec {
  pname = "gmnhg";
  version = "0.4.2";

  src = fetchgit {
    url = "https://github.com/tdemin/gmnhg.git";
    rev = "v${version}";
    sha256 = "sha256-ob1bt9SX9qFd9GQ5d8g+fS4z+aT9ob3a7iLY8zjUCp8=";
  };

  vendorHash = "sha256-Jiud36qgjj7RlJ7LysTlhKQhHK7C116lxbw1Cj2hHmU=";

  meta = {
    description = "Hugo-to-Gemini Markdown converter.";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.unix;
  };
}
