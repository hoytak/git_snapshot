#!/bin/bash -e 

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

mount_command=1
. "$SCRIPT_DIR/common.sh"

if [[ ! -z $list_snapshots ]] ; then
    setup_local_git_repo

    echo "Available snapshots:" 
    echo "===================="
    cd $local_repo_dir
    git log --pretty=format:"%h - %s" | grep "Snapshot"
    exit 0
fi

if [[ ! -z $unmount_snapshots ]] ; then 
    for f in "$working_dir/snapshot_mount_*" ; do 
        sudo umount -f -q $f
    done

    exit 0
fi

mount_commit="$other_command"

if [[ -z $mount_commit ]] ; then 
    >&2 echo "Must specify commit to mount.  Run $0 --list to see available commits."
    exit 1
fi

mount_dir="$working_dir/snapshot_mount_$mount_commit"

>&2 echo "Mounting commit $mount_commit at $mount_dir"
mkdir -p $mount_dir

git xet mount -r $mount_commit "$git_repo" "$mount_dir" 

>&2 echo "Successful.  Browse snaphot at"
>&2 echo "$mount_dir"

