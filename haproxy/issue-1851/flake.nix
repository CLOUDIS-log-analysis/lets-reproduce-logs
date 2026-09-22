{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-old.url = "github:NixOS/nixpkgs/nixos-22.11";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs-old,
    ...
  }:
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
        pkgs-old = import nixpkgs-old {
          inherit system;
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs;
            [
              git
              gnumake
              gcc
              lua53Packages.lua
              pkg-config
              uftraceFull
              python3
            ]
            ++ (with pkgs-old; [
              quictls
              libxcrypt
              pcre2
              systemd.dev
            ]);
        };
      };
    };
}
