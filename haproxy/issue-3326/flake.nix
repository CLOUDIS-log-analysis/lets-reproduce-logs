{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
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
            git
            gnumake
            gcc
            openssl
            pcre2
            lua53Packages.lua
            pkg-config
            libxcrypt
            uftraceFull
          ];
        };
      };
    };
}
