{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {
      inherit inputs;
    }
    {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      perSystem = {
        pkgs,
        system,
        ...
      }: let
        pkgs-old =
          import (fetchTarball {
            url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/18.09.tar.gz";
            sha256 = "sha256-7X4jp9lLB0pDxIK/btVHnH9/+ET7uL9MtmWDoBU0acU=";
          }) {
            inherit system;
          };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs-old; [
            gnumake
            gcc
          ];
        };
      };
    };
}
