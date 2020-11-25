#! /bin/bash
set -o errexit -o pipefail -o nounset
export WINEPREFIX="$HOME/.spelunky2.wine"

cd "$(dirname "$0")"
data_dir="$(realpath .)"
main_dir="$(realpath ..)/MAIN"
sync_files=(input.cfg local.cfg settings.cfg savegame.sav)
commit_message_file=$(mktemp --suffix='.log')
command=(
  time --format='Played for %E (%es)' --output="$commit_message_file"
  wine-env "$(pwd)/wine"
  run-at "$main_dir"
  wine64 Spel2.exe
)
for name in "${sync_files[@]}"; do
  pretty-exec -- cp "$data_dir/$name" "$main_dir/$name"
done
pretty-exec -- "${command[@]}"

for name in "${sync_files[@]}"; do
  pretty-exec -- cp "$main_dir/$name" "$data_dir/$name"
done
pretty-exec -- git add -v .
pretty-exec -- git commit --allow-empty --message="$(<"$commit_message_file")"
pretty-exec -- git push origin master
