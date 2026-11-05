# sbox-arch

![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)
![OS: Arch Linux](https://img.shields.io/badge/OS-Arch%20Linux-1793D1?logo=arch-linux&logoColor=white)
![AUR: paru](https://img.shields.io/badge/AUR_Helper-paru-1793D1)

**`sbox-arch`** is a modular seedbox and media server management solution built specifically for **Arch Linux**.

This project is an independent, heavily modified conversion of **[Swizzin](https://github.com/swizzin/swizzin)**. Full credit and appreciation go to the original [Swizzin](https://github.com/swizzin/swizzin) authors and contributors for designing a clean, modular bash-based seedbox toolkit on Debian/Ubuntu. **`sbox-arch`** adapts and re-engineers that foundation exclusively for Arch Linux (`pacman` and `paru`), with ongoing customization of the included software stack and installers.

> **Note:** Because this is a standalone Arch Linux conversion and personal fork, **do not** report issues or request support from the upstream Swizzin project.

---

## Key Differences from Upstream Swizzin

- **Arch Linux Exclusive (`x86_64` & `aarch64`)**: Replaces all `apt`/`dpkg` package management, Debian/Ubuntu repository handling, and codename pins with native Arch Linux equivalents (`pacman` and `vercmp`).
- **Automated AUR Support via `paru`**: Automatically bootstraps `paru` and executes AUR builds using a dedicated, unprivileged system build user (`_swizzin_aur`) when installers are run as `root`.
- **Arch System Conventions**:
  - Web server and PHP-FPM run under the native Arch `http` user/group (`/run/php-fpm/php-fpm.sock`, `php-fpm.service`, `/etc/php/php.ini`).
  - Administrative privileges use the `wheel` group (`/etc/sudoers.d/wheel`).
  - Unprivileged daemon accounts use `nobody` and standard `useradd`/`userdel` tooling.
- **Native Arch & AUR Packages Preferred**: Uses official Arch repository and AUR packages wherever possible (`deluge`, `qbittorrent-nox`, `rtorrent`, `transmission-cli`, `jellyfin-server`, `syncthing`, `rclone`, `wireguard-tools`, `znc`, etc.).

---

## Requirements

- A fresh or existing **Arch Linux** installation (`x86_64` or `aarch64`).
- Root privileges (`su -` or `sudo -i`).

---

## Installation

Make sure you are logged in with a full root login environment (`su -` or `sudo -i` rather than plain `su`).

### Quick Start (Interactive)

Using `curl`:
```bash
bash <(curl -sL https://raw.githubusercontent.com/pat-e/sbox-arch/master/setup.sh) && . ~/.bashrc
```

Using `wget`:
```shell
bash <(wget -qO - https://raw.githubusercontent.com/pat-e/sbox-arch/master/setup.sh) && . ~/.bashrc
```

### Installing from a Local Clone (Development / Private Repo)

If you want to customize scripts locally before installing, clone the repository and pass `--local`:

```bash
git clone https://github.com/pat-e/sbox-arch.git
sudo bash sbox-arch/setup.sh --local && . ~/.bashrc
```

### Unattended Installation

Specify the master user, password, and desired packages directly via CLI flags:

```bash
bash <(curl -sL https://raw.githubusercontent.com/pat-e/sbox-arch/master/setup.sh) \
  --unattend qbittorrent nginx panel --user tester --pass test1234
```

Or use an environment configuration file (see [unattended.example.env](unattended.example.env)):

```bash
bash <(curl -sL https://raw.githubusercontent.com/pat-e/sbox-arch/master/setup.sh) \
  --env /path/to/your/config.env
```

---

## Managing Your Server with `box`

Once installed, the `box` command is available in your `PATH`:

| Command | Description | Example |
| :--- | :--- | :--- |
| `box` | Launch the interactive Whiptail package manager UI | `box` |
| `box list` | List all available application packages and descriptions | `box list` |
| `box install <pkg...>` | Install one or more applications | `box install nginx qbittorrent jellyfin` |
| `box remove <pkg...>` | Remove one or more installed applications | `box remove sonarr radarr` |
| `box upgrade <pkg...>` | Run the upgrade script for one or more packages | `box upgrade nginx deluge` |
| `box update` | Pull the latest `sbox-arch` changes and run update hooks | `box update` |
| `box adduser <user>` | Create a new user account | `box adduser alice` |
| `box deluser <user>` | Delete a user account and its associated data | `box deluser alice` |
| `box chpasswd <user>` | Change a user's system, web, and client passwords | `box chpasswd alice` |
| `box rtx` | Manage ruTorrent plugins and themes interactively | `box rtx` |

---

## Customizing Packages (Adding or Removing Software)

`sbox-arch` discovers available packages dynamically from the filesystem, making it straightforward to strip out unwanted applications or add your own software:

1. **Removing an application from the catalog**:
   - Delete its scripts from:
     - `scripts/install/<app>.sh`
     - `scripts/remove/<app>.sh`
     - `scripts/nginx/<app>.sh` (if applicable)
     - `scripts/update/<app>.sh` and `scripts/upgrade/<app>.sh` (if applicable)
2. **Adding a new application**:
   - Create `scripts/install/<app>.sh` (ending with `touch /install/.<app>.lock`) and `scripts/remove/<app>.sh` (ending with `rm -f /install/.<app>.lock`).
   - Use `pac_install <pkg>` for official Arch repository packages or `aur_install <pkg>` to install from the AUR via `paru`.
   - Optionally add `scripts/nginx/<app>.sh` for Nginx reverse-proxy configuration and a description entry in `sources/lang_en`.

---

## Credits & License

- **Upstream Foundation**: [Swizzin](https://github.com/swizzin/swizzin) (and original QuickBox contributors where noted in script headers).
- **License**: Licensed under the [GNU General Public License v3.0 (GPL-3.0)](LICENSE).
