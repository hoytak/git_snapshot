#!/bin/bash -ex

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
. "$SCRIPT_DIR/setup.sh"

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


mirror_working_dir="${working_dir}/mirror"
snapshot_mirror_dir="$mirror_working_dir/$repo_subdir"
repo_dir="${working_dir}/backup_repo.git"

# Important -- these tell git we're in different places
export GIT_WORK_TREE="$mirror_working_dir"
export GIT_DIR="$repo_dir"

# Set up the git ignore file.
gitignore_contents="$(cat "$SCRIPT_DIR/gitignore")"

# Clone the repo if we haven't already
if [[ ! -e "$repo_dir" ]] ; then 
    git xet install
    git clone --bare "$git_repo" "$repo_dir"
    git config --local core.autocrlf false # Tell git that we don't want to change clrf endings
fi 

# A snapshot timestamp to put in the commit message.  Do it now as there will be a lot of 
# uploading and stuff that could take a while.
snapshot_time=$(date)

# Delete the snapshot mirror dir and recreate it so we get a correct representation
rm -rf "$snapshot_mirror_dir"/
mkdir -p "$snapshot_mirror_dir"/

# Create a mirrored copy (fast, this only makes hardlinks due to the -l)
cp -alPr "$snapshot_dir" "$snapshot_mirror_dir"

# Rename all the .git folders in the snapshot mirror so they get backed up too without submodule weirdness.
# (This is the main reason to have a mirror of hardlinks)
for f in `find . -wholename '*/.git'` ; do
	new_f="${f/.git/_git}"
	mv "$f" "$new_f"
done


# Make sure we have all the right config files present.
cd "$GIT_WORK_TREE"
git checkout HEAD -- .gitattributes
echo "$gitignore_contents" > .gitignore

if [[ ! -e "$GIT_WORK_TREE/.gitattributes" ]] ; then
   echo ".gitattributes not present in repo mirror directory; is it initialized for xet use?"
   exit 1
fi

git add $snapshot_mirror_dir
git commit -a -m "Snapshot $snapshot_time"
git push origin main




