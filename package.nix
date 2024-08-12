{
  stdenvNoCC,
  fetchurl,
  lib,
  unzip,
}:
let
  versionMetadata = import ./versions.nix;
  fetchForSystem = system: versionMetadata.${system} or (throw "unsupported system ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "instruqt";
  inherit (versionMetadata) version;
  src = fetchurl { inherit (fetchForSystem stdenvNoCC.system) url hash; };

  nativeBuildInputs = [ unzip ];

  unpackPhase = ''
    runHook preUnpack

    unzip $src

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -D instruqt -t $out/bin

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "A text-based interface that accepts commands to create and maintain tracks";
    homepage = "https://docs.instruqt.com/reference/cli/commands";
    mainProgram = "instruqt";
    maintainers = with maintainers; [ tembleking ];
    platforms = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
