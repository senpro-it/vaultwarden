{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.senpro.oci-containers.vaultwarden;

in

{

  options = {
    senpro = {
      oci-containers = {
        vaultwarden = {
          traefik = {
            fqdn = mkOption {
              type = types.str;
              default = "vaultwarden.local";
              example = "example.example.com";
              description = ''
                Defines the FQDN under which the predefined container endpoint should be reachable.
              '';
            };
          };
          vaultwarden = {
            admin-token = mkOption {
              type = types.str;
              default = "entez9k1s6NKUb2JSMbBDI533lPADswG";
              example = "DBxMebLhRxGGgdtMFESsAl35xS2pzrG2";
              description = ''
                Password for the Vaultwarden super admin. Should be at least 32 characters long. Remember that this password is stored unencrypted in the nix-store.
              '';
            };
            smtp = {
              host = mkOption {
                type = types.str;
                default = "smtp.host.local";
                example = "smtp.example.com";
                description = ''
                  FQDN of the mail server for sending mails via SMTP.
                '';
              };
              port = mkOption {
                type = types.port;
                default = 465;
                example = 587;
                description = ''
                  TCP port which vaultwarden uses to connect to the mail server.
                '';
              };
              from = mkOption {
                type = types.str;
                default = "info@vaultwarden.local";
                example = "vaultwarden@example.com";
                description = ''
                  FROM address which vaultwarden will use to send mails (Header FROM).
                '';
              };
              name = mkOption {
                type = types.str;
                default = "Vaultwarden";
                example = "Vaultwarden of Example Inc.";
                description = ''
                  Display name for the SMTP "FROM" header.
                  Setting `Vaultwarden` and `senpro.oci-containers.vaultwarden.vaultwarden.smtp.from` to `info@vault.warden` will result in `Vaultwarden <info@vault.warden>`
                '';
              };
              security = mkOption {
                type = types.enum [ "force_tls" "starttls" "off" ];
                default = "force_tls";
                description = ''
                  Whether Vaultwarden should use implicit or explicit TLS or not use TLS encryption at all.
                  See <https://github.com/dani-garcia/vaultwarden/wiki/SMTP-configuration> for further explanations about the possible values.
                '';
              };
              username = mkOption {
                type = types.str;
                default = "info@vaultwarden.local";
                example = "info@vault.warden";
                description = ''
                  Username for the login at the mail server defined under `senpro.oci-containers.vaultwarden.vaultwarden.smtp.host`.
                '';
              };
              password = mkOption {
                type = types.str;
                default = "Yo1iaKhe24K5jjTKObmE6lP6MSeHX4db";
                example = "Mmi4aKf8hHfwStd96RNcRdTjkyyZdbN1";
                description = ''
                  Password for the user specified under `senpro.oci-containers.vaultwarden.vaultwarden.smtp.username`.
                  The password should be at least 32 characters long. Remember that this password is stored unencrypted in the nix-store.
                '';
              };
            };
          };
        };
      };
    };
  };

  config = {
    virtualisation.oci-containers.containers = {
      vaultwarden = {
        image = "docker.io/vaultwarden/server:latest";
        extraOptions = [
          "--net=proxy"
        ];
        volumes = [
          "/srv/podman/vaultwarden/volume.d/vaultwarden:/data"
        ];
        environment = {
          INIT_ASSETS = "0";
          ADMIN_TOKEN = "${cfg.vaultwarden.admin-token}";
          DOMAIN = "https://${cfg.traefik.fqdn}";
          SIGNUPS_ALLOWED = "false";
          SMTP_HOST = "${cfg.vaultwarden.smtp.host}";
          SMTP_PORT = "${toString cfg.vaultwarden.smtp.port}";
          SMTP_FROM = "${cfg.vaultwarden.smtp.from}";
          SMTP_FROM_NAME = "${cfg.vaultwarden.smtp.name}";
          SMTP_SECURITY = "${cfg.vaultwarden.smtp.security}";
          SMTP_USERNAME = "${cfg.vaultwarden.smtp.username}";
          SMTP_PASSWORD = "${cfg.vaultwarden.smtp.password}";
          WEBSOCKET_ENABLED = "true";
        };
        autoStart = true;
      };
    };
    system.activationScripts = {
      makeVaultwardenBindVolDirectories = ''
        mkdir -p /srv/podman/vaultwarden/volume.d/vaultwarden
      '';
      makeVaultwardenTraefikConfiguration = ''
        printf '%s\n' \
        "http:"   \
        "  routers:"   \
        "    vaultwarden:" \
        "      rule: \"Host(\`${cfg.traefik.fqdn}\`)\"" \
        "      service: \"vaultwarden\"" \
        "      entryPoints:" \
        "      - \"https2-tcp\"" \
        "      tls: true" \
        "    vaultwarden-websocket:" \
        "      rule: \"Host(\`${cfg.traefik.fqdn}\`) && Path(\`/notifications/hub\`)\"" \
        "      service: \"vaultwarden-websocket\"" \
        "      entryPoints:" \
        "      - \"https2-tcp\"" \
        "      middlewares: \"vaultwarden-websocket\"" \
        "      tls: true" \
        "  services:" \
        "    vaultwarden:" \
        "      loadBalancer:" \
        "        passHostHeader: true" \
        "        servers:" \
        "        - url: \"http://vaultwarden:80\"" \
        "    vaultwarden-websocket:" \
        "      loadBalancer:" \
        "        passHostHeader: true" \
        "        servers:" \
        "        - url: \"http://vaultwarden:3012\"" \
        "  middlewares:" \
        "    vaultwarden-websocket:" \
        "      stripprefix:" \
        "        prefixes: \"/notifications/hub\"" \
        > /srv/podman/traefik/volume.d/traefik/conf.d/vaultwarden.yml
      '';
    };
  };

}
