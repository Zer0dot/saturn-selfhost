# Saturn self-host

Run the whole Saturn stack locally in a hardware-isolated microVM — one command, no Docker, no root.

```sh
curl -fsSL https://raw.githubusercontent.com/Zer0dot/saturn-selfhost/main/install.sh | bash
saturn up
```

## Requirements

- x86_64 Linux with `/dev/kvm` (hardware virtualization)
- Unprivileged user namespaces enabled

`saturn up` checks both up front and prints the exact fix for anything missing.

## Commands

`saturn up` · `down` · `status` · `logs` · `update` (pull the latest Saturn) · `nuke` (clean slate)

## What it does

Pulls the Saturn OCI image, boots it in a [libkrun](https://github.com/containers/libkrun) microVM, and opens `http://localhost:8080`. State persists in `~/.saturn`; bring your own LLM API key in-app. Releases here carry the prebuilt AppImage/tarball — see each release's notes for bundled-component licenses and source.
