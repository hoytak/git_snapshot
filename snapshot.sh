#!/bin/bash -ex

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
. "$SCRIPT_DIR/common.sh"

if [[ -z "$working_dir" ]] ; then 
    echo "working_dir not set."
    exit 1
fi

if [[ -z "$git_repo" ]] ; then 
    echo "git_repo not set."
    exit 1
fi

if [[ -z "$snapshot_dir" ]] ; then
    echo "snapshot_dir not set."
    exit 1
fi

if [[ -z "$repo_subdir" ]] ; then
    echo "repo_subdir not set."
    exit 1
fi

# Make sure we have the normalized absolute path and it's accessable.
pushd $snapshot_dir
snapshot_dir=${PWD}
popd

mirror_working_dir="${working_dir}/mirror/"
snapshot_mirror_dir="$mirror_working_dir/$repo_subdir"
snapshot_sync_dir="$snapshot_mirror_dir/$(basename $snapshot_dir)"
local_repo_dir="${working_dir}/backup_repo.git"

# Important -- these tell git we're in different places
export GIT_WORK_TREE="$mirror_working_dir"
export GIT_DIR="$local_repo_dir"

exclude_list="${working_dir}/mirror/exclude_paths.txt"
exclude_list_rel="${working_dir}/mirror/exclude_paths_rel.txt"

# Always exclude the working directory. 
echo "$working_dir" > "$exclude_list"

# Unless requested, exclude all files that do not have group read permissions.
if [[ -z $include_private_files ]] ; then
    find $snapshot_dir -mount -perm \! /077 >> "$exclude_list"
fi

# Exclude all the folders that are on a different filesystem. 
df -P | awk '{print $6}' | tail -n +2 | grep "$snapshot_dir" >> "$exclude_list"

# Exclude all the files in the manual exclude list
if [[ -e "$SCRIPT_DIR/exclude_list.txt" ]] ; then 
  cat "$SCRIPT_DIR/exclude_list.txt" >> "$exclude_list"
fi

# And, to make sure that we have the correct relative links and stuff, 
# Process all these to make sure they are all links relative to the 
cat "$exclude_list" | sed "s|^${snapshot_dir}||" | sed 's|^\./||' > "$exclude_list_rel"

# Clone the repo if we haven't already.  Otherwise, fetch and ensure we're on the correct branch. 
if [[ ! -e "$local_repo_dir" ]] ; then 
    git xet install
    git clone --bare "$git_repo" "$local_repo_dir"
    git config --local core.autocrlf false # Tell git that we don't want to change clrf endings
fi

# Now, fetch all these things.
git fetch origin
current_branch=$(git rev-parse --abbrev-ref HEAD)
if $(git branch --all | grep -q origin/$current_branch) ; then 
    # ensure that the tip matches with the remote
    git reset --soft origin/$current_branch
fi

# Make sure we have all the right config files present.
cd "$GIT_WORK_TREE"
git checkout HEAD -- .gitattributes
echo "$gitignore_contents" > .gitignore

if [[ ! -e "$GIT_WORK_TREE/.gitattributes" ]] ; then
   echo ".gitattributes not present in repo mirror directory; is it initialized for Xet use?"
   exit 1
fi

# A snapshot timestamp to put in the commit message.  Do it now as there will be a lot of 
# uploading and stuff that could take a while.
snapshot_time=$(date)

# Delete the snapshot mirror dir and recreate it so we get a correct representation
rm -rf "$snapshot_mirror_dir"/
mkdir -p "$snapshot_mirror_dir"/

# Create a mirrored copy; this should only use hardlinks and take up very minimal space. 
rsync -a --link-dest=$snapshot_dir --exclude-from="$exclude_list_rel" "$snapshot_dir/" "$snapshot_sync_dir/"

# Rename all the .git folders in the snapshot mirror so they get backed up too without submodule weirdness.
# (This is the main reason to have a mirror of hardlinks)
for f in `find "$snapshot_sync_dir" -wholename '*/.git'` ; do
	new_f="${f/.git/_git}"
	mv "$f" "$new_f"
done

git add $snapshot_mirror_dir
git commit -a -m "Snapshot $snapshot_time"
git push origin main




