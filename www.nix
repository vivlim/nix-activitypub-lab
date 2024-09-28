{ config, pkgs, ... }:

{
  services.caddy = let
  consts = import ./consts.nix;
  in {
    enable = true;
    configFile = pkgs.writeText "Caddyfile" ''
    {
      local_certs
    }

    ${consts.hostnames.host} {
      reverse_proxy /api/* localhost:44001
      root * ${./www}
      file_server browse
    }

    ${consts.hostnames.inner.host} {
      reverse_proxy inner:80 {
        # Remove CSP header so assets aren't blocked.
        header_down -Content-Security-Policy
      }

      header {
        Content-Security-Policy upgrade-insecure-requests
      }
    }
    '';
  };

  systemd.services.shell2http = {
    requiredBy = [ "caddy.service" ];
    serviceConfig = {
      User = "root";
      ExecStart = pkgs.writeShellScript "launch.sh" ''
      ${pkgs.shell2http}/bin/shell2http -port=44001 -include-stderr -shell="${pkgs.bash}/bin/bash" -form \
        /api/journal 'journalctl -u $v_unit' \
        /api/containerjournal '/run/current-system/sw/bin/nixos-container run $v_c -- journalctl -u $v_unit' \
        /api/containersystemctl '/run/current-system/sw/bin/nixos-container run $v_c -- systemctl $v_verb $v_unit' \
        /api/resetcontainer '/run/current-system/sw/bin/nixos-container run $v_c -- reset-gotosocial' \
        /api/poweroff 'poweroff'
      '';
    };
  };

}
