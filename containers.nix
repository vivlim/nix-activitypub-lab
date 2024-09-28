{ config, pkgs, lib, ... }:
let
  consts = import ./consts.nix;
  addrs = consts.addrs;

  hostsEntriesFile = ''
  ${addrs.host} host
  ${addrs.inner} inner
  ${addrs.boundary} boundary
  ${addrs.outer} outer
  ${addrs.host} ${consts.hostnames.inner.host}
  ${addrs.host} ${consts.hostnames.inner.account-domain}
  ${addrs.host} ${consts.hostnames.boundary.host}
  ${addrs.host} ${consts.hostnames.boundary.account-domain}
  ${addrs.host} ${consts.hostnames.outer.host}
  ${addrs.host} ${consts.hostnames.outer.account-domain}
  '';

  containerCommonConfig = {
    autoStart = true;
    hostAddress = addrs.host;
    privateNetwork = true;
    config = {
      environment.systemPackages = let
      resetScript = pkgs.writeShellScriptBin "reset-gotosocial" ''
      set -ex
      echo "stopping gts."
      systemctl stop gotosocial
      echo "removing /var/lib/gotosocial/*"
      rm -rf /var/lib/gotosocial/*
      gtsPath=$(cat /etc/systemd/system/gotosocial.service | grep ExecStart | sed -r 's/^ExecStart=([^ ]*gotosocial).*$/\1/')
      configPath=$(cat /etc/systemd/system/gotosocial.service | grep ExecStart | sed -r 's/^.*config-path ([^ ]*).*$/\1/')
      echo "gts is at $gtsPath"
      echo "config is at $configPath"
      echo "starting gts"
      systemctl start gotosocial
      echo "taking a little nap"
      sleep 3;
      echo "trying to create admin account u:${consts.testcreds.username} p:${consts.testcreds.password} e:${consts.testcreds.email}"
      $gtsPath --config-path $configPath admin account create --username "${consts.testcreds.username}" --email "${consts.testcreds.email}" --password "${consts.testcreds.password}"
      sleep 1;
      echo "trying to elevate it to admin"
      $gtsPath --config-path $configPath admin account promote --username "${consts.testcreds.username}"
      sleep 1;
      echo "restarting gts."
      systemctl restart gotosocial
      '';

      in [ resetScript ];

      networking = {
        extraHosts = hostsEntriesFile;
        firewall = {
          enable = true;
          allowedTCPPorts = [ 80 ];
        };
        # Use systemd-resolved inside the container
        # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
        useHostResolvConf = lib.mkForce false;

      };

      services.gotosocial = {
        settings = {
          http-client = {
            allow-ips = ["10.0.0.0/8"]; # Allow connecting to caddy from the inside
            tls-insecure-skip-verify = true; # don't verify certs
          };
        };
      };
    };
  };
in
{
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-+"];
  };
  networking.extraHosts = hostsEntriesFile;
  containers.inner = lib.mkMerge [containerCommonConfig {
    localAddress = addrs.inner;
    bindMounts = {
      "/var/lib/gotosocial" = {
        hostPath = "/var/lib/gotosocial-inner";
        isReadOnly = false;
      };
    };

    config = {
      environment.systemPackages = with pkgs; [ gotosocial ];
      services.gotosocial = {
        enable = true;
        settings = {
          instance-federation-mode = "allowlist";
          application-name = "inner-gts";
          port = 80;
          bind-address = "0.0.0.0";
          protocol = "https"; # via caddy
          host = consts.hostnames.inner.host;
          account-domain = consts.hostnames.inner.account-domain;
          trusted-proxies = consts.addrs.host;
          log-level = "trace";
        };
      };
    };
  }];

  containers.boundary = lib.mkMerge [containerCommonConfig {
    localAddress = addrs.boundary;
    bindMounts = {
      "/var/lib/gotosocial" = {
        hostPath = "/var/lib/gotosocial-boundary";
        isReadOnly = false;
      };
    };

    config = {
      environment.systemPackages = with pkgs; [ gotosocial ];
      services.gotosocial = {
        enable = true;
        settings = {
          application-name = "boundary-gts";
          instance-federation-mode = "blocklist";
          port = 80;
          bind-address = "0.0.0.0";
          protocol = "https"; # via caddy
          host = consts.hostnames.boundary.host;
          account-domain = consts.hostnames.boundary.account-domain;
          trusted-proxies = consts.addrs.host;
          log-level = "trace";
        };
      };
    };
  }];

  containers.outer = lib.mkMerge [containerCommonConfig {
    localAddress = addrs.outer;
    bindMounts = {
      "/var/lib/gotosocial" = {
        hostPath = "/var/lib/gotosocial-outer";
        isReadOnly = false;
      };
    };

    config = {
      environment.systemPackages = with pkgs; [ gotosocial ];
      services.gotosocial = {
        enable = true;
        settings = {
          application-name = "outer-gts";
          instance-federation-mode = "blocklist";
          port = 80;
          bind-address = "0.0.0.0";
          protocol = "https"; # via caddy
          host = consts.hostnames.outer.host;
          account-domain = consts.hostnames.outer.account-domain;
          trusted-proxies = consts.addrs.host;
          log-level = "trace";
        };
      };
    };
  }];

  system.activationScripts.createContainerPaths = lib.stringAfter [ "var" ] ''
    mkdir -p /var/lib/gotosocial-inner
    mkdir -p /var/lib/gotosocial-boundary
    mkdir -p /var/lib/gotosocial-outer
  '';
}
