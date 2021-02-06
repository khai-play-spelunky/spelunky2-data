#! /bin/bash
set -o errexit -o pipefail -o nounset
export WINEPREFIX="$HOME/.spelunky2.wine"

if [ -f /tmp/spelunky2.lock ]; then
  echo 'error: Lock file exits' >&2
  echo 'hint: If Spelunky 2 is running, wait for it to exit' >&2
  echo 'hint: If Spelunky 2 is not running, delete /tmp/spelunky2.lock' >&2
  notify-send 'Lock file exits' '/tmp/spelunky2.lock' --icon=dialog-error
  exit 1
fi

if ! touch /tmp/spelunky2.lock; then
  echo 'Failed to create lock file /tmp/spelunky2.lock' >&2
  notify-send 'Failed to create lock file' '/tmp/spelunky2.lock' --icon=dialog-error
  exit 1
fi

reenable_notification_banners=false
if [ "$(gsettings get org.gnome.desktop.notifications show-banners)" == 'true' ]; then
  notify-send 'Warning' 'Enabling Do-Not-Disturb' \
    --expire-time=2000 --icon=spelunky2
  sleep 2
  reenable_notification_banners=true
  gsettings set org.gnome.desktop.notifications show-banners false
fi

cd "$(dirname "$0")"
data_dir="$(realpath .)"
main_dir="$(realpath ..)/MAIN"
wine_dir="$(realpath ..)/wine"
sync_files() {
  for name in input.cfg local.cfg settings.cfg savegame.sav; do
    pretty-exec -- cp "$1/$name" "$2/$name"
  done
}
commit_message_file=$(mktemp --suffix='.log')
command=(
  time --format='Played for %E (%es)' --output="$commit_message_file"
  wine-env "$wine_dir"
  run-at "$main_dir"
  wine64 Spel2.exe
)
sync_files "$data_dir" "$main_dir"
pretty-exec -- "${command[@]}"
rm /tmp/spelunky2.lock
gsettings set org.gnome.desktop.notifications show-banners "$reenable_notification_banners"
sync_files "$main_dir" "$data_dir"
pretty-exec -- git add -v .
pretty-exec -- git commit --allow-empty --message="$(<"$commit_message_file")"
pretty-exec -- git push origin master
