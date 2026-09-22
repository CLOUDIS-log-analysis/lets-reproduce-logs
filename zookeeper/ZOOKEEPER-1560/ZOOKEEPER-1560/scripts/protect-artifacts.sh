#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
    echo "usage: $0 logs/attempt-NNN-or-unique-name | result/attempt-NNN.properties | result/attempt-NNN-or-unique-name" >&2
    exit 64
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
issue_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)

if [ -L "$1" ]; then
    echo "refusing to protect a symbolic link: $1" >&2
    exit 65
fi

if [ -d "$1" ]; then
    artifact_path=$(CDPATH= cd -- "$1" && pwd -P)
    artifact_kind=directory
elif [ -f "$1" ]; then
    artifact_parent=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd -P)
    artifact_path=$artifact_parent/$(basename -- "$1")
    artifact_kind=file
else
    echo "artifact file or directory does not exist: $1" >&2
    exit 66
fi

case "$artifact_path" in
    "$issue_dir"/logs/*|"$issue_dir"/result/*) ;;
    *)
        echo "refusing to protect a path outside logs/ or result/: $artifact_path" >&2
        exit 65
        ;;
esac

# Regular files become read-only and directories stay readable/traversable,
# including for Harness processes outside the container. Reject symlinks so a
# directory walk can never change permissions outside the selected tree.
if [ "$artifact_kind" = file ]; then
    chmod 0444 "$artifact_path"
else
    if find -P "$artifact_path" -type l -print -quit | grep -q .; then
        echo "refusing to protect an artifact tree containing symbolic links: $artifact_path" >&2
        exit 65
    fi

    find -P "$artifact_path" -type f -exec chmod 0444 {} +
    find -P "$artifact_path" -depth -type d -exec chmod 0555 {} +
fi
