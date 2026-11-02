#!/usr/bin/env bash
# vim: et ts=2 syn=bash
#
# Teleport sysext.
#

RELOAD_SERVICES_ON_MERGE="true"

# Teleport stopped publishing GitHub releases after v18.10.0 (and GitHub tags
# lag behind), so versions are listed from the official APT repo instead: one
# component per major (stable/vNN), each with its own Packages index.
function list_available_versions() {
  local repo="https://apt.releases.teleport.dev/ubuntu/dists/noble"
  local curl="curl -fsSL --retry-delay 1 --retry 60 --retry-connrefused"
  curl="$curl --retry-max-time 60 --connect-timeout 20"

  local component
  for component in $($curl "${repo}/Release" \
                       | sed -n -r 's/^Components:[[:space:]]*//p' \
                       | tr ' ' '\n' \
                       | grep -E '^stable/v[0-9]+$'); do
    $curl "${repo}/${component}/binary-amd64/Packages" \
      | awk '/^Package:/ { pkg = $2 } /^Version:/ && pkg == "teleport" { print $2 }'
  done \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    | sed 's/^/v/' \
    | sort -Vr \
    | uniq
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
