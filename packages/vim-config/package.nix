{
  fetchFromGitea,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "vim-config";
  version = "0-unstable-2024-10-16";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "vim-config";
    rev = "16aec1e3bb4a8e25aa0d53b3c4563d881f2c693a";
    hash = "sha256-xMfVJqiEtZ+bB/+pWBH1dXJW7WC6xWrnTGg98TwACFo=";
  };

  installPhase = ''
    install -D --mode=0644 vimrc $out/etc/vim/vimrc
  '';
}
