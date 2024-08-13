{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = [ self.overlays.default ];
            };
          in
          f pkgs
        );
    in
    {
      overlays.default = final: prev: { instruqt = final.pkgs.callPackage ./package.nix { }; };

      packages = forAllSystems (
        pkgs: with pkgs; {
          inherit instruqt;
          default = instruqt;
        }
      );

      checks = forAllSystems (
        pkgs: with pkgs; {
          inherit instruqt;
          test = stdenv.mkDerivation {
            name = "instruqt can be executed and is the correct version";
            dontUnpack = true;

            buildInputs = [ instruqt ];
            buildPhase = ''
              version=$(HOME="$out" instruqt version || true)
              [[ $(echo $version | awk '{print $2}') == "${instruqt.version}" ]]
            '';
          };
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
