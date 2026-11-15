{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
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
      perSystem = {pkgs, ...}: let
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            gnumake
            gcc
            pkg-config
            jemalloc
            cmake
            python3
          ];
        };
      };
    };
}
