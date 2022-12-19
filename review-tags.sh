#!/bin/bash

set -eo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: review-tags.sh <command>"
  exit 1
fi

branch_name=''

read_tracking_branch() {
  git for-each-ref --format='%(upstream:short)' "$(git symbolic-ref -q HEAD)"
}

fetch_branch_name() {
  branch_name=$(read_tracking_branch)
  if ! git rev-parse "$branch_name" > /dev/null 2>&1; then
    echo "$branch_name does not exist"
    exit 1
  fi
}

fetch_last_tag() {
  git tag -l | grep "review/$branch_name" | tail -1 || echo ""
}

fetch_default_branch() {
  for possible_default in develop master main; do
    if git rev-parse "origin/$possible_default" > /dev/null 2>&1; then
      echo "$possible_default"
      return
    fi
  done
  exit 1
}

command="$1"
case $command in
  s|stat|status)
    read_tracking_branch
    ;;

  c|create)
    fetch_branch_name
    last_tag=$(fetch_last_tag)

    if [ -z "$last_tag" ]; then
      new_num="1"
    else
      if [ "$(git rev-parse "$last_tag")" = "$(git rev-parse "$branch_name")" ]; then
        echo "$last_tag is same as upstream"
        exit 1
      fi
      last_num="${last_tag##*/}"
      new_num=$((last_num + 1))
    fi

    new_branch="review/$branch_name/$new_num"
    git tag "$new_branch" "$branch_name"
    echo "+ $new_branch"
    ;;

  l|list)
    fetch_branch_name
    git tag -l | grep "review/$branch_name" || echo "(none)"
    ;;

  rd|range-diff)
    fetch_branch_name
    git range-diff "$(fetch_default_branch)" "review/$branch_name/$2" "review/$branch_name/$3"
    ;;

  d|diff)
    fetch_branch_name
    git diff "review/$branch_name/$2" "review/$branch_name/$3"
    ;;

  co|checkout)
    fetch_branch_name
    if [ -z "$2" ]; then
      checkout_branch=$(fetch_last_tag)
    else
      checkout_branch="review/$branch_name/$2"
    fi
    echo "-> $checkout_branch"
    git checkout "$checkout_branch"
    ;;

  *)
    echo "Unknown command $command"
    exit 1
    ;;
esac
