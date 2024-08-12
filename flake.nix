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

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      pkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ self.overlays.default ];
        }
      );
    in
    {
      overlays.default = final: prev: {
        instruqt = (pkgsFor.${final.system}).callPackage ./package.nix { };
      };

      packages = forAllSystems (system: rec {
        inherit (pkgsFor.${system}) instruqt;
        default = instruqt;
      });

      checks = forAllSystems (
        system: with pkgsFor.${system}; {
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

      formatter = forAllSystems (system: (pkgsFor.${system}.nixfmt-rfc-style));
    };
}
