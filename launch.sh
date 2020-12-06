#! /bin/bash
set -o errexit -o pipefail -o nounset
export WINEPREFIX="$HOME/.spelunky2.wine"

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
sync_files "$main_dir" "$data_dir"
pretty-exec -- git add -v .
pretty-exec -- git commit --allow-empty --message="$(<"$commit_message_file")"
pretty-exec -- git push origin master
