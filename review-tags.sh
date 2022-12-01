#!/bin/bash

set -eo pipefail

if [[ $# -lt 2 ]]; then
	echo "usage: review-tags.sh <branch_name> <create|list>"
	exit
fi

branch_name="$1"
if ! git rev-parse "origin/$branch_name" > /dev/null 2>&1; then
	echo "origin/$branch_name does not exist"
	exit
fi

command="$2"
case $command in
	c|create)
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
		git tag -l | grep "review/$branch_name"
		;;

	d|diff)
		git range-diff origin/develop "review/$branch_name/$3" "review/$branch_name/$4"
		;;

	co|checkout)
		git checkout "review/$branch_name/$3"
		;;

	*)
		echo "Unknown command $command"
		exit 1
		;;
esac
