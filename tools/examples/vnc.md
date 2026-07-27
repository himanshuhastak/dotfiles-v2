# VNC (TigerVNC) — optional remote desktop on Linux hosts

## Resolution / different monitors

**Recommended (automatic):** do not set `geometry` in `~/.vnc/config`.

1. `vncpasswd` then `vncstart` (or `vncserver :2 -noreset`)
2. Connect with TigerVNC Viewer on Windows
3. **Resize the viewer window** or **fullscreen** — the server accepts client
   resize (`AcceptSetDesktopSize`, on by default in TigerVNC 1.15)

Each monitor can use fullscreen; no fixed 1920×1080 in dotfiles.

**TigerVNC Viewer (Windows):** Options → Screen → enable scaling / resize remote
session to window if your build exposes it.

## Fixed geometry (optional)

When you need a specific framebuffer size at start:

```sh
vncstart -g 2560x1440
# or
export VNC_GEOMETRY=3840x2160
vncstart
```

Or copy `tools/examples/vnc.local.example` → `local/profile/vnc.local`.

## Basics

Dotfiles stows `~/.vnc/xstartup` and `~/.vnc/config` only when `~/.vnc` is not
already set up. Secrets stay local (`vncpasswd` → `~/.vnc/passwd`).

```sh
vncpasswd
vncstart              # display :2 → port 5902
vncserver -list
vncserver -kill :2
```

## SSH tunnel (Windows)

Put `LocalForward 5902 127.0.0.1:5902` in `local/profile/ssh.local` for your
work host, or use Cursor Ports panel. Start VNC **before** opening the viewer.

Corporate hosts may prefer Nice DCV instead of raw VNC.
