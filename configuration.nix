{ config, pkgs, modulesPath, ... }:

{
  imports = [ 
    ./containers.nix 
    ./www.nix 
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  environment.shellInit = ''
    echo "failed units:"
    systemctl --failed
  '';
  services.getty.autologinUser = "viv";
  users.users.viv = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "test";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJsVWK+XuMD2hRYzPBRHUmeEcIUgHl7S6+6S6UcLMNQr vivlim@blue-channel"
    ];
  };
  networking.firewall.enable = false;
  security.sudo.defaultOptions = [ "NOPASSWD" ];
  services.openssh.enable = true;
  services.qemuGuest.enable = true;

  virtualisation.forwardPorts = [
    { from = "host"; guest.port = 22; host.port = 60022; }
    { from = "host"; guest.port = 80; host.port = 60080; }
    { from = "host"; guest.port = 443; host.port = 60443; }
  ];

  # copy this flake onto the vm in case we wanna iterate without rebuilding the whole thing.
  system.activationScripts.copySourceConfig = ''
    #if [ -z "$( ls -A '/etc/nixos" ]; then
      cp -rav ${./.}* /etc/nixos/
      chmod -R 700 /etc/nixos
    #fi
  '';

  system.stateVersion = "24.05";
}
