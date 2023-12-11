# The directory to snapshot.
snapshot_dir=/home/hoytak/

# The working directory we use to prepare the snapshot.  This cannot be inside the snapshot_dir folder.
working_dir=/home/hoytak_backup/

# The git repository where we store all the filenames and pointer files. 
git_repo=git@github.com:hoytak/raven-backup.git

# The subdirectory within the repo where we're storing the snapshots.
# Note that this shouldn't be emty 
repo_subdir=backups/

# LOCAL SETUP

# By default, the data is stored in the xethub data CAS.  To use
# a local directory instead, e.g. on a nas, first mount the remote drive
# at the location here and export this environment variable.
export XET_CAS_SERVER=local:///home/hoytak_backup/nas/cas/

# If the data shards are stored locally, then this allows the repo to be 
# stored there as well.  
git_repo=/home/hoytak_backup/nas/raven-backup.git/


