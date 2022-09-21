# vaultwarden
Configuration snippet for NixOS to spin up a vaultwarden container using Podman.

## :tada: `Getting started`

Clone the repository into the directory `/srv/podman/vaultwarden`. The path can't be changed for now!

Add the following statement to your `imports = [];` in `configuration.nix` and do a `nixos-rebuild`:

```
  /srv/podman/vaultwarden/default.nix {
    senpro.oci-containers.vaultwarden = {
      traefik.fqdn = "<your-fqdn>";
      vaultwarden = {
        admin-token = "<your-admin-token>";
        smtp = {
          host = "<smtp-fqdn>";
          port = <smtp-port>;
          from = "<smtp-from>";
          name = "<smtp-name>";
          security = "<smtp-security>";
          username = "<smtp-username>";
          password = "<smtp-password>";
        };
      };
    };
  }
```
