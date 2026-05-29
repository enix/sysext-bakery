#!/usr/bin/env bash
# vim: et ts=2 syn=bash
#
# Teleport sysext.
#

RELOAD_SERVICES_ON_MERGE="true"

function list_available_versions() {
  list_github_releases "gravitational" "teleport"
}
# --

function populate_sysext_root() {
  local sysextroot="$1"
  local arch="$2"
  local version="$3"

  local rel_arch
  rel_arch="$(arch_transform "x86-64" "amd64" "$arch")"

  curl --parallel --fail --silent --show-error --location \
       --remote-name "https://cdn.teleport.dev/teleport-${version}-linux-${rel_arch}-bin.tar.gz"

  mkdir -p "${sysextroot}/usr/bin"
  tar --force-local -xzf "teleport-${version}-linux-${rel_arch}-bin.tar.gz" \
      -C "${sysextroot}/usr/bin" --strip-components=1 teleport/teleport
}
# --
