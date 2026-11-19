#!/bin/bash

# Collect selected Linux configuration into baseline/etc.

set -u

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "ERROR: Run this script from inside the Electryon_CP19 repository."
    exit 1
}

DEST="$REPO_ROOT/baseline"
MANIFEST="$DEST/collection_manifest.txt"

mkdir -p "$DEST"

if ! command -v rsync >/dev/null 2>&1; then
    echo "rsync is required. Install it with: sudo apt install rsync"
    exit 1
fi

# Individual configuration files
FILES=(
    /etc/anacrontab
    /etc/ca-certificates.conf
    /etc/crontab
    /etc/environment
    /etc/fstab
    /etc/hosts
    /etc/hostname
    /etc/issue
    /etc/issue.net
    /etc/login.defs
    /etc/nftables.conf
    /etc/nsswitch.conf
    /etc/sysctl.conf
)

# Configuration directories
DIRS=(
    /etc/apparmor.d
    /etc/cron.d
    /etc/cron.daily
    /etc/cron.hourly
    /etc/cron.monthly
    /etc/cron.weekly
    /etc/default
    /etc/depmod.d
    /etc/environment.d
    /etc/grub.d
    /etc/initramfs-tools
    /etc/ld.so.conf.d
    /etc/modprobe.d
    /etc/modules-load.d
    /etc/netplan
    /etc/network
    /etc/pam.d
    /etc/polkit-1
    /etc/rsyslog.d
    /etc/security
    /etc/systemd
    /etc/udev
    /etc/sysctl.d
)

echo "Collecting configuration from /etc..."
echo "Repository: $REPO_ROOT"

{
    echo "Configuration collection"
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo
} > "$MANIFEST"

copy_path() {
    local path="$1"

    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
        echo "[MISSING] $path" | tee -a "$MANIFEST"
        return
    fi

    if sudo rsync -aR \
        --exclude='*.key' \
        --exclude='*.keyfile' \
        --exclude='*.pem' \
        --exclude='ssh_host_*' \
        --exclude='auth.conf' \
        --exclude='auth.conf.d/' \
        "$path" "$DEST/"; then

        echo "[COPIED] $path" | tee -a "$MANIFEST"
    else
        echo "[ERROR] $path" | tee -a "$MANIFEST"
    fi
}

for path in "${FILES[@]}"; do
    copy_path "$path"
done

for path in "${DIRS[@]}"; do
    copy_path "$path"
done

# Restore ownership to the normal repository user.
sudo chown -R "$(id -u):$(id -g)" "$DEST"

echo
echo "Collection complete."
echo "Output: $DEST"
echo "Manifest: $MANIFEST"
