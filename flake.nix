{
  description = "CTXBench Lattes dataset repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.bash
            pkgs.coreutils
            pkgs.curl
            pkgs.gnutar
            pkgs.gzip
            pkgs.jq
            pkgs.python3
            pkgs.git
            pkgs.gh
            pkgs.just
          ];

          shellHook = ''
            echo "CTXBench Lattes development environment"
            echo "Available commands:"
            echo "  just pack"
            echo "  just verify"
            echo "  just download"
            echo "  just unpack"
          '';
        };
      });
    };
}
