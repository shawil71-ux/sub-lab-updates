#!/bin/sh
# SUB-LAB updater (folder > Update SUB-LAB). Downloads the newest version over Wi-Fi from
# github.com/shawil71-ux/sub-lab-updates and swaps the files in place. Your projects and samples
# live elsewhere on the card, so they are never touched.
# Result line in update-result.txt:  ok <version> | same <version> | fail <reason>
cd "$(dirname "$0")" || exit 1
BASE="https://raw.githubusercontent.com/shawil71-ux/sub-lab-updates/main/trimui"
R=update-result.txt
rm -f "$R"
chmod +x ./fetch 2>/dev/null

get() {   # get <url> <file>: our own downloader first, then whatever the system has
  rm -f "$2"
  ./fetch get "$1" "$2" ./cacert.pem && [ -s "$2" ] && return 0
  command -v curl >/dev/null 2>&1 && curl -fsSL --max-time 300 -o "$2" "$1" && [ -s "$2" ] && return 0
  command -v wget >/dev/null 2>&1 && wget -q -O "$2" "$1" && [ -s "$2" ] && return 0
  return 1
}

rm -rf update && mkdir -p update
if ! get "$BASE/manifest.txt" update/manifest.txt; then
  echo "fail no connection (is Wi-Fi on?)" > "$R"; exit 1
fi
NEW=$(sed -n 's/^version //p' update/manifest.txt)
CUR=$(cat version.txt 2>/dev/null)
[ -n "$NEW" ] || { echo "fail the update list looks wrong" > "$R"; exit 1; }
if [ "$NEW" = "$CUR" ]; then echo "same $CUR" > "$R"; exit 0; fi

# manifest lines: file <sha256> <name>   (names are plain file names in this folder)
grep '^file ' update/manifest.txt > update/files.txt
while read -r k sha name; do
  case "$name" in */*|.*|"") continue ;; esac
  if [ -f "$name" ] && [ "$(./fetch sha "$name" 2>/dev/null)" = "$sha" ]; then continue; fi
  get "$BASE/$name" "update/$name" || { echo "fail could not download $name" > "$R"; break; }
  [ "$(./fetch sha "update/$name")" = "$sha" ] || { echo "fail $name arrived damaged, try again" > "$R"; break; }
done < update/files.txt
[ -f "$R" ] && exit 1

# everything arrived intact: swap the files in (the running program keeps its old copy until it quits)
for f in update/*; do
  n=$(basename "$f")
  case "$n" in manifest.txt|files.txt) continue ;; esac
  mv -f "$f" "./$n" || { echo "fail could not replace $n" > "$R"; exit 1; }
done
chmod +x ./sub-lab ./fetch ./launch.sh ./update.sh 2>/dev/null
echo "$NEW" > version.txt
sync
echo "ok $NEW" > "$R"
