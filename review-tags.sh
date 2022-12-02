#!/bin/bash

set -eo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: review-tags.sh <command>"
  exit
fi

BRANCH_FILE="$HOME/.rt"
branch_name=''

fetch_branch_name() {
  branch_name="$(cat "$BRANCH_FILE")"
  if ! git rev-parse "origin/$branch_name" > /dev/null 2>&1; then
    echo "origin/$branch_name does not exist"
    exit
  fi
}

command="$1"
case $command in
  s|stat|status)
    cat "$BRANCH_FILE"
    ;;

  sb|set-branch)
    if [ -z "$2" ]; then
      git branch -r | sed 's!origin/!!' | tr -d ' ' | fzf > "$BRANCH_FILE"
    else
      echo "$2" > "$BRANCH_FILE"
    fi
    ;;

  c|create)
    fetch_branch_name
    last_tag=$(git tag -l | grep "review/$branch_name" | tail -1)

    if [ -z "$last_tag" ]; then
      new_num="1"
    else
      if [ "$(git rev-parse "$last_tag")" = "$(git rev-parse "origin/$branch_name")" ]; then
        echo "$last_tag is same as origin"
        exit
      fi
      last_num="${last_tag##*/}"
      new_num=$((last_num + 1))
    fi

    new_branch="review/$branch_name/$new_num"
    git tag "$new_branch" "origin/$branch_name"
    echo "+ $new_branch"
    ;;

  l|list)
    fetch_branch_name
    git tag -l | grep "review/$branch_name"
    ;;

  d|diff)
    fetch_branch_name
    git range-diff origin/develop "review/$branch_name/$2" "review/$branch_name/$3"
    ;;

  co|checkout)
    fetch_branch_name
    git checkout "review/$branch_name/$2"
    ;;

  *)
    echo "Unknown command $command"
    exit 1
    ;;
esac
