#!/bin/bash -e

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

>&2 echo "Beginning snapshot: "
>&2 echo "   Snapshot Directory: $snapshot_dir" 
>&2 echo "   Remote git repo: $git_repo" 

if [[ ! -z $XET_CAS_SERVER ]] ; then
    >&2 echo "   Data store: $XET_CAS_SERVER"
else
    >&2 echo "   Data store: XetHub."

fi

>&2 echo "   Local working directory $working_dir"

mirror_working_dir="${working_dir}/mirror"
snapshot_mirror_dir="$mirror_working_dir/$repo_subdir"
snapshot_sync_dir="$snapshot_mirror_dir/$(basename $snapshot_dir)"
local_repo_dir="${working_dir}/backup_repo.git"


mkdir -p "${working_dir}"
mkdir -p "${mirror_working_dir}"


# Clone the repo if we haven't already.  Otherwise, fetch and ensure we're on the correct branch. 
if [[ ! -e "$local_repo_dir" ]] ; then 
    >&2 echo "Cloning remote repository into $local_repo_dir"
    git xet install
    git clone --bare "$git_repo" "$local_repo_dir"
    git config --local core.autocrlf false # Tell git that we don't want to change clrf endings
fi

cd $local_repo_dir

>&2 echo "Ensuring repository is up to date."

# Now, fetch all these things.
git xet install --local # Ensure the filter is installed in the local repo.
git fetch origin
current_branch=$(git rev-parse --abbrev-ref HEAD)
git show HEAD:.gitattributes > "$mirror_working_dir/.gitattributes"

# Important -- these tell git we're in different places
export GIT_WORK_TREE="$mirror_working_dir"
export GIT_DIR="$local_repo_dir"

# Make sure we have all the right config files present.
cd "$GIT_WORK_TREE"

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
    >&2 echo -n "Finding and excluding files without group read permissions... "
    find "$snapshot_dir" -mount -not \( -path "$working_dir" -prune \) '!' -perm -g=r >> "$exclude_list"
    >&2 echo "Done." 
fi

# Exclude all the folders that are on a different filesystem. 
>&2 echo -n "Finding and excluding directories on other mounts... " 
df -P | awk '{print $6}' | tail -n +2 | grep "$snapshot_dir/" >> "$exclude_list" && echo " Done." || echo " None found." 

# Exclude all the files in the manual exclude list
if [[ -e "$SCRIPT_DIR/exclude_list.txt" ]] ; then 
  cat "$SCRIPT_DIR/exclude_list.txt" | sed "s|^|$snapshot_dir/|" | sed 's|/+|/|g' >> "$exclude_list"
fi

# A snapshot timestamp to put in the commit message.  Do it now as there will be a lot of 
# uploading and stuff that could take a while.
snapshot_time=$(date)

>&2 echo "Setting the snapshot time at $snapshot_time."

# Delete the snapshot mirror dir and recreate it so we get a correct representation
mkdir -p "$snapshot_mirror_dir"/

# Now, annoyingly, all the links in the exclude_list are absolute, but rsync exclude-from 
# only works with relative.
exclude_list_rel="${exclude_list}.relative"
cat "$exclude_list" | sed "s|^$snapshot_dir/||" > "$exclude_list_rel"


# Create a mirrored copy; this should only use hardlinks and take up very minimal space. 
>&2 echo "Creating snapshot in $snapshot_mirror_dir/ using hardlinks."
rsync -a --delete --link-dest="$snapshot_dir/" --exclude-from="$exclude_list_rel" --exclude "*$working_subdir_name/*" "$snapshot_dir"/ "$snapshot_sync_dir/"

# Rename all the .git folders in the snapshot mirror so they get backed up too without submodule weirdness.
# (This is the main reason to have a mirror of hardlinks)

>&2 echo "Renaming .git folders to _git in mirror for git compatibility"
for f in `find "$snapshot_sync_dir" -wholename '*/.git'` ; do
	new_f="$(dirname $f)/_git" 
    >&2 echo "  Old: $f"
    >&2 echo "  New: $new_f"

	mv "$f" "$new_f"
done

>&2 echo "Adding the snapshot to git."
git add $snapshot_mirror_dir
git commit --quiet -a -m "Snapshot $snapshot_time"

>&2 echo "Syncing snapshot to remote."
git push --force origin $current_branch

