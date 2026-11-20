#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

source_repo=goome-ui/lua-goome

latest=$(gh api "repos/$source_repo/releases/latest" -q .tag_name)
latest=${latest#v}
old_rockspec=$(ls goome-*.rockspec | head -n1)
current=$(echo "$old_rockspec" | sed -n 's#^goome-\([0-9.]*\)-[0-9]*\.rockspec$#\1#p')
echo "latest $latest, pinned $current"

if ! [[ $latest =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || [ -z "$current" ]; then
  echo "cannot read a clean version, nothing to do"
  exit 0
fi
highest=$(printf '%s\n%s\n' "$latest" "$current" | sort -V | tail -n1)
if [ "$latest" = "$current" ] || [ "$highest" != "$latest" ]; then
  echo "up to date"
  exit 0
fi

new_rockspec=$(gh release view "v$latest" -R "$source_repo" --json assets -q '.assets[].name' | grep -E "^goome-$latest-[0-9]+\.rockspec$" | head -n1 || true)
if [ -z "$new_rockspec" ]; then
  echo "release v$latest has no rockspec yet, nothing to do"
  exit 0
fi

pin_version() {
  old_rockspec=$(ls goome-*.rockspec | head -n1)
  if [ "$old_rockspec" != "$new_rockspec" ]; then
    git rm -q -f "$old_rockspec"
  fi
  gh release download "v$latest" -R "$source_repo" -p "$new_rockspec" --clobber
  sed -i "s/goome-[0-9][0-9.]*-[0-9]*\.rockspec/$new_rockspec/g; s/LuaRocks grabs v[0-9][0-9.]*/LuaRocks grabs v$latest/" README.md CONTRIBUTING.md
}

smoke_test() {
  export GOOME_BACKEND=test
  luarocks install --local "$new_rockspec"
  eval "$(luarocks path --local)"
  rm -rf shots
  mkdir shots
  out=$(GOOME_TEST_SHOTS=shots GOOME_TEST_SCRIPT="screen 1280x720 1; 3 click 60,28; end 6" lua main.lua)
  echo "$out"
  ls shots | grep -q ppm
  rm -rf shots
}

pin_version
git add -A -- '*.rockspec' README.md CONTRIBUTING.md
git diff --cached --stat

if [ -z "${GOOME_NOSMOKE:-}" ]; then
  smoke_test
fi

if [ -n "${GOOME_DRY:-}" ]; then
  echo "dry run, not committing"
  exit 0
fi

git config user.name "$(git log -1 --format=%an)"
git config user.email "$(git log -1 --format=%ae)"

git commit -q -m "Bump goome to $latest"
git push -q origin HEAD:dev

git checkout -q -B main origin/main
pin_version
git add -A -- '*.rockspec' README.md CONTRIBUTING.md
if git diff --cached --quiet; then
  echo "main already pinned to $latest"
  exit 0
fi
git commit -q -m "Update to goome $latest"
git push -q origin main
