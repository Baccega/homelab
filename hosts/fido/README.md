# Fido

Fido serves `https://plex.baccegasandro.dev`. Caddy terminates HTTPS and sends
requests through Tailscale to TCP 32401 on Nemo. A socket on Nemo passes that
traffic to Plex on Max. The socket has no access to Nemo's other Caddy sites.

## Install and enroll

1. Install NixOS on the selected VPS. Keep its generated disk, boot, network,
   administrator access and `system.stateVersion` settings. Add
   `nixosModules.fido` from this flake to that system's modules. For a checkout of
   this repo, add `./hosts/fido/configuration.nix` to the VPS system's imports
   using the path relative to its configuration.
2. In the tailnet policy, give Fido a dedicated tag such as `tag:fido`. Allow
   that tag to reach only Nemo's Tailscale IPv4 address on `tcp:32401`. Review
   existing wildcard and group rules before enrolling Fido. Tailscale rules
   are additive, so a broad rule that matches Fido also grants its access.
   Add policy tests for the relay, Nemo's SSH and HTTPS ports, other tailnet
   peers and subnet routes. Enroll Fido with the restricted tag and record both
   its Tailscale addresses.
3. Add `homelab.fido = { ipv4 = "..."; ipv6 = "..."; };` to Nemo using Fido's
   assigned Tailscale addresses. Keep the option in the Nemo configuration
   used for subsequent rebuilds. Nemo leaves the relay off until both addresses
   are set. The relay accepts only Fido's IPv4 connection. Nemo drops other
   Fido traffic on both address families.
4. Allow inbound TCP 80 and 443 at the VPS provider. Point the public Plex A
   record at Fido and set the AAAA record only if Fido has working public IPv6.
   Review the current Cloudflare route and keep it available until you test the
   new route. Set Plex's Custom server access URLs to
   `https://plex.baccegasandro.dev` if clients need discovery through Fido.

Verify `https://plex.baccegasandro.dev/identity` and play media from outside the
LAN. Confirm Fido cannot connect to Nemo's SSH or shared HTTPS port, other
tailnet peers, or advertised LAN routes. Keep Plex authentication enabled.
Check that Plex requires authentication for requests from Nemo and its LAN.

To roll back, restore the previous public DNS/Cloudflare route, remove the Fido
grant, and clear `homelab.fido` on Nemo.
