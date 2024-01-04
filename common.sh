# First get the config stuff set up.

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
. "$SCRIPT_DIR/config.sh"

show_help() {
    if [[ $mount_command == 1 ]] ; then 
        echo "Usage: $0 [OPTIONS] [COMMIT]"
    else
        echo "Usage: $0 [OPTIONS]"
    fi
    echo
    echo "Options:"
    echo "  --repo                  Set the git repository to use for backup." 
    echo "                          If omitted, the value from config.sh is used."
    echo "  --local-data-store      Set the local data store path to a given directory."
    echo "                          If omitted, the value from config.sh is used."
    
    if [[ $mount_command == 1 ]] ; then 
        echo "  --list                  List the available snapshots commits to mount."
        echo "  --unmount               Unmount the snapshot."
    else
        echo "  --snapshot-dir          Set the directory to snapshot. Default is '$snapshot_dir'"
        echo "  --backup-subdir         Set the directory within the git repo for snapshots. Default is '$backup_subdir'"
        echo "  --include-private-files Include files without group read permissions"
    fi
    
    echo "  -h, --help              Show this help message and exit"
    echo
}

list_snapshots=
unmount_snapshots=
other_command=

# Parsing arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --repo) git_repo="$2"; shift ;;
        --repo=*) git_repo="${1#*=}" ;;
        
        --local-data-store) local_data_store="$2"; shift ;;
        --local-data-store=*) local_data_store="${1#*=}" ;;
        
        --snapshot-dir) snapshot_dir="$2"; shift ;;
        --snapshot-dir=*) snapshot_dir="${1#*=}" ;;
        
        --backup-subdir) backup_subdir="$2"; shift ;;
        --backup-subdir=*) backup_subdir="${1#*=}" ;;
        
        --repo-branch) repo_branch="$2"; shift ;;
        --repo-branch=*) repo_branch="${1#*=}" ;;
        
        --include-private-files) include_private_files=true ;;

        --list) list_snapshots=1 ;; 
        
        --unmount) unmount_snapshots=1 ;; 
        --umount) unmount_snapshots=1 ;; 
        
        --commit) mount_commit="$2"; shift ;;
        --commit=*) mount_commit="${1#*=}" ;;
        
        -h|--help) show_help; exit 0 ;;
        
        -*) echo "Unrecognized flag '$1'"; show_help; exit 1 ;;
        
        *) other_command="$1" ;;
    esac
    shift
done


# Set up the environment variables if needed. 
if [[ ! -z $local_data_store ]] ; then 

   if [[ ! -d $local_data_store ]] ; then
      mkdir -p $local_data_store || echo "Error creating directory $local_data_store";
   fi
   
   # If it still doesn't exist...
   if [[ ! -d $local_data_store ]] ; then
     >&2 echo "Local data store $local_data_store does not exist or is not a directory."
     exit 1
   fi

   export XET_CAS_SERVER="local://$local_data_store"
fi

if [[ -z "$git_repo" ]] ; then 
    >&2 echo "Remote git repo not set.  Please set git_repo in config.sh to your remote repo, or pass in --repo on the command line."
    exit 1
fi


# Make sure we have the normalized absolute path and it's accessable.
snapshot_dir="$(cd "$snapshot_dir" && pwd)"

# Put in the .noindex extension so this folder doesn't get indexed in spotlight
working_subdir_name=".git_snapshot.noindex"
working_dir="$snapshot_dir/$working_subdir_name"
mkdir -p $working_dir

local_repo_dir="${working_dir}/backup_repo.git"

# Common function to set up the local repo
setup_local_git_repo() {
    # Clone the repo if we haven't already.  Otherwise, fetch and ensure we're on the correct branch. 
    if [[ ! -e "$local_repo_dir" ]] ; then 
        >&2 echo "Cloning remote repository into $local_repo_dir"
        git xet install
        git clone --bare "$git_repo" "$local_repo_dir"
        cd "$local_repo_dir"
        git config --local core.autocrlf false # Tell git that we don't want to change clrf endings
    fi

    cd $local_repo_dir

    >&2 echo "Ensuring repository is up to date."

    # Now, fetch all these things.
    git xet install --local # Ensure the filter is installed in the local repo.
    git fetch origin -u
}









