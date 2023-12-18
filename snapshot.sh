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

mirror_working_dir="${working_dir}/mirror"
snapshot_mirror_dir="$mirror_working_dir/$repo_subdir"
snapshot_sync_dir="$snapshot_mirror_dir/$(basename $snapshot_dir)"
local_repo_dir="${working_dir}/backup_repo.git"

mkdir -p "${working_dir}"
mkdir -p "${mirror_working_dir}"

# Important -- these tell git we're in different places
export GIT_WORK_TREE="$mirror_working_dir"
export GIT_DIR="$local_repo_dir"

# Now, fetch all these things.
git fetch origin
current_branch=$(git rev-parse --abbrev-ref HEAD)
if $(git branch --all | grep -q origin/$current_branch) ; then 
    # ensure that the tip matches with the remote
    git reset --soft origin/$current_branch
fi

# Make sure we have all the right config files present.
echo "Syncing with remotes." 
cd "$GIT_WORK_TREE"
git checkout HEAD -- .gitattributes
echo "$gitignore_contents" > .gitignore

if [[ ! -e "$GIT_WORK_TREE/.gitattributes" ]] ; then
   echo ".gitattributes not present in repo mirror directory; is it initialized for Xet use?"
   exit 1
fi

if [[ -z  $(grep xet "$GIT_WORK_TREE/.gitattributes") ]] ; then
   echo ".gitattributes does not contain xet filter; repo mirror must be xet enabled."
   exit 1
fi

if [[ -z $(git xet --version) ]] ; then 
    echo "git-xet binary not in path."
    exit 1
fi

exclude_list="${working_dir}/exclude_paths.txt"

# Always exclude the working directory. 
echo "$working_dir" > "$exclude_list"

# Unless requested, exclude all files that do not have group read permissions.
if [[ -z $include_private_files ]] ; then
    echo "Finding and excluding files without group read permissions."
    find "$snapshot_dir" -mount -not \( -path "$working_dir" -prune \) '!' -perm -g=r >> "$exclude_list"
fi

# Exclude all the folders that are on a different filesystem. 
echo "Finding and excluding directories on other mounts." 
df -P | awk '{print $6}' | tail -n +2 | grep "$snapshot_dir" >> "$exclude_list" || echo ">>> None found."

# Exclude all the files in the manual exclude list
if [[ -e "$SCRIPT_DIR/exclude_list.txt" ]] ; then 
  cat "$SCRIPT_DIR/exclude_list.txt" | sed "s|^|$snapshot_dir/|" >> "$exclude_list"
fi

# Clone the repo if we haven't already.  Otherwise, fetch and ensure we're on the correct branch. 
if [[ ! -e "$local_repo_dir" ]] ; then 
    echo "Cloning remote repository."
    git xet install
    git clone --bare "$git_repo" "$local_repo_dir"
    git config --local core.autocrlf false # Tell git that we don't want to change clrf endings
    git xet install --local # Ensure the filter is installed in the local directory.
fi

# A snapshot timestamp to put in the commit message.  Do it now as there will be a lot of 
# uploading and stuff that could take a while.
snapshot_time=$(date)

echo "Setting the snapshot time at $snapshot_time."

# Delete the snapshot mirror dir and recreate it so we get a correct representation
mkdir -p "$snapshot_mirror_dir"/

# Create a mirrored copy; this should only use hardlinks and take up very minimal space. 
echo "Creating snapshot in $snapshot_mirror_dir/ using hardlinks."
rsync -a --delete --link-dest="$snapshot_dir/" --exclude-from="$exclude_list" --exclude "*$working_subdir_name/*" "$snapshot_dir"/ "$snapshot_sync_dir/"

# Rename all the .git folders in the snapshot mirror so they get backed up too without submodule weirdness.
# (This is the main reason to have a mirror of hardlinks)
echo "Renaming for git compatibility"
for f in `find "$snapshot_sync_dir" -wholename '*/.git'` ; do
	new_f="$(dirname $f)/_git" 
    echo "  Old: $f"
    echo "  New: $new_f"

	mv "$f" "$new_f"
done

echo "Adding the snapshot to git."
git add $snapshot_mirror_dir
git commit -a -m "Snapshot $snapshot_time"

echo ""
git push origin main




