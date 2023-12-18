# First get the config stuff set up.

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
. "$SCRIPT_DIR/config.sh"

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --repo                  Set the git repository to use for backup." 
    echo "                          If omitted, the value from config.sh is used."
    echo "  --local-data-store      Set the local data store path to a given directory."
    echo "                          If omitted, the value from config.sh is used."
    echo "  --snapshot-dir          Set the directory to snapshot. Default is '$snapshot_dir'"
    echo "  --backup-subdir         Set the directory within the git repo for snapshots. Default is '$backup_subdir'"
    echo "  --include-private-files Include files without group read permissions"
    echo "  -h, --help              Show this help message and exit"
    echo
}

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
        
        -h|--help) show_help; exit 0 ;;
        
        *) echo "Unknown parameter: $1"; show_help; exit 1 ;;
    esac
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

working_subdir_name=".git_snapshot"
working_dir="$snapshot_dir/$working_subdir_name"
mkdir -p $working_dir









