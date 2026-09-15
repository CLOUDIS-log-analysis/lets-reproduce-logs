{
  inputs = {
    nixpkgs-old.url = "github:NixOS/nixpkgs/nixos-21.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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
          config.permittedInsecurePackages = [
            "python-2.7.18.8"
            "openssl-1.0.2u"
          ];
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs-old;
            [
              openjdk8
              ant
              maven
            ]
            ++ (with pkgs; [
              wget
            ]);
        };
      };
    };
}
