# Test Plugin

A bundle of three Tern plugins: the root **Test Plugin** plus two internal
plugins, **Foo** and **Bar**.

Tern has no dependency resolution: a manifest cannot declare other plugins,
and `tern plugin install` copies exactly one package (a directory with
`plugin.toml` at its root). Tern's loader reads only the plugins folder's
direct children, so the copies inside this package stay inert until they are
installed. The root plugin therefore installs them itself.

## Layout

```
test-plugin/
├── plugin.toml     root package: id "test-plugin"
├── window.luau     installer + "Bundle status" command
├── foo/            installable on its own
│   ├── plugin.toml
│   └── window.luau
└── bar/            installable on its own
    ├── plugin.toml
    └── window.luau
```

## Install

Root only — brings foo and bar with it:

```sh
tern plugin install github.com/yurifrl/test-plugin
```

One at a time:

```sh
tern plugin install github.com/yurifrl/test-plugin/foo
tern plugin install github.com/yurifrl/test-plugin/bar
```

While developing:

```sh
tern plugin link /path/to/test-plugin
```

## How the root installs the payload

On every load (not `window_start`, which runs only once per window) the root
runs `tern plugin dir`, looks for `foo/plugin.toml` and `bar/plugin.toml` as
direct children of that folder, and installs at most one missing package from
its own installed copy with:

```sh
tern plugin install <this plugin's dir>/foo
```

That install makes the daemon reload every plugin; the root's next load runs
the same check, sees `foo`, installs `bar`, reloads again, and finally sees
both. Each pass re-reads the disk, so an interrupted pass resumes by itself,
and removing foo or bar reinstalls it on the next reload. `TERN_EXE`
overrides the `tern` binary the root calls.

`Test Plugin: Bundle status` in the palette reports whether foo and bar are
installed.

## Caveats

- Reloads are global: every install reloads all plugins in the window.
- Updating the root does not update foo/bar; reinstall them, or remove them
  and let the root reinstall its bundled copy.
- No version pinning: the bundled copies are whatever the installed root
  shipped.
