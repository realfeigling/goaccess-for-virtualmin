#!/bin/sh
# Cron ticks once per minute; update-all.pl enforces the configured interval
# (including intervals longer than 60 minutes) using a persisted timestamp.
set -eu
[ "$(id -u)" -eq 0 ] || { echo 'Cron setup requires root' >&2; exit 1; }
module=/usr/share/webmin/virtualmin-goaccess
config=/etc/webmin/virtualmin-goaccess/config
[ -f "$config" ] || config="$module/config"
[ -f "$module/update-all.pl" ] || { echo 'Missing update-all.pl' >&2; exit 1; }
[ -d /etc/cron.d ] || { echo 'Missing /etc/cron.d' >&2; exit 1; }
interval=$(sed -n 's/^update_minutes=//p' "$config" | tail -n 1 | tr -d '\r')
case "$interval" in ''|*[!0-9]*) echo 'Invalid update_minutes' >&2; exit 1;; esac
[ "$interval" -ge 1 ] && [ "$interval" -le 10080 ] || { echo 'Interval must be 1..10080 minutes' >&2; exit 1; }
# Use an exact cron schedule only when the interval divides a day evenly.
# All other intervals are checked every minute by update-all.pl.
if [ "$interval" -eq 1 ]; then
  schedule="*/1 * * * *"
elif [ "$interval" -lt 60 ] && [ $((60 % interval)) -eq 0 ]; then
  schedule="*/$interval * * * *"
elif [ "$interval" -eq 60 ]; then
  schedule='0 * * * *'
elif [ "$interval" -eq 1440 ]; then
  schedule='0 0 * * *'
elif [ "$interval" -gt 60 ] && [ $((interval % 60)) -eq 0 ] && [ $((1440 % interval)) -eq 0 ]; then
  hours=$((interval / 60))
  schedule="0 */$hours * * *"
else
  schedule='* * * * *'
fi
tmp=$(mktemp /etc/cron.d/.virtualmin-goaccess.XXXXXX)
trap 'rm -f "$tmp"' EXIT HUP INT TERM
{
  printf '%s\n' "# Managed by Virtualmin GoAccess; configured interval: $interval minutes"
  printf '%s\n' 'SHELL=/bin/sh' 'PATH=/usr/sbin:/usr/bin:/sbin:/bin'
  printf '%s\n' "$schedule root /usr/bin/perl $module/update-all.pl >> /var/log/virtualmin-goaccess.log 2>&1"
} > "$tmp"
chmod 0644 "$tmp"
chown root:root "$tmp"
mv -f "$tmp" /etc/cron.d/virtualmin-goaccess
trap - EXIT HUP INT TERM
if command -v service >/dev/null 2>&1; then
  service cron status >/dev/null 2>&1 || service cron start || echo 'WARNING: cron not started' >&2
fi
if command -v update-rc.d >/dev/null 2>&1; then
  update-rc.d cron enable >/dev/null 2>&1 || echo 'WARNING: cron boot enable failed' >&2
fi
echo "GoAccess cron installed: $schedule (configured interval: $interval minute(s))"
