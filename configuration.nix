{ pkgs
, config
, ...
}:
let
  domain = "pbcarrara.com.br";
  email = "piticarrara@gmail.com";
  trilliumPort = 2222;
  adguardPort = 3333;

  env = import ./env.nix;
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  nix.gc = {
    automatic = true;
    randomizedDelaySec = "14m";
    options = "--delete-older-than 1d";
  };


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
    enableReload = true;
    clientMaxBodySize = "40M";
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      "${domain}" = {
        forceSSL = true;
        enableACME = true;
        root = /root/wwwroot;
        locations."/".extraConfig = ''
          autoindex on;
          autoindex_exact_size off;
          autoindex_format html;
          autoindex_localtime on;
        '';
      };
      "library.${domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString trilliumPort}";
          proxyWebsockets = true;
          extraConfig =
            "proxy_ssl_server_name on;" +
            "proxy_pass_header Authorization;"
          ;
        };
      };
      "adguard.${domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString adguardPort}";
          proxyWebsockets = true;
          extraConfig =
            "proxy_ssl_server_name on;" +
            "proxy_pass_header Authorization;"
          ;
        };
      };
    };
  };

  services.shadowsocks = {
    enable = true;
    password = env.shadowsocks.password;
    port = 51992;
  };

  services.trilium-server = {
    enable = true;
    port = trilliumPort;
    instanceName = "The Library";
  };

  services.adguardhome = {
    enable = true;
    port = adguardPort;
  };

  networking = {
    firewall.enable = false;
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

  system.stateVersion = "23.11";
}
