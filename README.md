# Omalive

**A quiet, Omarchy-native view of the time you are living.**

Omalive turns your life into a visual scale. On first run it selects one random, fixed **Life Scale** between 95 and 120 years and shows where today falls within it. The scale is intended for reflection—it is not a lifespan estimate or prediction.

## Features

- Native Omarchy bar widget with an optional elapsed- or remaining-day counter
- Click-to-open summary panel with progress, dates, and life-scale statistics
- Life Ring view with the elapsed percentage centered in a circular progress ring
- Life-grid view in days, weeks, months, or years, fitted into one complete view
- First-run setup and Life Scale reveal
- Optional daily overlay, shown at most once per local calendar day
- Persistent identity, view, grid, bar, and overlay preferences
- Graceful beyond-scale display instead of negative remaining days
- Styling inherited from Omarchy Shell, including colors, fonts, spacing, borders, and controls
- Local-only operation with no network requests or external daemon

Omalive is implemented entirely as an Omarchy Shell plugin—no Electron, GTK application, Python GUI, or systemd timer is used.

## Requirements

- Omarchy 4.x
- Omarchy Shell / Quickshell

## Install

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

## Usage

Click the bar widget to open Omalive. The first launch asks for your name and birth date, then reveals the randomly selected Life Scale. That scale remains fixed unless you reset Omalive.

Use the settings button in the panel to configure:

| Setting | Default | Effect |
| --- | --- | --- |
| View | Summary | Switches between summary, Life Ring, and life-grid views |
| Grid unit | Weeks | Displays the grid in days, weeks, months, or years |
| Show day count in bar | On | Shows or hides the number beside the icon |
| Bar displays remaining days | Off | Switches the bar counter from days alive to days remaining |
| Daily display | On | Shows the overlay once per local calendar day |
| Show remaining days in panel | On | Shows or hides remaining days in summary views |

Changing your name or birth date preserves the current Life Scale. **Reset Omalive** clears the profile and generates a new scale after setup; the reset button requires a second click within three seconds.

## Local development

Validate the source tree:

```bash
omarchy plugin validate .
node tests/life.test.js

lint_root=$(mktemp -d)
ln -s /usr/share/omarchy/shell "$lint_root/qs"
/usr/lib/qt6/bin/qmllint -I "$lint_root" \
  Service.qml BarWidget.qml Panel.qml Overlay.qml \
  components/LifeProgress.qml components/LifeRing.qml \
  components/LifeStats.qml components/LifeGrid.qml
rm -rf "$lint_root"
```

Install a development copy (the destination must be a real directory, not a symlink, because Omarchy rejects symlinks in plugins):

```bash
plugin_dir="$HOME/.config/omarchy/plugins/io.github.midastruth.omalive"
rm -rf "$plugin_dir"
mkdir -p "$plugin_dir"
cp -a manifest.json Service.qml BarWidget.qml Panel.qml Overlay.qml \
  assets components js "$plugin_dir/"
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

## Privacy and data

Profile state is stored locally at:

```text
~/.local/state/omalive/state.json
```

It contains your name, birth date, fixed Life Scale, selected view and grid unit, display preferences, and the last daily display date. Omalive makes no network requests.

## Life math

All calendar calculations live in `js/Life.js`. Civil dates are converted to UTC day ordinals so daylight-saving transitions do not add or remove a day. A February 29 scale endpoint is clamped to February 28 in a non-leap endpoint year.

## Compatibility

Developed against Omarchy `4.0.3` / Quickshell. The plugin manifest uses schema version 1.

## License

MIT
