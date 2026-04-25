# Switch1 (MikroTik) Configuration

Declarative management of the MikroTik switch at `192.168.1.2`
(`constants.networkGear.switch1.ip`). Unlike the other hosts in this repo,
this one does **not** run NixOS — it runs RouterOS. The "config" here is a
single RouterOS script (`config.rsc`) that is the source of truth for the
device's state.

## Structure

```text
switch1/
├── config.rsc   # RouterOS export, source of truth (committed)
├── default.nix  # Defines the switch1 flake apps
└── README.md
```

## One-time setup

Install your SSH public key on the switch so the apps can authenticate
non-interactively via SSH:

Upload your SSH public key to the device's `Files` directory in the WEB-UI and link it to an admin user:

```routeros
/user ssh-keys import public-key-file=id_rsa.pub user=YOUR_USERNAME
```

## Workflow

1. **Pull the live config** into the repo (do this first, before any deploy):

   ```bash
   nix run .#switch1-export
   git diff -- hosts/switch1/config.rsc
   ```

2. **Edit `config.rsc`** by hand (or via WinBox/WebFig, then re-run
   `switch1-export` to capture the changes).

3. **Deploy** the local file and choose how to apply it:

   ```bash
   nix run .#switch1-deploy
   ```

   This will:
   - Pull the live config and show a unified diff vs the local file.
   - Ask for a deploy mode: `incremental`, `full`, or `abort`.

   `incremental` will:
   - `scp` `config.rsc` to `flash/config.rsc` on the device.
   - Run `/import file-name=flash/config.rsc`.
   - Avoid resetting the switch, so SSH host keys and users are preserved.

   This is safer for day-to-day changes, but it is not a true clean rebuild:
   config that exists on the switch but is no longer present in `config.rsc`
   may remain.

   `full` will:
   - Prompt for the exact phrase `full erase switch1`.
   - Upload `config.rsc`.
   - Run `/system/reset-configuration keep-users=yes no-defaults=yes
     skip-backup=yes run-after-reset=flash/config.rsc`.
   - Preserve RouterOS users, but wipe other device config not present in
     `config.rsc`.
   - Reboot the switch and cause a ~30-60s outage.

## Port map (physical connections)

Current cabling (documented here so you don’t have to infer it from the config):

- **ether1**: Nemo
- **ether2**: AP1
- **ether3**: (unused)
- **ether4**: Hachiko
- **ether5**: (unused)
- **ether6**: Apple TV
- **ether7**: Max
- **ether8**: (unused)
- **sfp9**: (unused)
- **sfp10**: (unused)
- **sfp11**: (unused)
- **sfp12**: (unused)

## Notes

- `config.rsc` is exported with `/export show-sensitive`, so it includes
  WPA passphrases, RADIUS shared secrets, and the like. If you want those
  out of git, switch to plain `/export` and manage the sensitive bits via
  sops separately.
- MikroTik's `/export` output starts with a comment preamble containing
  timestamp, software ID, model, and serial number; the apps strip all leading
  comment lines so that information is not committed and diffs stay stable.
- The `incremental` deploy mode should not regenerate the SSH host key. The
  `full` deploy mode performs a reset; if SSH complains about a host key
  mismatch afterward, remove the old entry with `ssh-keygen -R 192.168.1.2`.
