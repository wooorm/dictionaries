#!/bin/sh
ls dictionaries | while read -r dictionary; do
  prefix="$(pwd)/dictionaries/$dictionary"
  minor=$(git diff "$prefix/index.dic" "$prefix/index.aff" "$prefix/index.js")
  patch=$(git diff "$prefix")
  version=""

  cd "$prefix" || exit

  if [ "$minor" != "" ]; then
    version=$(npm version minor)
  elif [ "$patch" != "" ]; then
    version=$(npm version patch)
  fi

  if [ "$version" != "" ]; then
    echo "Publishing new version $version for $dictionary"
    # npm publish
  fi

  cd "../.." || exit
done
