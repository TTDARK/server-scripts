#!/bin/bash
GITHUB_RAW="https://raw.githubusercontent.com/TTDARK/server-scripts/main/backup.sh"
SCRIPT_PATH="/root/backup.sh"
LOG="/var/log/backup.log"

echo "🚀 Synology ZIP Backup Installer"

# 1. Hostname prompt (works when NOT piped)
if [ -t 0 ]; then
    # Interactive terminal detected
    read -p "Current hostname: $(hostname). Change? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "New hostname: " NEW_HOST
        hostnamectl set-hostname "$NEW_HOST"
        echo "✅ Hostname: $NEW_HOST (reboot later)"
    fi
else
    # Piped install - skip prompt
    echo "⚠️  Non-interactive mode - change hostname manually later"
fi

# 2. Download script
curl -fsL "$GITHUB_RAW" -o "$SCRIPT_PATH" || { echo "❌ Download failed!"; exit 1; }

# 3. Install dependencies
apt update -qq && apt install -y zip nfs-common >/dev/null 2>&1

# 4. Permissions
chmod +x "$SCRIPT_PATH"

# 5. Test run
echo "🧪 Testing backup (create Synology folder first)..."
"$SCRIPT_PATH"

# 6. Random cron 3:00-3:30
RANDOM_MIN=$(printf "%02d" $((RANDOM % 31)))
(crontab -l 2>/dev/null; echo "$RANDOM_MIN 3 * * * $SCRIPT_PATH >> $LOG 2>&1") | crontab -

# 7. Log setup
touch "$LOG" && chown root:root "$LOG"

echo ""
echo "🎉 INSTALLED!"
echo "📅 Cron: 3:${RANDOM_MIN} daily"
echo "📊 Logs: tail -f $LOG"
