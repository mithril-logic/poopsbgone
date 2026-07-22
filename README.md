# poopsbgone

Remove macOS metadata from writable external volumes, with an exact dry run by default.

`poopsbgone` prepares SD cards, USB drives, camera cards, sampler media, and similar removable storage for use in non-Mac devices.

## Requirements

- macOS with `/bin/zsh`
- The macOS system tools `diskutil`, `plutil`, `find`, `stat`, and `rm`
- A writable external volume mounted directly below `/Volumes`

It does not support Linux, Windows, internal disks, read-only volumes, arbitrary directories, or volume subdirectories.

## Install

From the repository root:

```sh
mkdir -p "$HOME/.local/bin"
install -m 0755 bin/poopsbgone "$HOME/.local/bin/poopsbgone"
```

Ensure `$HOME/.local/bin` is on your `PATH`, then verify the installation:

```sh
poopsbgone --version
```

### Uninstall

```sh
rm -f "$HOME/.local/bin/poopsbgone"
```

## Usage

Preview cleanup:

```sh
poopsbgone /Volumes/SDCARD
```

Apply the reviewed cleanup:

```sh
poopsbgone --apply /Volumes/SDCARD
```

Apply cleanup and eject after success:

```sh
poopsbgone --apply --eject /Volumes/SDCARD
```

Quote paths containing spaces:

```sh
poopsbgone "/Volumes/My SD Card"
```

## Options

| Option | Behavior |
| --- | --- |
| `--apply` | Perform cleanup. Without this option, the command is a dry run. |
| `--eject` | Eject after a successful apply-mode cleanup. Dry runs never eject. |
| `--include-trashes` | Include the root-level `.Trashes` directory. |
| `--force-mac` | Permit APFS/HFS volumes; every other safety check remains enforced. |
| `--version` | Print the version and exit. |
| `-h`, `--help` | Print help and exit. |

Exactly one volume path is required. Use `--` before a path that begins with `-`.

## Cleanup behavior

A dry run lists the exact paths that would be removed. With `--apply`, `poopsbgone`:

1. removes `.DS_Store` and `._*` AppleDouble sidecar files recursively without crossing into nested filesystems; and
2. removes these entries when present at the volume root:
   - `.Spotlight-V100`
   - `.fseventsd`
   - `.metadata_never_index`
   - `.TemporaryItems`
   - `.DocumentRevisions-V100`

`.Trashes` is preserved unless `--include-trashes` is supplied:

```sh
poopsbgone --apply --include-trashes /Volumes/SDCARD
```

Review a dry run before applying cleanup. Back up irreplaceable data first.

## Safety

Before cleanup, the command requires the resolved target to:

- be the exact mount root of a volume below `/Volumes`;
- be reported by `diskutil` as external and writable; and
- use a non-APFS/HFS filesystem unless `--force-mac` is supplied.

It records the mount point, device identifier, and filesystem identity, then revalidates them before each destructive phase. Filesystem-confined traversal avoids descending into nested mounts. Recursive metadata files are deleted only as files; root-level targets use a separate confined routine.

`--force-mac` bypasses only the APFS/HFS refusal. It never permits internal disks, read-only volumes, paths outside `/Volumes`, or volume subdirectories.

## Output and errors

The command prints the inspected volume, path, filesystem, mode, and each planned or completed removal. Paths and volume metadata are shell-quoted so control characters cannot alter terminal output.

Dry-run messages begin with `Would remove:`. Apply-mode messages begin with `Removed:`. Missing targets produce no message.

Help, version, and successful cleanup exit with status `0`. Usage and explicit safety refusals exit with status `2`. A failed macOS system command exits nonzero and stops the operation. Requested ejection occurs only after cleanup succeeds.

## Testing

Run the non-destructive smoke test on macOS from the repository root:

```sh
test/smoke.zsh
```

The smoke test checks syntax, help, version output, parser failures, and the non-`/Volumes` safety boundary. CI also uses a disposable disk image to verify dry-run immutability, default and opt-in cleanup, sentinel preservation, and ejection. Never test `--apply` against media containing irreplaceable data.

## Contributing and support

Bug reports and focused pull requests are welcome. Include your macOS version, filesystem type, command, and sanitized output. Never include private file names, volume contents, or credentials.

For security-sensitive reports, use GitHub's private vulnerability reporting rather than a public issue.

This software is provided without warranty. Review a dry run and back up important media before applying cleanup.

## License

[MIT](LICENSE)
