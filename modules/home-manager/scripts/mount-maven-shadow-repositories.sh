#!/bin/bash

set -e -o pipefail

XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.local/var/cache}"

BASE="${MAVEN_LOCAL_REPOSITORY:-$XDG_CACHE_HOME/m2/repository}"
BASE="$( realpath "$BASE" )"
DMG="${BASE}.dmg"
HDI_ATTACH_OPTS=( "-noverify" "-nobrowse" "-readwrite" "-noautoopen" )

declare -A SHADOWS

# Populate the associative array with mount points and their corresponding shadow files
for mountpoint in "$@"; do
  SHADOWS["$mountpoint"]="${mountpoint}.shadow"
done
[[ ${#SHADOWS[@]} -eq 0 ]] && exit 0

# Function to create or update the disk image
shadow:base:createOrUpdate() {
  if [ ! -f "$DMG" ]; then
    hdiutil create -fs APFS -volname "m2-base-repo" \
      -srcfolder "$BASE" "$BASE"
    return
  fi

  local mountpoint
  mountpoint=$(mktemp -d)
  trap 'shadow:detach "$mountpoint"' EXIT
  shadow:attach "$mountpoint"
  rsync -av --delete "$BASE/" "$mountpoint/"
}


# Function to mount a shadowed folder
shadow:mount() {
    local mountpoint="$1"
    # Skip if the mount point does not exist
    [[ ! -d "$mountpoint" ]] && return 1

    # Umount the mount point if it is already mounted
    
    # Mount the shadowed image
    local shadow="${SHADOWS[$mountpoint]}"
    shadow:attach "$mountpoint" "$shadow"
}

# Function to attach a shadow to a mount point
shadow:attach() {
  local mountpoint="$1"
  local shadow="$2"
  local opts=(  "${HDI_ATTACH_OPTS[@]}" )

  [[ -n "$shadow" ]] && opts+=( "-shadow" "$shadow" )

  hdiutil attach "${HDI_ATTACH_OPTS[@]}" -mountpoint "$mountpoint" "$DMG"
}

# Function to detach a shadow from a mount point
shadow:detach() {
  local mountpoint="$1"
  shadow:is_mounted "$mountpoint" && 
    return
  umount "$mountpoint"
}

# Function to check if a mount point is currently mounted
shadow:is_mounted() {
  local mountpoint="$1"
  hdiutil info -plist | yq -e -p xml '.images[].system-entities[] | select(.mount-point == "'"$mountpoint"'") | .mount-point' > /dev/null 2>&1
}

# Function to mount shadowed folders
shadow:folders:mount() {
  for mountpoint in "${!SHADOWS[@]}"; do
    shadow:mount "$mountpoint"
  done
}

# Main script execution
shadow:base:createOrUpdate
shadow:folders:mount
