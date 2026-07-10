# SaltyOS Home Assistant Add-on

This repository contains a custom Home Assistant add-on that boots **SaltyOS** using QEMU and exposes the display through **noVNC** in a web browser.

The add-on runs:

```text
Home Assistant OS
└── SaltyOS Add-on
    └── QEMU
        └── saltyos.iso + persistent disk.img
            └── QEMU VNC on port 5900
                └── noVNC browser UI on port 6080
```

## Features

- Boots `saltyos.iso` using QEMU.
- Uses a bundled 32 MB `disk.img` as the seed disk.
- Copies the seed disk to `/data/disk.img` on first run so disk changes persist.
- Exposes raw VNC on port `5900`.
- Exposes noVNC browser access on port `6080`.
- Can be added to the Home Assistant sidebar using either add-on Ingress or `panel_iframe`.

## Repository layout

```text
ha-addon-saltyos/
├── repository.yaml
└── saltyos/
    ├── config.yaml
    ├── Dockerfile
    ├── run.sh
    ├── saltyos.iso
    ├── disk.img
    ├── index.html        # optional Ingress helper
    └── CHANGELOG.md
```

## Installation

1. Create a GitHub repository containing this add-on.
2. In Home Assistant, go to:

```text
Settings → Apps → Add-ons → Add-on Store → ⋮ → Repositories
```

3. Add your repository URL, for example:

```text
https://github.com/YOUR-GITHUB-USER/ha-addon-saltyos
```

4. Reload the add-on store.
5. Install the **SaltyOS** add-on.
6. Start the add-on.

## Accessing SaltyOS

After the add-on starts, noVNC should be available at:

```text
http://HOME_ASSISTANT_IP:6080/vnc.html
```

Example:

```text
http://10.0.10.2xx:6080/vnc.html
```

Raw VNC is available at:

```text
HOME_ASSISTANT_IP:5900
```

If the add-on is configured for Home Assistant Ingress, it may also appear as an app/sidebar entry using a URL similar to:

```text
http://homeassistant.local:8123/app/xxxx_saltyos
```

## Home Assistant add-on configuration

Example `saltyos/config.yaml`:

```yaml
name: SaltyOS
version: "1.0.4"
slug: saltyos
description: Boot SaltyOS in QEMU and expose it through noVNC
startup: services
boot: auto
init: false

arch:
  - amd64

ingress: true
ingress_port: 6080
ingress_stream: true
ingress_entry: index.html

panel_icon: mdi:console
panel_title: SaltyOS

ports:
  5900/tcp: 5900
  6080/tcp: 6080

ports_description:
  5900/tcp: Raw QEMU VNC
  6080/tcp: noVNC direct browser access

options: {}
schema: {}
```

## Dockerfile

Example `saltyos/Dockerfile`:

```dockerfile
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        qemu-system-x86 \
        qemu-utils \
        novnc \
        websockify \
        bash \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /saltyos

COPY saltyos.iso /saltyos/saltyos.iso
COPY disk.img /saltyos/disk.img.seed
COPY run.sh /run.sh
COPY index.html /usr/share/novnc/index.html

RUN chmod +x /run.sh

EXPOSE 5900
EXPOSE 6080

CMD ["/run.sh"]
```

If you are not using the optional Ingress helper, remove this line:

```dockerfile
COPY index.html /usr/share/novnc/index.html
```

## Runtime script

Example `saltyos/run.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

PERSISTENT_DISK="/data/disk.img"
SEED_DISK="/saltyos/disk.img.seed"

echo "Starting SaltyOS add-on..."

if [ ! -f "${PERSISTENT_DISK}" ]; then
    echo "No persistent disk image found."
    echo "Creating /data/disk.img from bundled seed disk..."
    cp "${SEED_DISK}" "${PERSISTENT_DISK}"
fi

echo "Using persistent disk: ${PERSISTENT_DISK}"

echo "Starting QEMU..."

qemu-system-x86_64 \
    -m 128 \
    -cdrom /saltyos/saltyos.iso \
    -drive file="${PERSISTENT_DISK}",format=raw,if=ide \
    -boot order=d \
    -display none \
    -vnc 0.0.0.0:0 \
    -no-reboot &

QEMU_PID=$!

echo "Starting noVNC on port 6080..."

websockify \
    --web=/usr/share/novnc/ \
    0.0.0.0:6080 \
    localhost:5900 &

WEBSOCKIFY_PID=$!

wait -n "${QEMU_PID}" "${WEBSOCKIFY_PID}"
```

