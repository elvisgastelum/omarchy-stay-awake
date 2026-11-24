# Stay Awake for Omarchy

A coffee mug in the [Omarchy](https://omarchy.org/) bar that keeps your system
awake, with no screensaver and no idle lock. It can stay on until you turn it
off, or run on a timer with a countdown.

- **Left-click:** stay awake until you click again.
- **Right-click:** cycle through timed presets (30 min → 1 h → 2 h → off).
  The time left shows next to the mug, and idle lock comes back on by itself
  when it runs out.
- The tooltip says what the next click will do. It's in English and Spanish
  and follows your Omarchy language.

It uses the same state as Omarchy's built-in stay-awake indicator and
`omarchy toggle idle`, so they always agree. Turning stay-awake off from
either of them also cancels a running timer, and a running timer survives a
shell restart.

## Install

On an Omarchy system:

```bash
omarchy plugin add https://github.com/elvisgastelum/omarchy-stay-awake.git --enable
```

Or from a clone of this repo:

```bash
make install
```

The widget goes in `centerEnd`, beside the clock. To move it:

```bash
omarchy bar move elvisgastelum.stay-awake --section right
```

## Settings

Open the widget's settings from the bar editor, or set them from the command
line:

| Key             | Default     | Meaning                                              |
|-----------------|-------------|------------------------------------------------------|
| `presets`       | `30,60,120` | Comma-separated minutes that right-click cycles through |
| `showCountdown` | `true`      | Show the time left next to the mug                   |

```bash
omarchy bar set elvisgastelum.stay-awake presets "15,45,90"
```

## Make targets

```text
make install    Install from GitHub and put it on the bar
make update     Pull the latest version of the installed plugin
make uninstall  Remove the plugin
make enable     Put the widget on the bar
make disable    Take the widget off the bar
make test       Run the model tests and check the JSON files parse
make validate   Validate the manifest against Omarchy's plugin schema
make check      Run test and validate
make dev        Copy this working tree over the installed plugin and restart the shell
```

`make test` needs `node` and `jq`.

## How it works

Omarchy doesn't give bar widgets direct access to its idle service, so this
plugin uses the public interface:

- It changes state with `omarchy-toggle-idle stay-awake|allow-idle`.
- It reads state from the file the idle service itself watches:
  `~/.local/state/omarchy/indicators/stay-awake`.
- It stores a timer's deadline in
  `~/.local/state/omarchy/elvisgastelum.stay-awake/timer`.

## License

MIT
