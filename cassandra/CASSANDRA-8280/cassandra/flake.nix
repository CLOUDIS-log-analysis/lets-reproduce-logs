{
  inputs = {
    nixpkgs-old.url = "github:NixOS/nixpkgs/nixos-21.05";
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs-old,
    nixpkgs-python,
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
              ((nixpkgs-python.packages.${system}."2.7.10") .overrideAttrs (old: {
                configureFlags =
                  (old.configureFlags)
                  ++ [
                    "--with-openssl=${openssl_1_0_2}"
                  ];
                nativeBuildInputs =
                  (old.nativeBuildInputs)
                  ++ (with pkgs; [
                    openssl_1_0_2
                  ]);
              }))
              openjdk8
              ant
            ]
            ++ (with pkgs; [
              wget
            ]);
        };
      };
    };
}
