{
  description = "activitypub test lab";

  inputs = { nixpkgs = { url = "github:NixOS/nixpkgs/nixos-24.05"; }; };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      supportedSystems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      eachSystem = f:
        nixpkgs.lib.genAttrs supportedSystems (system:
          f {
            pkgs = import nixpkgs { inherit system; };
            inherit system;
          });
    in rec {
      devShells = eachSystem ({ pkgs, system }: {
        default = pkgs.mkShell {
          packages = with pkgs; [ nix-prefetch-github nil nixfmt ];
        };
      });
      packages = eachSystem ({ pkgs, system }: let
        consts = import ./consts.nix;
      in {
        run = pkgs.writeShellScriptBin "run-vm" ''
          echo
          echo "if you didn't already, do 'nix run .#tunnel-port' to forward localhost:443, which is needed for this to work"
          echo "after the vm is up, go here:"
          echo "https://${consts.hostnames.host}"
          echo
          ${nixosConfigurations."${system}".lab.config.system.build.vm}/bin/run-nixos-vm

        '';
        tunnel-port = pkgs.writeShellScriptBin "tunnel-port" ''
          echo "starting socat as root to forward localhost:443 to :60443, which is forwarded to caddy in the vm"
          sudo ${pkgs.socat}/bin/socat tcp-l:443,fork,reuseaddr tcp:127.0.0.1:60443
        '';
      });
      nixosConfigurations = eachSystem ({ pkgs, system }: {
        lab = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs.inputs = inputs;
          modules = [
            ./configuration.nix
          ];
        };
      });
      apps = eachSystem ({ pkgs, system }: {
        default = {
          type = "app";
          program = "${packages."${system}".run}/bin/run-vm";
        };
      });
    };
}
