# The directory to snapshot.
snapshot_dir="$HOME"

# The git repository where we store all metadata and pointer files, and the data store where
# all the deduplicated data is stored. 
#
# If blank, these must be specified on the command line 
#
# Examples:
# 
#  Local store, with repo and data entirely on a NAS drive mounted at /nas/:
#    git_repo=/nas/repo/home_directory.git
#    local_data_store=//nas/data/
#  
#  Repo in github, data stored in xethub:
#    git_repo=git@github.com/hoytak/home_directory_backup.git
#    local_data_store=    # Leave this one blank to store on xethub.com endpoint. 
#
#  Repo in github, data stored on NAS: 
#    git_repo=git@github.com/hoytak/home_directory_backup.git
#    local_data_store=//nas/data/
#
git_repo=
local_data_store=

# The subdirectory within the repo where we're storing the snapshots.
# For home of /home/hoytak/, this means that the snapshot will be in <repo>/backups/hoytak/ 
repo_subdir=backups

