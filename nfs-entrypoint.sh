#!/usr/bin/env bash

# This script checks environments variables and conditionally mounts NFS directories,
# then executes commands passed as docker command.
# NFS directories are mounted in userspace, using nfs-fuse.
#
# Example environment variables:
# NFS_ENABLED=true
# NFS_MOUNTS=/data/data:/data,/data2:/data2
# NFS_SERVER=nfs-server
#
# Then it executes command passed via docker args
#
# if NFS_ENABLED=false or not set, mounts are skipped.
#

set -e
# set -x

NFS_SETUP_TIMEOUT="${NFS_SETUP_TIMEOUT:=30}"

# Setup user account
USER_ID=${LOCAL_USER_ID:-10001}
GROUP_ID=${LOCAL_GROUP_ID:-10001}
USER_NAME=${LOCAL_USER_NAME:-iv}
GROUP_NAME=${LOCAL_GROUP_NAME:-iv}
addgroup  --gid $GROUP_ID $GROUP_NAME
adduser --uid $USER_ID --gid $GROUP_ID --no-create-home --disabled-login --gecos "" $USER_NAME

# Parse mount string and mount it
# Example input string: /data/data:/mnt/data
function nfs_mount() {
  IFS=":" read -r SRV_DIR MNT_DIR <<<"$1"
  echo "Mount $SRV_DIR to $MNT_DIR"
  mkdir -p "$MNT_DIR"
  chown $USER_NAME $MNT_DIR
  # Retry NFS mounts forever?
timeout $NFS_SETUP_TIMEOUT sh -- <<TIMEOUTCODE
  while ! fuse-nfs -a -n "nfs://$NFS_SERVER$SRV_DIR" -m "$MNT_DIR"; do
    echo "Failed to mount $NFS_SERVER$SRV_DIR"
    sleep 3
  done
TIMEOUTCODE
  echo "Done."
}

function check_nfs_env() {
  if [ -z "$NFS_SERVER" ]; then
    echo >&2 "NFS_SERVER is not set. Please check your configuration."
    exit 1
  fi
  if [ -z "$NFS_MOUNTS" ]; then
    echo >&2 "NFS_MOUNTS is not set. Please check your configuration."
    exit 1
  fi
}

if [ "$NFS_ENABLED" = true ]; then
  echo "NFS mounts enabled"
  check_nfs_env
  # Split and mount NFS_MOUNTS
  IFS=',' read -ra NFS_MOUNT <<<"$NFS_MOUNTS"
  for i in "${NFS_MOUNT[@]}"; do
    nfs_mount "$i"
  done
else
  echo "NFS mounts disabled"
fi

# Proceed with whatever else
echo "Proceed with command" "$@"
echo "Starting with UID : $USER_ID"
/bin/su-exec $USER_NAME "$@"
