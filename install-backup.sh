#!/bin/bash
# TTDARK/server-scripts backup installer

GITHUB_RAW="https://raw.githubusercontent.com/TTDARK/server-scripts/main/backup.sh"
SCRIPT_PATH="/root/backup.sh"
LOG="/var/log/backup.log"

echo "🚀 Synology ZIP Backup Installer"

# 1. PROMPT: Set proper hostname
read -p "Hostname '$CURRENT_HOST' OK? Change? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "New hostname: " NEW_HOST
    hostnamectl set-hostname "$NEW_HOST"
    echo "✅ Set: $NEW_HOST (reboot later)"
fi


# 2. Download script
curl -fsL "$GITHUB_RAW" -o "$SCRIPT_PATH" || {
    echo "❌ Download failed!"
    exit 1
}

# 3. Install dependencies
sudo apt update -qq && sudo apt install -y zip nfs-common >/dev/null

# 4. Permissions
chmod +x "$SCRIPT_PATH"

# 5. Test run
echo "🧪 Testing backup (create hostname folder on Synology first)..."
"$SCRIPT_PATH"

# 6. RANDOM cron 3:00-3:30
RANDOM_MIN=$((RANDOM % 31))
(crontab -l 2>/dev/null || true; echo "$RANDOM_MIN 3 * * * $SCRIPT_PATH >> $LOG 2>&1") | crontab -
RANDOM_MIN_DISPLAY=$(printf "%02d" $RANDOM_MIN)

# 7. Log setup
sudo touch "$LOG" && sudo chown root:root "$LOG"

echo "🎉 INSTALLED!"
echo "📅 Cron: ${RANDOM_MIN_DISPLAY}:00 daily (randomized)"
echo "📊 Logs: tail -f $LOG"
echo "📁 Script: $SCRIPT_PATH"
echo "🔄 Reboot recommended for hostname."
