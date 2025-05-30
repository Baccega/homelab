# 💻❄️ My's Homelab

This repo contains all my Nix configurations for all of the hosts that currently use nix in my homelab. I wanted a single repo that contained all the code for my homelab, but that I could deploy directly from my main laptop.

To deploy a new build to a remote machine I'm using [nixinate](https://github.com/MatthewCroughan/nixinate?tab=readme-ov-file) with the following command:

```
nix run .#apps.nixinate.HOSTNAME
```

## Hosts

All of the hostnames are 🐶 inspired.

- **Laika**: 🧪 My old laptop, used for testing out NixOS.

  The name comes of course from the famous [Soviet space dog](https://en.wikipedia.org/wiki/Laika), seemed fitting for a test laptop 😄

-
