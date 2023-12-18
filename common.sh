# First get the config stuff set up.

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
. "$SCRIPT_DIR/config.sh"

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --repo             Set the git repository to use for backup." 
    echo "                     If omitted, the value from config.sh is used."
    echo "  --local-data-store Set the local data store path to a given directory."
    echo "                     If omitted, the value from config.sh is used."
    echo "  --snapshot-dir     Set the directory to snapshot. Default is '$snapshot_dir'"
    echo "  --backup-subdir    Set the directory within the git repo for snapshots. Default is '$backup_subdir'"
    echo "  -h, --help         Show this help message and exit"
    echo
}

# Parsing arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --repo) git_repo="$2"; shift ;;                 
        --local-data-store) local_data_store="$2"; shift ;;   
        --snapshot-dir) snapshot_dir="$2"; shift ;;
        --backup-subdir) backup_subdir="$2"; shift ;;
        -h|--help) show_help; exit 0 ;;                 
        *) echo "Unknown parameter: $1"; show_help; exit 1 ;;
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

# Make sure we have the normalized absolute path and it's accessable.
snapshot_dir="$(cd "$snapshot_dir" && pwd)"

working_subdir_name=".git_snapshot"
working_dir="$snapshot_dir/$working_subdir_name"
mkdir -p $working_dir









