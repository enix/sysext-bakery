#!/bin/bash
#
# Ensure parity of Bakery releases and all extensions / release versions in release_build_versions.txt.
#
# Note that only new releases will be published; existing ones removed from release_build_versions.txt
#   will not be un-published.

set -euo pipefail
cd "$(dirname "$0")"
source "lib/libbakery.sh"

output="${GITHUB_OUTPUT:-releases_to_build.txt}"

echo
echo "Checking for new extension images to be built"
echo "============================================="
echo

mapfile -t images < <( sed -e 's:\s*#.*::' -e 's/[[:space:]]*$//' -e '/^$/d' release_build_versions.txt )

builds=()
extensions=()

for image in "${images[@]}"; do
  extension="${image% *}"
  version="${image#* }"

  if [ "${version}" = "latest" ] ; then
    unset version
    mapfile -t version < <( ./bakery.sh list "${extension}" --latest true )
  fi

  build_required="false"
  for v in "${version[@]}"; do
    echo -n "*  ${extension} ${v}: "

    # Enix: releases are per-major (e.g., teleport-v17), with version-stamped
    # asset filenames (teleport-v17.7.24-x86-64.raw). Check asset presence
    # on the per-major release instead of tag existence.
    major="${v%%.*}"
    if curl_api_wrapper \
         "https://api.github.com/repos/${bakery%/*}/${bakery#*/}/releases/tags/${extension}-${major}" 2>/dev/null \
       | jq -e --arg prefix "${extension}-${v}-" \
           '.assets[] | select(.name | startswith($prefix))' >/dev/null 2>&1; then
      echo "Bakery release exists."
      continue
    fi

    if [[ " ${builds[@]} " != *" ${extension}:${v} "* ]] ; then
      echo "Build required. "
      build_required="true"
      builds+=( "${extension}:${v}" )
    else
      echo "Build already scheduled. "
    fi
  done

  if [[ $build_required == true && " ${extensions[@]} " != *" ${extension} "* ]] ; then
    extensions+=( "${extension}" )
  fi
  unset version
done

cat >> "${output}" <<EOF
builds=$(jq -r -c -n --args '$ARGS.positional' "${builds[@]}")
extensions=$(jq -r -c -n --args '$ARGS.positional' "${extensions[@]}")
EOF
