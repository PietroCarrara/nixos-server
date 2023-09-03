{ pkgs
, ...
}:
let
  dns = import (builtins.fetchTarball "https://github.com/kirelagin/dns.nix/archive/master.zip");
  domain = "pbcarrara.com.br";
  ipv4 = "162.248.102.209";
  email = "piticarrara@gmail.com";

  stargatePort = 1111;
in
{
  imports = [
    ./hardware-configuration.nix
    ./unstable/gotosocial.nix
  ];

  programs = {
    git = {
      enable = true;
      config = {
        user.name = "Pietro Carrara";
        user.email = "pbcarrara@inf.ufrgs.br";
      };
    };
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = email;
  services.nginx = {
    enable = true;
    clientMaxBodySize = "40M";
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      "${domain}" = {
        forceSSL = true;
        enableACME = true;
      };
      "stargate.${domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString stargatePort}";
          proxyWebsockets = true;
          extraConfig =
            "proxy_ssl_server_name on;" +
            "proxy_pass_header Authorization;"
          ;
        };
      };
    };
  };

  services.gotosocial = {
    enable = true;
    package = pkgs.callPackage ./pkgs/gotosocial.nix { };
    setupPostgresqlDB = true;
    settings = {
      application-name = "Stargate";
      host = "stargate.${domain}";
      port = stargatePort;
      accounts-registration-open = false;
      media-description-min-chars = 1;
      media-description-max-chars = 1500;
    };
  };

  services.bind = {
    enable = true;
    zones = {
      "pbcarrara.com.br" = {
        master = true;
        file = pkgs.writeText "${domain}.zone" (dns.lib.toString domain (with dns.lib.combinators; {
          SOA = {
            nameServer = "dns.${domain}.";
            adminEmail = email;
            serial = 2023090200;
          };

          NS = [
            "dns.${domain}."
          ];

          A = [
            { address = ipv4; ttl = 60 * 60; }
          ];

          subdomains = let self = host ipv4 null; in {
            dns = self;
            stargate = self;
          };
        }));
      };
    };
  };

  networking = {
    firewall.enable = false;
    nameservers = [
      "8.8.8.8"
      "4.4.4.4"
    ];
  };

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = false;
  networking.hostName = "hope";
  networking.domain = "";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOi+CZumNvuUVU+TPJ26CDdYAzKkaQ2YJ9EnFa172VRO pbcarrara@inf.ufrgs.br''
    ''ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCwdtnVDxmDeNFM5YH4wsa1k9qTLlYcbAuqXtZUbwkZdLzvfdkMav8OH2mMra9lkEjBKgjniGmvCaGYXyPINVD4a7J9UKlaNVExXJ4PzVMbM/3Kvjo0WcMKh/mQKeLmF6aYBIOjyO0V4JsbiSb9N4lleD9mPD5NSJSCphZuMYzuSILj7C9X46/0bQSqW3vp61YAWzetdNnyYwTFVnibr2w2U7WRIXFDUvJX5oRSvI2QLn1bn9J5zaRbT6FwgIIfeliAI4rrwIWmLhfeAOz8X+dTwaC/Jb3cFXf4CtQhO0+aLzR236q4nqAheW7xhSidzavhq12kFGRmupMbCj9skCf7m0HFkwPABuw0AY/j5DwVTTuhuAgoYyjKlFxbX7vm+3puqJNh9DO2S0DHetEQykhAP+PRiHLpWZXKQ5+ZdVHQatGOiJxuSTUs3yBQPy0V4vA9sQu6fsB1x1l658/rv+fIy9DYgFHpAfsjyH5iEIJKwwzMCSAbuTLPi7zRoyTdsR8= pietro@hope''
  ];

  system.stateVersion = "23.05";
}