## Optional Ingress helper

If noVNC loads in Home Assistant Ingress but fails to connect, add an `index.html` file to help noVNC use the correct WebSocket path.

Example `saltyos/index.html`:

```html
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>SaltyOS</title>
</head>
<body>
<script>
(function () {
  const currentPath = window.location.pathname;

  let basePath = currentPath;
  if (!basePath.endsWith("/")) {
    basePath = basePath.substring(0, basePath.lastIndexOf("/") + 1);
  }

  const wsPath = basePath.replace(/^\/+/, "") + "websockify";

  const params = new URLSearchParams(window.location.search);
  params.set("autoconnect", "true");
  params.set("resize", "scale");
  params.set("path", wsPath);

  window.location.replace(basePath + "vnc.html?" + params.toString());
})();
</script>
</body>
</html>
```

## Adding SaltyOS to the Home Assistant sidebar

### Option 1: Add-on sidebar / Ingress

If Ingress is enabled in `config.yaml`, go to the SaltyOS add-on page and enable:

```text
Show in sidebar
```

### Option 2: `panel_iframe`

If direct access works better than Ingress, add this to Home Assistant's `configuration.yaml`:

```yaml
panel_iframe:
  saltyos:
    title: SaltyOS
    icon: mdi:console
    url: "http://HOME_ASSISTANT_IP:6080/vnc.html"
    require_admin: false
```

Then restart Home Assistant.

## Updating the add-on

After changing files in GitHub:

1. Bump the version in `saltyos/config.yaml`.
2. Commit and push the change.
3. In Home Assistant, reload the add-on store.
4. Update/rebuild the add-on.
5. Restart the add-on.

Example:

```bash
git add .
git commit -m "Update SaltyOS add-on"
git push
```

## Changelog

Home Assistant may warn that the changelog is missing during add-on updates. Add a `CHANGELOG.md` file inside the `saltyos/` folder.

Example:

```markdown
# Changelog

## 1.0.4

- Added Ingress support and noVNC WebSocket path helper.

## 1.0.3

- Enabled Home Assistant Ingress support.
- Added noVNC WebSocket streaming support.

## 1.0.2

- Updated Web UI URL handling.

## 1.0.1

- Exposed noVNC on port 6080.
- Exposed raw VNC on port 5900.

## 1.0.0

- Initial SaltyOS Home Assistant add-on.
```

## Troubleshooting

### noVNC page loads but says `Failed to connect to server`

This usually means the noVNC web page loaded, but the WebSocket connection to QEMU failed.

Check that `config.yaml` includes:

```yaml
ingress_stream: true
```

Also test direct access:

```text
http://HOME_ASSISTANT_IP:6080/vnc.html
```

If direct access works but Ingress fails, use the optional `index.html` helper or use `panel_iframe` with the direct URL.

### Browser shows `RFB 003.008` on port 5900

That is normal if you open the raw VNC port in a web browser. It means QEMU's VNC server is alive.

Use noVNC instead:

```text
http://HOME_ASSISTANT_IP:6080/vnc.html
```

### Add-on does not appear in Home Assistant

Check that the GitHub repository layout is correct:

```text
repository.yaml
saltyos/config.yaml
```

Then reload the add-on store.

### Home Assistant says the changelog is missing

Add:

```text
saltyos/CHANGELOG.md
```

and bump the version in `config.yaml`.

## Notes

- The add-on uses the Home Assistant host IP, not the old standalone Docker/macvlan IP.
- `/data/disk.img` is persistent add-on storage.
- The bundled `disk.img` is only used as a seed on first run.
- If you want to reset the disk image, uninstalling the add-on or deleting its persistent data may be required.
