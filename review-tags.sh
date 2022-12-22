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

read_tracking_remote() {
  git for-each-ref --format='%(upstream:remotename)' "$(git symbolic-ref -q HEAD)"
}

fetch_branch_name() {
  branch_name=$(read_tracking_branch)
  if ! git rev-parse "$branch_name" > /dev/null 2>&1; then
    echo "$branch_name does not exist"
    return 1
  fi
}

fetch_last_tag() {
  git tag -l | grep "review/$branch_name" | tail -1 || echo ""
}

fetch_default_branch() {
  for possible_default in develop master main; do
    possible_default_upstream="$(read_tracking_remote)/$possible_default"
    if git rev-parse "$possible_default_upstream" > /dev/null 2>&1; then
      echo "$possible_default_upstream"
      return
    fi
  done
  return 1
}

create_review_tag() {
  last_tag=$(fetch_last_tag)

  if [ -z "$last_tag" ]; then
    new_num="1"
  else
    if [ "$(git rev-parse "$last_tag")" = "$(git rev-parse "$branch_name")" ]; then
      echo "$last_tag is same as upstream"
      return
    fi
    last_num="${last_tag##*/}"
    new_num=$((last_num + 1))
  fi

  new_branch="review/$branch_name/$new_num"
  git tag "$new_branch" "$branch_name"
  echo "+ $new_branch"
}

command="$1"
case $command in
  s|stat|status)
    read_tracking_branch
    ;;

  c|create)
    fetch_branch_name
    create_review_tag
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

  p|pull)
    git fetch
    if [ -n "$2" ]; then
      git checkout "$2"
    fi
    fetch_branch_name
    create_review_tag
    git reset --keep "$(read_tracking_branch)"
    ;;

  g|goto)
    fetch_branch_name
    if [ -z "$2" ]; then
      checkout_branch=$(fetch_last_tag)
    else
      checkout_branch="review/$branch_name/$2"
    fi
    echo "-> $checkout_branch"
    git reset --keep "$checkout_branch"
    ;;

  *)
    echo "Unknown command $command"
    exit 1
    ;;
esac
