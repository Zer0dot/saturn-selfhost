#!/usr/bin/env bash
# Saturn self-host installer.
#   curl -fsSL https://raw.githubusercontent.com/Zer0dot/saturn-selfhost/main/install.sh | bash
#
# Downloads the latest release, verifies its checksum, and installs the
# `saturn` command for the current user (no sudo).
#
# Env knobs:
#   SATURN_VERSION        install a specific version (default: latest)
#   SATURN_INSTALL_DIR    where the `saturn` command goes (default: ~/.local/bin)
#   SATURN_FORCE_TARBALL  =1 to skip the AppImage and use the tarball layout
set -euo pipefail
trap 'echo "ERROR: install.sh failed at line ${LINENO} (exit $?)" >&2' ERR

REPO="Zer0dot/saturn-selfhost"
INSTALL_DIR="${SATURN_INSTALL_DIR:-$HOME/.local/bin}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/saturn-selfhost"

if [ "$(uname -s)" = "Darwin" ]; then
    echo "ERROR: this installer is Linux-only. On macOS (Apple Silicon):" >&2
    echo "  brew tap zer0dot/saturn && brew install saturn" >&2
    exit 1
fi
if [ "$(uname -s)" != "Linux" ]; then
    echo "ERROR: Linux only (macOS ships via 'brew install saturn')." >&2
    exit 1
fi
ARCH="$(uname -m)"
if [ "${ARCH}" != "x86_64" ]; then
    echo "ERROR: ${ARCH} is not supported yet — x86_64 only today (arm64 is planned)." >&2
    exit 1
fi

# The AppImage needs the fusermount helper; fall back to the tarball without it.
use_tarball=0
if [ "${SATURN_FORCE_TARBALL:-0}" = "1" ]; then
    use_tarball=1
elif [ ! -e /dev/fuse ]; then
    use_tarball=1
elif ! command -v fusermount3 >/dev/null 2>&1 && ! command -v fusermount >/dev/null 2>&1; then
    use_tarball=1
fi

if [ "${use_tarball}" = "1" ]; then
    asset="saturn-${ARCH}.tar.gz"
else
    asset="saturn-${ARCH}.AppImage"
fi

if [ -n "${SATURN_VERSION:-}" ]; then
    base="https://github.com/${REPO}/releases/download/selfhost-v${SATURN_VERSION}"
else
    base="https://github.com/${REPO}/releases/latest/download"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

echo "→ downloading ${asset}"
curl -fL --retry 3 -o "${tmp}/${asset}" "${base}/${asset}"
curl -fL --retry 3 -o "${tmp}/SHA256SUMS" "${base}/SHA256SUMS"
(cd "${tmp}" && grep " ${asset}\$" SHA256SUMS | sha256sum -c -)

mkdir -p "${INSTALL_DIR}"
if [ "${use_tarball}" = "1" ]; then
    echo "→ installing tarball layout to ${DATA_HOME}"
    rm -rf "${DATA_HOME}/app.new"
    mkdir -p "${DATA_HOME}/app.new"
    tar -xzf "${tmp}/${asset}" -C "${DATA_HOME}/app.new" --strip-components=1
    rm -rf "${DATA_HOME}/app.old"
    [ -d "${DATA_HOME}/app" ] && mv "${DATA_HOME}/app" "${DATA_HOME}/app.old"
    mv "${DATA_HOME}/app.new" "${DATA_HOME}/app"
    rm -rf "${DATA_HOME}/app.old"
    ln -sfn "${DATA_HOME}/app/AppRun" "${INSTALL_DIR}/saturn"
else
    echo "→ installing AppImage to ${INSTALL_DIR}/saturn"
    # Same-directory rename: replaces a running `saturn` without ETXTBSY.
    staged="${INSTALL_DIR}/.saturn.tmp.$$"
    cp "${tmp}/${asset}" "${staged}"
    chmod 755 "${staged}"
    mv -f "${staged}" "${INSTALL_DIR}/saturn"
fi

echo "→ verifying"
"${INSTALL_DIR}/saturn" --version

case ":${PATH}:" in
*":${INSTALL_DIR}:"*) ;;
*)
    echo ""
    echo "NOTE: ${INSTALL_DIR} is not on your PATH. Add it:"
    echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
    ;;
esac

echo ""
echo "✓ installed. Start Saturn with:  saturn up"
