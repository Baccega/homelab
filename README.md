# 💻❄️ My's Homelab

This repo contains all my Nix configurations for all of the hosts that currently use nix in my homelab. I wanted a single repo that contained all the code for my homelab, but that I could deploy directly from my main laptop.

To deploy a new build to a remote machine I'm using [nixinate](https://github.com/MatthewCroughan/nixinate?tab=readme-ov-file) with the following command:

```
nix run .#apps.nixinate.HOSTNAME
```

## Hosts

All of the hostnames are 🐶 inspired.

- **Laika**: 🧪 My old laptop, used for testing out NixOS.

  Named after the famous [Soviet space dog](https://en.wikipedia.org/wiki/Laika), seemed fitting for a test laptop 😄

- **Zero**: 👻 A phantom machine, used for installing NixOS on a new host.

  Named after [Zero](https://the-nightmare-before-christmas.fandom.com/wiki/Zero), Jack's pet ghost-dog who serves of Tim Burton's The Nightmare Before Christmas

- **Max**: 🐶 My main server, very good boy.
