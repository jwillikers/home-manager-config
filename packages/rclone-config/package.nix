{
  fetchFromGitea,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "rclone-config";
  version = "0-unstable-2025-08-04";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "jwillikers";
    repo = "rclone-config";
    rev = "5f7b60f72356642d3bda16ca43502b25419f4601";
    hash = "sha256-V6lob9YWcJPxNldk/+A2wdeASc2uqYIriH5+ADyTRhk=";
  };

  installPhase = ''
    runHook preInstall
    install -D --mode=0600 rclone/rclone.conf $out/etc/rclone/rclone.conf
    runHook postInstall
  '';
}
