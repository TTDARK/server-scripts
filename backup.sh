#!/bin/bash
SYNOLOGY_IP="100.88.245.84"
SYNOLOGY_MOUNT="/mnt/synology-backup"
if [ ! -d "$SYNOLOGY_MOUNT" ]; then
    echo "Creating mount point $SYNOLOGY_MOUNT..."
    sudo mkdir -p "$SYNOLOGY_MOUNT"
fi
DATE=$(date +%F-%H%M)
HOSTNAME=$(hostname)
ZIPFILE="$HOSTNAME-root-$DATE.zip"

echo "1. Mounting parent /volume1/backup-vps/..."
sudo mount -t nfs4 "$SYNOLOGY_IP:/volume1/backup-vps" "$SYNOLOGY_MOUNT"

echo "2. Checking $HOSTNAME folder..."
if [ ! -d "$SYNOLOGY_MOUNT/$HOSTNAME" ]; then
    echo "⚠️ Create $HOSTNAME folder manually on Synology first."
    sudo umount "$SYNOLOGY_MOUNT"
    exit 1
fi

echo "3. Creating ZIP of /root/ contents..."
BACKUP_DIR="$SYNOLOGY_MOUNT/$HOSTNAME"
TEMP_ZIP="/tmp/$ZIPFILE"

# ZIP contents of /root/ (fast single file)
# Silent ZIP: -q = quiet, redirect errors
cd /root && zip -rq "$TEMP_ZIP" * .??* >/dev/null 2>&1 || true

echo "4. Copying ZIP → $(du -h "$TEMP_ZIP" | cut -f1)..."
sudo cp "$TEMP_ZIP" "$BACKUP_DIR/$ZIPFILE"

# Cleanup temp ZIP
rm -f "$TEMP_ZIP"

# Cleanup: Remove ZIPs older than 14 days
sudo find "$BACKUP_DIR/" -name "*-root-20*.zip" -mtime +14 -delete 2>/dev/null || true

sudo umount "$SYNOLOGY_MOUNT"
echo "✅ Backup complete: $ZIPFILE"
