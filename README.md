# Omalive

**Omarchy-native life-scale visualization**

Omalive does not predict how long you will live. On first run it chooses one random, fixed **Life Scale** between 95 and 120 years, then shows where today sits within that scale.

## What v0.1 includes

- Native Omarchy bar widget (`11344d`)
- Click-to-open Quickshell panel
- First-run name and birth-date overlay
- Random, persistent Life Scale from 95–120 years
- One daily overlay, at most once per local calendar day
- Settings for identity, daily display, and remaining-day visibility
- Full reset as the only way to generate a new Life Scale
- Graceful beyond-scale display instead of negative remaining days
- Theme colors, fonts, spacing, borders, and controls from Omarchy Shell

No Electron, GTK application, Python GUI, systemd timer, or external daemon is used.

## Install

Once this repository is published:

```bash
omarchy plugin add https://github.com/midastruth/omalive.git --enable
```

Omalive defaults to the center section. Move it if desired:

```bash
omarchy bar move io.github.midastruth.omalive --section right
```

Open the panel or preview the daily overlay from the command line:

```bash
omarchy-shell omalive open
omarchy-shell shell summon io.github.midastruth.omalive '{"mode":"daily"}'
```

## Local development

Validate the source tree:

```bash
omarchy plugin validate .
node tests/life.test.js

lint_root=$(mktemp -d)
ln -s /usr/share/omarchy/shell "$lint_root/qs"
/usr/lib/qt6/bin/qmllint -I "$lint_root" \
  Service.qml BarWidget.qml Panel.qml Overlay.qml \
  components/LifeProgress.qml components/LifeStats.qml
rm -rf "$lint_root"
```

Install a development copy (the destination must be a real directory, not a symlink, because Omarchy rejects symlinks in plugins):

```bash
plugin_dir="$HOME/.config/omarchy/plugins/io.github.midastruth.omalive"
rm -rf "$plugin_dir"
mkdir -p "$plugin_dir"
cp -a manifest.json Service.qml BarWidget.qml Panel.qml Overlay.qml \
  components js "$plugin_dir/"
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.midastruth.omalive --section center
```

Files under `~/.config/omarchy/plugins/` hot-reload. If needed:

```bash
omarchy restart shell
```

## Architecture

```text
Omalive Service
 ├── profile persistence
 ├── daily once-only state
 ├── js/Life.js date calculations
 └── Overlay.qml (native top-level overlay entry)

BarWidget.qml
 └── Panel.qml (bar-anchored popup, like omarchy.clock)
```

The manifest declares three real entry kinds: `bar-widget`, `overlay`, and `service`. `Panel.qml` is owned by the live bar widget, following the anchored-popup pattern used by `omarchy.clock`; the fullscreen `Overlay.qml` is loaded and injected by the Omarchy plugin host. Keeping the panel nested is intentional because a bar-anchored popup needs the per-monitor widget instance as its anchor.

## Data

Profile state is stored locally at:

```text
~/.local/state/omalive/state.json
```

It contains the name, birth date, fixed Life Scale, display preferences, and the last daily display date. Omalive makes no network requests.

## Life math

All calendar calculations live in `js/Life.js`. Civil dates are converted to UTC day ordinals so daylight-saving transitions do not add or remove a day. A February 29 scale endpoint is clamped to February 28 in a non-leap endpoint year.

## Compatibility

Developed against Omarchy `4.0.3` / Quickshell. The plugin manifest uses schema version 1.

## License

MIT
