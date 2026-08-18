{
  nixpkgs,
  pkgs,
  system,
}:
nixpkgs.lib.nixosSystem {
  inherit system pkgs;
  modules = [
    # ./configuration.nix

    ({...}: {
      nixpkgs.flake.setNixPath = false;
      nix.nixPath = [
        "pinned-nixpkgs=flake:pinned-nixpkgs"
        "nixpkgs=flake:pinned-nixpkgs"
      ];
      nix.channel.enable = false;
      nix.settings = {
        experimental-features = ["nix-command" "flakes"];

        flake-registry = pkgs.writeText "flake-registry.json" (builtins.toJSON {
          version = 2;
          flakes = [
            {
              from = {
                id = "pinned-nixpkgs";
                type = "indirect";
              };
              to = {
                type = "path";
                path = nixpkgs;
              };
            }
          ];
        });
      };
    })

    ({modulesPath, ...}: {
      imports = [
        # QEMU VM hardware configuration
        # (modulesPath + "/profiles/qemu-guest.nix")
        # QEMU VM options (virtualisation.*, fileSystems, bootloader, etc.)
        # (modulesPath + "/virtualisation/disk-image.nix")
        (modulesPath + "/virtualisation/qemu-vm.nix")
        # QEMU VM hardware configuration
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      virtualisation.diskSize = 1024 * 1; # 1gib
      virtualisation.memorySize = 1024 * 8;
    })
    ({...}: {
      services.openssh = {
        enable = true;
        settings = {
          # Options: "yes", "prohibit-password", "forced-commands-only", "no"
          # "prohibit-password" is highly recommended for security.
          PermitRootLogin = "yes";
        };
      };

      users.users.root = {
        password = "root";
      };
      networking.firewall.allowedTCPPorts = [22];
      virtualisation.forwardPorts = [
        {
          from = "host";
          host.port = 2221;
          guest.port = 22;
        }
      ];
    })
    ({pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        helix
        wget
      ];
    })
  ];
}
